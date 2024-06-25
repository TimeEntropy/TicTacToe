extends PanelContainer

var ENUMS := preload("res://schema/core/enum.gd").new()

#region events

func _on_mouse_entered() -> void:
	change_content_color(Color.ORANGE_RED)
	pass # Replace with function body.

func _on_mouse_exited() -> void:
	change_content_color(Color.TRANSPARENT)
	pass # Replace with function body.

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