class_name CreateGameUi
extends MarginContainer

signal create_game(config: Dictionary)

@export var reward_config_ui_scene: PackedScene
@export_category('Nodes')
@export var rewards_container: VBoxContainer
@export var create_button: Button
@export var participants_text_edit: TextEdit
@export var name_line_edit: LineEdit
@export var game_type_option_button: OptionButton

func _ready() -> void:
	create_button.disabled = true

func _on_create_button_pressed() -> void:
	var rewards = get_rewards()
	var participants = get_participants()
	
	var config = {
		'name': name_line_edit.text,
		'type': game_type_option_button.get_item_text(game_type_option_button.selected),
		'rewards': rewards,
		'participants': participants,
	}
	
	create_game.emit(config)

func _on_add_reward_button_pressed() -> void:
	var reward_ui: RewardConfigUi = reward_config_ui_scene.instantiate()
	rewards_container.add_child(reward_ui)
	reward_ui.remove_clicked.connect(
		func(): 
			rewards_container.remove_child(reward_ui)
			reward_ui.queue_free()
	)
	
func get_participants() -> Array[String]:
	var participants: Array[String]
	
	var txt = participants_text_edit.text
	txt = txt.replace("\n", ' ')
	var items = txt.split(' ')
	for item in items:
		var addr = item.lstrip(' ').rstrip(' ')
		if addr.length() > 0:
			participants.append(addr)
	
	return participants
	
func get_rewards() -> Array[Dictionary]:
	var rewards: Array[Dictionary]
	
	for child: RewardConfigUi in rewards_container.get_children():
		if child.amount > 0:
			rewards.append({
				type = child.reward_type,
				amount = child.amount
			})
	
	return rewards

func is_config_valid():
	var has_name = name_line_edit.text.length() > 0
	var has_rewards = get_rewards().size() > 0
	var has_participants = get_participants().size() > 0
	
	return has_rewards && has_participants && has_name
	
func _physics_process(delta: float) -> void:
	create_button.disabled = !is_config_valid()
	
