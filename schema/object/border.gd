extends GridContainer

var ENUMS := preload("res://schema/core/enum.gd").new()

@export var layout := Vector2i.ZERO : set = set_layout

#region overrides

func _ready() -> void:
	pass

#endregion

#region tools

func set_layout(value:Vector2i) -> void:
	for child in get_children():
		child.queue_free()
	layout = value
	self.size = Vector2.ZERO
	self.columns = value.x
	for i in (value.x * value.y):
		var cell := preload("res://scene/prefab/cell.tscn").instantiate()
		add_child(cell)
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
