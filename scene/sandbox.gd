@tool
extends Node

@export_group('node')
@export var win_prompt : Label
@export var pointing : Control
@export var board    : BoardPanel
@export var info_PC  : InfoPanel
@export var info_ME  : InfoPanel

@export_subgroup('buttons')
@export var button_surrender : Button

func _ready() -> void:
	get_window().min_size = Vector2i(
		ProjectSettings.get_setting('display/window/size/viewport_width'),
		ProjectSettings.get_setting('display/window/size/viewport_height')
	)
	pointing.pivot_offset = Vector2(pointing.size.x / 2.0, pointing.size.y + 0.5)
	board.duel_win.connect(_on_duel_win)
	board.duel_draw.connect(_on_duel_draw)
	info_PC.nickname = board.players[0].nickname
	info_ME.nickname = board.players[1].nickname
	pass

func _on_border_player_changed(current: int) -> void:
	pointing.rotation_degrees = current * 180.0
	pass

func _on_duel_win(player_id:int) -> void:
	win_prompt.show()
	win_prompt.text = '{0} WIN!!!'.format([board.players[player_id].nickname])
	pass

func _on_duel_draw() -> void:
	win_prompt.show()
	win_prompt.text = 'DRAW!!!'
	pass
