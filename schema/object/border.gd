extends GridContainer

var ENUMS := preload("res://schema/core/enum.gd").new()

@export_group('node')
@export var image_storage : Node

@export_group('data')
@export var layout := Vector2i.ZERO : set = set_layout

var cells  := {}
var score  := {}
var player := 0

#region overrides

func _ready() -> void:
	pass

#endregion

#region events

func _on_cell_dropped_chess(cell:BoardCell) -> void:
	score[cell.coords] = player
	player = wrapi(player + 1, 0, image_storage.images.size())
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

#endregion
