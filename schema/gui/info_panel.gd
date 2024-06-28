@tool
class_name InfoPanel
extends PanelContainer

@export_group('node')
@export var image : TextureRect
@export var label : Label

@export_group('data')
@export var nickname : String : set = _set_nickname, get = _get_nickname

func _set_nickname(value:String) -> void:
	if !is_node_ready():
		await ready
	label.text = value
	pass

func _get_nickname() -> String:
	if !is_node_ready():
		await ready
	return label.text
