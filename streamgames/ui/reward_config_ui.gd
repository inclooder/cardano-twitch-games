@tool
class_name RewardConfigUi
extends MarginContainer

signal remove_clicked

enum RewardType {
	ADA = 0,
	NATIVE_ASSET = 1
}

@export var reward_type: RewardType = RewardType.ADA : set = _set_reward_type
@export var amount: int = 0# : set = _set_amount
@export_category('Nodes')
@export var remove_button: Button
@export var amount_edit: LineEdit
@export var option_button: OptionButton

#func _set_amount(_amount: int):
	#amount = _amount
	#
	#if !is_node_ready():
		#await ready
		#
	#amount_edit.text = "%d" % amount
	#amount_edit.caret_column = amount_edit.text.length()

func _set_reward_type(_reward_type: RewardType):
	reward_type = _reward_type
	
	if !is_node_ready():
		await ready
		
	option_button.selected = reward_type

func _on_remove_button_pressed() -> void:
	remove_clicked.emit()


func _on_option_button_item_selected(index: int) -> void:
	reward_type = index


func _on_line_edit_text_changed(new_text: String) -> void:
	var val = float(new_text)
	amount = int(val * 1000000)
