extends Node2D

@export var modal_scene: PackedScene
@export var create_game_scene: PackedScene
@export var games_scene: PackedScene
@export_category('Nodes')
@export var modal_container: CenterContainer
@export var modal_background: MarginContainer
@export var top_menu: MarginContainer
@export var leaderboard: MarginContainer
@export var leaderboard_container: VBoxContainer

var game_name_to_file = {
	'Marbles': preload("res://games/marbles_2d/marbles_2d.tscn")
}
var game

func _ready() -> void:
	print("=== GET GAMES ===")
	await ApiManager.get_games()
	print("=== GET GAMES END ===")
	leaderboard.visible = false
	modal_background.visible = false

func _on_new_game_button_pressed() -> void:
	open_new_game_modal()

func open_new_game_modal():
	var create_game_ui: CreateGameUi = create_game_scene.instantiate()
	create_game_ui.create_game.connect(_on_create_game)
	var modal = open_modal(create_game_ui)
	modal.title = "New game"
	
	
func open_modal(ui):
	var modal: Modal = modal_scene.instantiate()
	modal.close_clicked.connect(_close_modal)
	modal.add_child(ui)
	modal_container.add_child(modal)
	modal_background.visible = true
	return modal
	
func _on_create_game(config: Dictionary):
	for modal in modal_container.get_children():
		modal_container.remove_child(modal)
		modal.queue_free()
		
	_close_modal()
	
	start_game(config)

func start_game(config: Dictionary):
	#await ApiManager.clear_games()
	var resp = await ApiManager.create_game(
		config.name,
		config.rewards.map(func(item): return { 'ada': item.amount }),
		config.participants
	)
	if resp.code != 200:
		#TODO: show error
		return
	print_debug(config)
	
	print("=== GET GAMES ===")
	await ApiManager.get_games()
	print("=== GET GAMES END ===")
	
	if !game_name_to_file.has(config.type):
		push_error("Invalid game type %s" % config.type)
		return
	
	var game_scene = game_name_to_file[config.type]
	
	game = game_scene.instantiate()
	game.game_ended.connect(_on_game_ended)
	game.players.clear()
	for participant in config.participants:
		var player = Player.new()
		var unprefixed = participant.trim_prefix('addr_')
		player.name = "%s...%s" % [unprefixed.substr(0, 5), unprefixed.substr(unprefixed.length() - 5, unprefixed.length())]
		player.wallet = participant
		game.players.append(player)
		
	top_menu.visible = false
	add_child(game)

func _on_game_ended():
	var winners = game.leaderboard.map(func(p): return p.wallet)
	print_debug(winners)
	await ApiManager.set_game_winners(winners)
	await ApiManager.send_rewards()
	remove_child(game)
	game.queue_free()
	top_menu.visible = true
	
	var ui = games_scene.instantiate()
	ui.show_last_game()
	var modal = open_modal(ui)
	modal.title = "Game Result"

func _close_modal():
	for modal in modal_container.get_children():
		modal_container.remove_child(modal)
		modal.queue_free()
		
	modal_background.visible = false
	

func _physics_process(delta: float) -> void:
	leaderboard.visible = game != null
	
	if leaderboard.visible && is_instance_valid(game):
		for child in leaderboard_container.get_children():
			leaderboard_container.remove_child(child)
			child.queue_free()
			
		var pos = 1
		for player in game.leaderboard:
			var lbl = Label.new()
			
			lbl['theme_override_font_sizes/font_size'] = 30
			lbl.text = "%d. %s " % [pos, player.name]
			pos += 1
			leaderboard_container.add_child(lbl)


func _on_games_button_pressed() -> void:
	var ui = games_scene.instantiate()
	ui.show_all_games()
	var modal = open_modal(ui)
	modal.title = "Games"


func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	var ui = preload("res://ui/settings_ui.tscn").instantiate()
	var modal = open_modal(ui)
	modal.title = "Settings"
