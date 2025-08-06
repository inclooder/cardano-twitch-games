extends Node

@export_category('Nodes')

enum Sound {
	MARBLE_HIT,
	MARBLE_WIN
}

var SoundToFile: Dictionary = {
	Sound.MARBLE_HIT: preload("res://assets/sounds/marble-hit.ogg"),
	Sound.MARBLE_WIN: preload("res://assets/sounds/marble-win.mp3")
}

func play_sound(sound: Sound, global_position: Vector2):
	var stream = SoundToFile.get(sound)
	
	if stream:
		var stream_player = AudioStreamPlayer2D.new()
		stream_player.global_position = global_position
		add_child(stream_player)
		stream_player.pitch_scale = randf_range(0.6, 1.0)
		stream_player.stream = stream
		stream_player.play()
		await stream_player.finished
		remove_child(stream_player)
		
	
