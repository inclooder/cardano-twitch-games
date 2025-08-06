extends Node2D

signal game_ended

@export var marble_scene: PackedScene
@export_category('Nodes')
@export var camera: Camera2D
@export var marbles_container: Node2D
@export var starting_point: Node2D

var players: Array[Player]
var leaderboard: Array[Player]
var player_to_marble: Dictionary[Player, Marble]

const CAMERA_SPEED = 5.0

func _ready() -> void:
	start_round()
	
func start_round():
	var i = 0
	for player in players:
		var marble: Marble = marble_scene.instantiate()
		marble.display_name = player.name
		marble.color = Color.from_hsv(randf(), 0.5, 0.5)
		marble.position.y = -500 + i * -100
		marble.position.x = i * 50
		marbles_container.add_child(marble)
		player_to_marble[player] = marble
		i += 1

func _process(delta: float) -> void:
	var follow_player = leaderboard.front()
	
	if follow_player:
		var marble = player_to_marble[follow_player]
		camera.global_position = lerp(camera.global_position, marble.global_position, CAMERA_SPEED * delta)


func _on_update_leaderboard_timeout() -> void:
	var new_leaderboard = players.duplicate()
	new_leaderboard.sort_custom(func(a, b): return player_to_marble[a].global_position.x > player_to_marble[b].global_position.x)
	
	leaderboard = new_leaderboard


func _on_end_area_body_entered(body: Node2D) -> void:
	print_debug("body entered ", body)
	SoundManager.play_sound(SoundManager.Sound.MARBLE_WIN, body.global_position)
	_stop_marbles()
	game_ended.emit()

func _stop_marbles():
	for marble in marbles_container.get_children():
		marble.set_deferred("freeze", true)
		marble.set_deferred("angular_velocity", 0)
		marble.set_deferred("linear_velocity", Vector2.ZERO)
