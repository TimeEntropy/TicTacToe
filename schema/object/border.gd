class_name BoardPanel
extends GridContainer

@export_group('data')
@export var layout  := Vector2i.ZERO : set = set_layout
@export var players : Array[PlayerProfile] = []
@export var win_count := 3

var cells := {}
var score := {}
var current_player  := 0 : set = _set_current_player
var last_player := -1
var rest_cell_count := 0
var turn_count := 0
var history := UndoRedo.new()
var finished := false

signal chess_dropped(coords:Vector2i)
signal player_changed(current:int)
signal duel_win(player_id:int)
signal duel_draw()

#region overrides

#endregion

#region events

func _on_cell_dropped_chess(cell:BoardCell) -> void:
	drop_by_player(cell)
	if !finished:
		await drop_by_ai()
	pass

#endregion

#region tools

func clear() -> void:
	cells.clear()
	score.clear()
	for child in get_children():
		child.queue_free()
	pass

func set_layout(value:Vector2i) -> void:
	clear()
	layout = value
	self.size = Vector2.ZERO
	self.columns = value.x
	for y in value.y:
		for x in value.x:
			var cell := preload("res://scene/prefab/cell.tscn").instantiate() as BoardCell
			cell.dropped_chess.connect(_on_cell_dropped_chess)
			cell.coords = Vector2i(x, y)
			add_child(cell)
			cells[cell.coords] = cell
	rest_cell_count = value.x * value.y
	pass

func check_chess_inline(player_id:int, length:=3) -> Array[Vector2i]:
	var CHECK_AXIS_INLINE := func(coords:Vector2i, dir:Vector2i) -> Array[Vector2i]:
		var output_coords : Array[Vector2i] = []
		for i in length:
			var tcrds := coords + i * dir
			var tid   := score.get(tcrds, -1) as int
			output_coords.append(tcrds)
			if tid != player_id:
				return []
		return output_coords

	var CHECK_INLINE := func(coords:Vector2i) -> Array[Vector2i]:
		var x_axis := CHECK_AXIS_INLINE.call(coords, Vector2i( 1, 0)) as Array[Vector2i]
		var y_axis := CHECK_AXIS_INLINE.call(coords, Vector2i( 0, 1)) as Array[Vector2i]
		var skew_1 := CHECK_AXIS_INLINE.call(coords, Vector2i( 1, 1)) as Array[Vector2i]
		var skew_2 := CHECK_AXIS_INLINE.call(coords, Vector2i(-1, 1)) as Array[Vector2i]
		var result : Array[Vector2i] = []
		result.append_array(x_axis)
		result.append_array(y_axis)
		result.append_array(skew_1)
		result.append_array(skew_2)
		return result

	for y in layout.y:
		for x in layout.x:
			var result := CHECK_INLINE.call(Vector2i(x, y)) as Array[Vector2i]
			if !result.is_empty():
				return result
	return []

func let_win(player_id:int) -> void:
	set_cell_droppable(false)
	duel_win.emit(player_id)
	pass

func is_win(player_id:int) -> bool:
	var result := check_chess_inline(player_id, win_count)
	if !result.is_empty():
		# change to 'win_handle' state
		set_cell_droppable(false)
		for crd:Vector2i in result:
			var c := cells[crd] as BoardCell
			c.change_content_color(Color.GREEN)
		return true
	return false

func is_draw() -> bool:
	return rest_cell_count <= 0

func set_cell_droppable(enable:bool) -> void:
	for c:BoardCell in cells.values():
		c.handle_drop = enable
	pass

func drop_by_player(cell:BoardCell) -> void:
	history.create_action(String.num(turn_count))
	history.add_do_method(drop.bind(cell))
	history.add_undo_property(self, 'current_player', current_player)
	history.add_undo_property(self, 'last_player', last_player)
	history.add_do_property(self, 'last_player', current_player)
	history.add_do_property(self, 'current_player', wrapi(current_player + 1, 0, players.size()))
	history.add_undo_method(pick.bind(cell))
	history.commit_action()
	pass

func drop_by_ai() -> void:
	set_cell_droppable(false)
	for c:BoardCell in cells.values():
		c.change_content_color(Color.TRANSPARENT)
	await get_tree().create_timer(1.0).timeout
	set_cell_droppable(true)
	var rest_cells := cells.values().filter(func(c:BoardCell) -> bool: return c.get_child_count() < 1)
	drop_by_player(rest_cells.pick_random())

func drop(cell:BoardCell) -> void:
	if cell.get_child_count() < 1:
		var chess := preload("res://scene/prefab/chess.tscn").instantiate()
		chess.position = cell.pivot_offset
		chess.texture  = players[current_player].used_chess_image
		cell.add_child(chess)
		score[cell.coords] = current_player
		rest_cell_count -= 1
		chess_dropped.emit(cell.coords)

		if is_win(current_player):
			let_win(current_player)
			finished = true
			return
		elif is_draw():
			set_cell_droppable(false)
			finished = true
			duel_draw.emit()
		turn_count += 1
	pass

func pick(cell:BoardCell) -> void:
	if cell.get_child_count() > 0:
		for child in cell.get_children():
			child.queue_free()
	set_cell_droppable(true)
	for c:BoardCell in cells.values():
		c.change_content_color(Color.TRANSPARENT)
	score[cell.coords] = -1
	rest_cell_count += 1
	turn_count -= 1
	finished = false
	pass

#endregion

#region setget

func _set_current_player(value:int) -> void:
	current_player = value
	player_changed.emit(current_player)

#endregion
