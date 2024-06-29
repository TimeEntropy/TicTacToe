class_name BoardCell
extends PanelContainer

enum CELL_BORDER_FLAGS { LEFT, UP, RIGHT, DOWN, COUNT }

@export_group('data')
@export var coords : Vector2i
@export var handle_drop := true

signal dropped_chess(cell:BoardCell)

#region overrides

func _gui_input(event: InputEvent) -> void:
	if handle_drop:
		if (event is InputEventMouseButton) and event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_LEFT : dropped_chess.emit(self)
	pass

#endregion

#region events

func _on_mouse_entered() -> void:
	if handle_drop:
		change_content_color(Color.ORANGE_RED)
	pass

func _on_mouse_exited() -> void:
	if handle_drop:
		change_content_color(Color.TRANSPARENT)
	pass

#endregion

#region tools

func change_content_color(color:Color) -> void:
	var style_box := get_theme_stylebox('panel') as StyleBoxFlat
	style_box.bg_color = color

#endregion
