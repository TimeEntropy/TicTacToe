class_name BoardCell
extends PanelContainer

var ENUMS := preload("res://schema/core/enum.gd").new()

@export_group('data')
@export var coords : Vector2i

signal dropped_chess(cell:BoardCell)

#region overrides

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton) and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_LEFT : drop_chess()
	pass

#endregion

#region events

func _on_mouse_entered() -> void:
	change_content_color(Color.ORANGE_RED)
	pass

func _on_mouse_exited() -> void:
	change_content_color(Color.TRANSPARENT)
	pass

#endregion

#region tools

func change_content_color(color:Color) -> void:
	var style_box := get_theme_stylebox('panel') as StyleBoxFlat
	style_box.bg_color = color

func change_border_color(color:Color) -> void:
	var style_box := get_theme_stylebox('panel') as StyleBoxFlat
	style_box.border_color = color

func change_border_width(border_flag:int, width:int) -> void:
	var style_box := get_theme_stylebox('panel') as StyleBoxFlat
	match border_flag:
		ENUMS.CELL_BORDER_FLAGS.LEFT : style_box.border_width_left   = width
		ENUMS.CELL_BORDER_FLAGS.UP   : style_box.border_width_top    = width
		ENUMS.CELL_BORDER_FLAGS.RIGHT: style_box.border_width_right  = width
		ENUMS.CELL_BORDER_FLAGS.DOWN : style_box.border_width_bottom = width
	pass

func drop_chess() -> void:
	if get_child_count() < 1:
		print('dropped')
		var chess := preload("res://scene/prefab/chess.tscn").instantiate()
		chess.position = pivot_offset
		add_child(chess)
		dropped_chess.emit(self)
	pass

#endregion