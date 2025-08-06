extends MarginContainer

@export_category('Nodes')
@export var firefly_wallet_address_line_edit: LineEdit

func _ready() -> void:
	firefly_wallet_address_line_edit.text = ConfigManager.firefly_wallet_address

func _on_save_button_pressed() -> void:
	ConfigManager.firefly_wallet_address = firefly_wallet_address_line_edit.text
	ConfigManager.save_config()
