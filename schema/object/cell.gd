class_name BoardCell
extends PanelContainer

var ENUMS := preload("res://schema/core/enum.gd").new()

@export_group('data')
@export var coords : Vector2i
@export var handle_input := true

signal dropped_chess(cell:BoardCell)

#region overrides

func _gui_input(event: InputEvent) -> void:
	if handle_input:
		if (event is InputEventMouseButton) and event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_LEFT : dropped_chess.emit(self)
	pass

#endregion

#region events

func _on_mouse_entered() -> void:
	if handle_input:
		change_content_color(Color.ORANGE_RED)
	pass

func _on_mouse_exited() -> void:
	if handle_input:
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

#endregion
