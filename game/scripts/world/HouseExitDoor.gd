extends Area3D

class_name HouseExitDoor

@export var return_position: Vector3 = Vector3(0.0, 0.5, 2.5)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2 # Player layer

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.global_position = return_position
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_sfx"):
			am.play_sfx("door_close")
