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

var ai_minds := {}

signal chess_dropped(coords:Vector2i)
signal player_changed(current:int)
signal duel_win(player_id:int)
signal duel_giveup(player_id:int)
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

func check_chess_inline(player_id:int, length:=3) -> Dictionary:
	var CHECK_AXIS_INLINE := func(coords:Vector2i, dir:Vector2i) -> Array[Vector2i]:
		var output_coords : Array[Vector2i] = []
		for i in length:
			var tcrds := coords + i * dir
			var tid   := score.get(tcrds, -1) as int
			output_coords.append(tcrds)
			if tid != player_id:
				return []
		return output_coords

	var CHECK_INLINE := func(coords:Vector2i) -> Dictionary:
		var x_axis := CHECK_AXIS_INLINE.call(coords, Vector2i( 1, 0)) as Array[Vector2i]
		var y_axis := CHECK_AXIS_INLINE.call(coords, Vector2i( 0, 1)) as Array[Vector2i]
		var skew_1 := CHECK_AXIS_INLINE.call(coords, Vector2i( 1, 1)) as Array[Vector2i]
		var skew_2 := CHECK_AXIS_INLINE.call(coords, Vector2i(-1, 1)) as Array[Vector2i]
		var result := {}
		if !x_axis.is_empty(): result['1'] = x_axis
		if !y_axis.is_empty(): result['2'] = y_axis
		if !skew_1.is_empty(): result['3'] = skew_1
		if !skew_2.is_empty(): result['4'] = skew_2
		return result

	for y in layout.y:
		for x in layout.x:
			var result := CHECK_INLINE.call(Vector2i(x, y)) as Dictionary
			if !result.is_empty():
				return result
	return {}

func let_win(player_id:int) -> void:
	set_cell_droppable(false)
	duel_win.emit(player_id)
	pass

func let_giveup(player_id:int) -> void:
	set_cell_droppable(false)
	duel_giveup.emit(player_id)
	pass

func is_win(player_id:int) -> bool:
	var result := check_chess_inline(player_id, win_count)
	if !result.is_empty():
		# change to 'win_handle' state
		set_cell_droppable(false)
		for case in result:
			for crd:Vector2i in result[case]:
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
	await get_tree().create_timer(randf_range(0.2, 2.0)).timeout
	set_cell_droppable(true)
	var rest_cells := ai_think()
	if !rest_cells.is_empty():
		drop_by_player(rest_cells[0])
	else:
		let_giveup(0)

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

func ai_think() -> Array[BoardCell]:
	var FIND_CONNECT_CELLS := func(connected_coords:Dictionary) -> Array[BoardCell]:
		var ret : Array[BoardCell] = []
		if !connected_coords.is_empty():
			var region := Rect2i(Vector2i.ZERO, layout)
			var check_coords := []
			for case in connected_coords:
				match case:
					'1': check_coords = [connected_coords['1'][0] + Vector2i(-1, 0), connected_coords['1'][-1] + Vector2i( 1, 0)]
					'2': check_coords = [connected_coords['2'][0] + Vector2i( 0,-1), connected_coords['2'][-1] + Vector2i( 0, 1)]
					'3': check_coords = [connected_coords['3'][0] + Vector2i(-1,-1), connected_coords['3'][-1] + Vector2i( 1, 1)]
					'4': check_coords = [connected_coords['4'][0] + Vector2i( 1,-1), connected_coords['4'][-1] + Vector2i(-1, 1)]
				for crd:Vector2i in check_coords:
					if region.has_point(crd):
						var c := cells[crd] as BoardCell
						if c.get_child_count() < 1:
							ret.append(c)
		return ret

	var result:Array[BoardCell] = []
	result.append_array(FIND_CONNECT_CELLS.call(check_chess_inline(0, 2)))
	result.append_array(FIND_CONNECT_CELLS.call(check_chess_inline(1, 2)))
	if result.is_empty():
		result.append_array(cells.values().filter(func(c:BoardCell) -> bool: return c.get_child_count() < 1))
	return result

#endregion

#region setget

func _set_current_player(value:int) -> void:
	current_player = value
	player_changed.emit(current_player)

#endregion
