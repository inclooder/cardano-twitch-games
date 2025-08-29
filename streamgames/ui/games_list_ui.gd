extends MarginContainer

@export var game_result_ui_scene: PackedScene
@export_category('Nodes')
@export var games_container: VBoxContainer


func show_all_games():
	if !is_node_ready():
		await ready
	var resp = await ApiManager.get_games()
	_update_games(resp.body)
	
func show_last_game():
	if !is_node_ready():
		await ready
	var resp = await ApiManager.get_games()
	_update_games([resp.body.back()])

func _update_games(games):
	if !is_node_ready():
		await ready
	
	for child in games_container.get_children():
		games_container.remove_child(child)
		child.queue_free()
	
	for game in games:
		var result_ui = game_result_ui_scene.instantiate()
		result_ui.game_name = game.name
		
		var winners: String = ""
		
		var idx = 0
		for reward in game.rewards:
			if game.winners.size() > idx:
				winners += "%s won %.2f ADA\n" % [game.winners[idx], reward.ada / 1000000]
				
			idx += 1

		result_ui.winners = winners
		result_ui.tx_hash = game['txHash'] if game['txHash'] != null else ""
	
		games_container.add_child(result_ui)
		
