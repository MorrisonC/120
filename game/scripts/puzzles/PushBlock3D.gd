extends CharacterBody3D

class_name PushBlock3D

@export var block_id: String = "block_ruins_1"
@export var push_speed: float = 3.5

var initial_position: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var is_moving: bool = false

var custom_game_state: Node = null

var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

var time_manager: Node:
	get:
		return get_node_or_null("/root/TimeManager")

func _ready() -> void:
	initial_position = global_position
	target_position = initial_position
	collision_layer = 4 # Puzzle/Object layer
	collision_mask = 1 # Environment

	if time_manager != null:
		time_manager.loop_expired.connect(_on_loop_expired)

func push(direction: Vector3) -> bool:
	if game_state == null or not game_state.capabilities.can_push:
		if game_state:
			game_state.trigger_hint("This block is too heavy. You need a boost of strength (Coffee)!")
		return false
	
	if is_moving:
		return false

	var snap_dir = Vector3.ZERO
	if abs(direction.x) > abs(direction.z):
		snap_dir.x = sign(direction.x)
	else:
		snap_dir.z = sign(direction.z)

	var proposed_pos = global_position + snap_dir * 2.0
	target_position = proposed_pos
	is_moving = true
	_play_sfx("hit")
	return true

func _physics_process(delta: float) -> void:
	if is_moving:
		global_position = global_position.move_toward(target_position, push_speed * delta)
		if global_position.distance_to(target_position) < 0.05:
			global_position = target_position
			is_moving = false

func interact(player: CharacterBody3D) -> void:
	var dir = (global_position - player.global_position).normalized()
	push(dir)

func _on_loop_expired() -> void:
	global_position = initial_position
	target_position = initial_position
	is_moving = false

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)
