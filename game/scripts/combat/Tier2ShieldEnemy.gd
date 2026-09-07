extends "res://scripts/combat/EnemyBase3D.gd"

class_name Tier2ShieldEnemy

@export var shield_angle_deg: float = 80.0

func _ready() -> void:
	max_health = 2
	move_speed = 2.4
	super._ready()

func take_hit(damage: int, source_pos: Vector3) -> void:
	# Check if hit came from the front (blocked by shield)
	var forward = -mesh_root.global_transform.basis.z.normalized()
	var to_source = (source_pos - global_position).normalized()
	var angle_to_source = rad_to_deg(forward.angle_to(to_source))

	if angle_to_source <= shield_angle_deg:
		# Blocked!
		_play_sfx("hit")
		var gs = get_node_or_null("/root/GameState")
		if gs and gs.has_method("trigger_hint"):
			gs.trigger_hint("Shield blocked the attack! Roll or flank around behind.")
		return

	# Successful flank hit
	super.take_hit(damage, source_pos)

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)
