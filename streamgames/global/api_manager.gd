extends Node

	
var last_invoke_id = 0

var contract = "contract@0.2.0"

func _ready() -> void:
	var resp
	var addr = ConfigManager.firefly_wallet_address
	resp = await _firefly_contract_request("set_system_address", [{ name = "address" }], [addr])
	print_debug(resp)
	
func create_game(game_name: String, rewards: Array, participants: Array[String]):
	var resp = await _firefly_contract_request(
		"create_game",
		 [{ name = "name" }, { name = "rewards" }, { "name" = "participants" }],
		 [game_name, rewards, participants]
	)
	print_debug(resp)
	return resp
	
func clear_games():
	var resp = await _firefly_contract_request("clear_games", [], [])
	print_debug(resp)

func get_games():
	var resp = await _firefly_contract_request("get_games", [], [])
	print_debug(resp)
	return resp
	
func set_game_winners(winners):
	var resp = await _firefly_contract_request(
		"set_game_winners",
		 [{ name = "winners" }],
		 [winners]
	)
	print_debug(resp)
	
func send_rewards():
	var resp = await _firefly_contract_invoke(
		ConfigManager.firefly_wallet_address,
		"send_rewards",
		[],
		[]
	)
	print_debug(resp)
	
func _firefly_contract_request(method: String, params_def: Array[Dictionary] = [], params: Array = []):
	var data = {
		address = contract,
		method = {
			name = method,
			params = params_def
		},
		params = params
	}
	
	return await _post_request("http://127.0.0.1:5102/api/v1/contracts/query", data)

	
func _firefly_contract_invoke(from: String, method: String, params_def: Array[Dictionary] = [], params: Array = []):
	last_invoke_id += 1
	var data = {
		address = contract,
		id = str(last_invoke_id),
		from = from,
		method = {
			name = method,
			params = params_def
		},
		params = params
	}
	
	print_debug(data)
	
	return await _post_request("http://127.0.0.1:5102/api/v1/contracts/invoke", data)
	
func _post_request(url: String, data, timeout: float = 10.0):
	var http = HTTPRequest.new()
	http.timeout = timeout
	add_child(http)

	var body = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	var error = http.request(url, headers, HTTPClient.METHOD_POST, body)

	if error != OK:
		push_error("An error occurred in the HTTP request.")

	var res = await http.request_completed
	var result: HTTPRequest.Result = res[0]
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("HTTP request failed, reason ", str(result))
		return null
		
	var resp_body = res[3]
	var resp_txt = resp_body.get_string_from_utf8()

	remove_child(http)

	return {
		code = res[1],
		body = JSON.parse_string(resp_txt)
	}
	
func _get_request(url: String):
	var http = HTTPRequest.new()
	add_child(http)

	var error = http.request(url)

	if error != OK:
		push_error("An error occurred in the HTTP request.")

	var res = await http.request_completed
	var result: HTTPRequest.Result = res[0]
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("HTTP request failed, reason ", str(result))
		return null
		
	var resp_body = res[3]
	var resp_txt = resp_body.get_string_from_utf8()

	remove_child(http)

	return {
		code = res[1],
		body = resp_txt
	}
