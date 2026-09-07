extends "res://scripts/combat/EnemyBase3D.gd"

class_name Tier1PatrolEnemy

@export var patrol_radius: float = 4.0
var patrol_angle: float = 0.0

func _ready() -> void:
	max_health = 1
	super._ready()

func _process_ai(delta: float) -> void:
	if not is_instance_valid(target_player):
		_find_player()

	if is_instance_valid(target_player):
		var dist = global_position.distance_to(target_player.global_position)
		if dist <= attack_reach:
			_start_telegraph()
			return
		elif dist <= detection_radius:
			super._process_ai(delta)
			return

	# Idle patrol loop
	patrol_angle += delta * 0.8
	var target_offset = Vector3(cos(patrol_angle) * patrol_radius, 0.0, sin(patrol_angle) * patrol_radius)
	var patrol_dest = spawn_position + target_offset
	var dir = (patrol_dest - global_position).normalized()
	velocity.x = dir.x * (move_speed * 0.5)
	velocity.z = dir.z * (move_speed * 0.5)
	move_and_slide()
