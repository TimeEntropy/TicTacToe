extends GridContainer

var ENUMS := preload("res://schema/core/enum.gd").new()

@export_group('node')

@export_group('data')
@export var layout  := Vector2i.ZERO : set = set_layout
@export var players : Array[PlayerProfile] = []
@export var win_count := 3

var cells := {}
var score := {}
var current_player  := 0
var rest_cell_count := 0

#region overrides

#endregion

#region events

func _on_cell_dropped_chess(cell:BoardCell) -> void:
	if cell.get_child_count() < 1:
		var chess := preload("res://scene/prefab/chess.tscn").instantiate()
		chess.position = cell.pivot_offset
		chess.texture  = players[current_player].used_chess_image
		cell.add_child(chess)
		score[cell.coords] = current_player
		rest_cell_count -= 1

		if is_win(current_player):
			print('player {0} win!!!'.format([players[current_player].nickname]))
			return
		elif is_draw():
			print('draw! no player win!')

		current_player = wrapi(current_player + 1, 0, players.size())
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

func hide_border() -> void:
	for i in get_child_count():
		var cell  = get_child(i)
		@warning_ignore("integer_division")
		var coord = Vector2i(i % layout.x, i / layout.x)

		if coord.x == (layout.x - 1):
			cell.change_border_width(ENUMS.CELL_BORDER_FLAGS.RIGHT, 0)
		elif coord.x == 0:
			cell.change_border_width(ENUMS.CELL_BORDER_FLAGS.LEFT , 0)

		if coord.y == (layout.y - 1):
			cell.change_border_width(ENUMS.CELL_BORDER_FLAGS.DOWN , 0)
		elif coord.y == 0:
			cell.change_border_width(ENUMS.CELL_BORDER_FLAGS.UP   , 0)
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

func is_win(player_id:int) -> bool:
	var result := check_chess_inline(player_id, win_count)
	if !result.is_empty():
		# change to 'win_handle' state
		for c:BoardCell in cells.values():
			c.handle_input = false
		for crd:Vector2i in result:
			var c := cells[crd] as BoardCell
			c.change_content_color(Color.BLUE)
		return true
	return false

func is_draw() -> bool:
	return rest_cell_count <= 0

#endregion
