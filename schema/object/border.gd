extends GridContainer

var ENUMS := preload("res://schema/core/enum.gd").new()

@export_group('node')

@export_group('data')
@export var layout  := Vector2i.ZERO : set = set_layout
@export var players : Array[PlayerProfile] = []

var cells   := {}
var score   := {}
var current_player  := 0
var rest_cell_count := 0

#region overrides

func _ready() -> void:
	pass

#endregion

#region events

func _on_cell_dropped_chess(cell:BoardCell) -> void:
	drop_chess(cell)
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
			var cell := preload("res://scene/prefab/cell.tscn").instantiate()
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

func drop_chess(cell:BoardCell) -> void:
	if cell.get_child_count() < 1:
		var chess := preload("res://scene/prefab/chess.tscn").instantiate()
		chess.position = cell.pivot_offset
		chess.texture  = players[current_player].used_chess_image
		cell.add_child(chess)
		score[cell.coords] = current_player
		rest_cell_count -= 1

		if check_chess_inline(current_player):
			print('player {0} win!!!'.format([players[current_player].nickname]))
		elif is_draw():
			print('draw! no player win!')

		current_player = wrapi(current_player + 1, 0, players.size())
	pass

func check_chess_inline(player_id:int, length:=3) -> bool:
	var CHECK_AXIS_INLINE := func(coords:Vector2i, dir:Vector2i) -> bool:
		for i in length:
			var tcrds := coords + i * dir
			var tid   := score.get(tcrds, -1) as int
			if tid != player_id:
				return false
		return true

	var CHECK_INLINE := func(coords:Vector2i) -> bool:
		var x_axis := CHECK_AXIS_INLINE.call(coords, Vector2i(1, 0)) as bool
		var y_axis := CHECK_AXIS_INLINE.call(coords, Vector2i(0, 1)) as bool
		var toeing := CHECK_AXIS_INLINE.call(coords, Vector2i(1, 1)) as bool
		return x_axis or y_axis or toeing

	for y in layout.y:
		for x in layout.x:
			var result := CHECK_INLINE.call(Vector2i(x, y)) as bool
			if result:
				return true
	return false

func is_win(player_id:int) -> bool:
	return check_chess_inline(player_id)

func is_draw() -> bool:
	return rest_cell_count <= 0

#endregion
