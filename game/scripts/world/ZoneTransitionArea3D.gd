extends Area3D

class_name ZoneTransitionArea3D

signal zone_transitioned(target_zone: String)

@export var target_zone: String = "TheHollow"
@export var target_position: Vector3 = Vector3(0, -20, 0)

var custom_game_state: Node = null
var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

func _ready() -> void:
	collision_layer = 16 # Interaction layer
	collision_mask = 2  # Player body
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		trigger_transition(body)

func interact(player: CharacterBody3D) -> void:
	trigger_transition(player)

func trigger_transition(player: CharacterBody3D) -> void:
	var gs = game_state
	if gs != null:
		gs.loop_state.current_zone = target_zone
	
	if is_instance_valid(player):
		if player.is_inside_tree():
			player.global_position = target_position
		else:
			player.position = target_position
		player.velocity = Vector3.ZERO
		
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("door_open")
		
	zone_transitioned.emit(target_zone)
