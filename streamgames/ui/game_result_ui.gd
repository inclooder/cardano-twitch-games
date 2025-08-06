extends MarginContainer

@export var game_name: String : set = _set_game_name
@export var tx_hash: String : set = _set_tx_hash
@export var winners: String : set = _set_winners
@export_category('Nodes')
@export var game_name_label: Label
@export var winners_label: Label
@export var tx_hash_label: Label

func _set_winners(_winners: String):
	winners = _winners
	
	if !is_node_ready():
		await ready

	winners_label.text = winners

func _set_tx_hash(_tx_hash: String):
	tx_hash = _tx_hash
	
	if !is_node_ready():
		await ready

	tx_hash_label.text = tx_hash

func _set_game_name(_game_name: String):
	game_name = _game_name
	
	if !is_node_ready():
		await ready

	game_name_label.text = game_name


func _on_copy_tx_hash_button_pressed() -> void:
	DisplayServer.clipboard_set(tx_hash)
