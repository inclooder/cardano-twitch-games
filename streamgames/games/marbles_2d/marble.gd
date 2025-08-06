@tool
class_name Marble
extends RigidBody2D

@export var display_name: String = "Marble 1" : set = _set_display_name
@export var color: Color = Color.AQUAMARINE : set = _set_color
@export_category('Nodes')
@export var visible_body: MeshInstance2D
@export var name_label: Label

var collision_bodies: Dictionary

func _set_display_name(_display_name: String):
	display_name = _display_name
	
	if !is_node_ready():
		await ready
		
	name_label.text = display_name
	

func _set_color(_color):
	color = _color
	
	if !is_node_ready():
		await ready
		
	visible_body.modulate = color


func _on_body_entered(body: Node) -> void:
	collision_bodies[body] = true
	SoundManager.play_sound(SoundManager.Sound.MARBLE_HIT, global_position)
	
	
func _on_body_exited(body: Node) -> void:
	collision_bodies.erase(body)

func _physics_process(delta: float) -> void:
	if freeze:
		return
	
	if is_on_floor() && randf() < 0.8:
		var angle = randf_range(0.0, 45.0)
		apply_impulse(Vector2.UP.rotated(deg_to_rad(angle)) * 50)
		
func is_on_floor():
	for body in collision_bodies.keys():
		if body.is_in_group("terrain"):
			return true
			
	return false

func _process(delta: float) -> void:
	var screen_position = get_viewport_transform() * global_position
	var offset = name_label.get_rect().size / 2.0
	name_label.global_position = screen_position - offset + Vector2.UP * 10.0
