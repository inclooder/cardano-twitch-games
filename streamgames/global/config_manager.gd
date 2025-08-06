extends Node

var firefly_wallet_address: String = ""

func _ready() -> void:
	read_config()

func save_config():
	var config = ConfigFile.new()
	
	var err = config.load("user://config.cfg")

	# If the file didn't load, ignore it.
	if err != OK:
		return

	config.set_value("Main", "firefly_wallet_address", firefly_wallet_address)
	config.save("user://config.cfg")
	
	
func read_config():
	var config = ConfigFile.new()
	var err = config.load("user://config.cfg")

	# If the file didn't load, ignore it.
	if err != OK:
		return
	
	firefly_wallet_address = config.get_value("Main", "firefly_wallet_address", "")
