extends Node

@export_group('node')
@export var game_viewport : SubViewport
@export var camera     : Camera2D
@export var win_prompt : Label
@export var pointing : Control
@export var info_PC  : InfoPanel
@export var info_ME  : InfoPanel

@export_subgroup('buttons', 'button_')
@export var button_replay : Button
@export var button_undo   : Button
@export var button_giveup : Button

var board : BoardPanel

#region overrides

func _ready() -> void:
	# setup nodes
	get_window().min_size = Vector2i(
		ProjectSettings.get_setting('display/window/size/viewport_width'),
		ProjectSettings.get_setting('display/window/size/viewport_height')
	)
	pointing.pivot_offset = Vector2(pointing.size.x / 2.0, pointing.size.y + 0.5)
	button_replay.pressed.connect(replay)
	button_giveup.pressed.connect(giveup)
	button_undo.pressed.connect(undo)
	replay()
	pass

#endregion

#region events

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

func _on_duel_giveup(player_id:int) -> void:
	win_prompt.show()
	win_prompt.text = '{0} GIVEUP!!!'.format([board.players[player_id].nickname])
	pass

#endregion

#region tools

func replay() -> void:
	if board:
		board.queue_free()
	var new_board := preload('res://scene/prefab/board.tscn').instantiate() as BoardPanel
	game_viewport.add_child(new_board)
	board = new_board
	# reset nodes
	camera.position = board.size / 2.0
	win_prompt.hide()
	board.player_changed.connect(_on_border_player_changed)
	board.duel_win.connect(_on_duel_win)
	board.duel_draw.connect(_on_duel_draw)
	info_PC.nickname = board.players[0].nickname
	info_ME.nickname = board.players[1].nickname
	info_PC.image.texture = board.players[0].used_chess_image
	info_ME.image.texture = board.players[1].used_chess_image
	board.current_player = 1
	pass

func giveup() -> void:
	board.let_giveup(1)
	pass

func undo() -> void:
	board.history.undo()
	if board.last_player == 1:
		board.history.undo()
	win_prompt.hide()
	pass

#endregion
