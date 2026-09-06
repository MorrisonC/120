extends Area3D

class_name WaterPlane

@export var damage_interval: float = 1.5
@export var damage_amount: int = 1

var custom_game_state: Node = null
var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

var _damage_timer: float = 0.0
var _tracked_player: CharacterBody3D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("take_damage_from"):
		_tracked_player = body
		_damage_timer = 0.5 # Quick initial warning tick

func _on_body_exited(body: Node3D) -> void:
	if body == _tracked_player:
		_tracked_player = null
		_damage_timer = 0.0

func _physics_process(delta: float) -> void:
	if is_instance_valid(_tracked_player):
		process_water_damage(_tracked_player, delta)

func process_water_damage(player: CharacterBody3D, delta: float) -> bool:
	var gs = game_state
	if gs != null and gs.capabilities.get("can_swim", false):
		return false # Player has Fins, completely safe
	
	_damage_timer -= delta
	if _damage_timer <= 0.0:
		_damage_timer = damage_interval
		if player.has_method("take_damage_from"):
			player.take_damage_from(damage_amount, global_position)
		elif gs != null and gs.has_method("take_damage"):
			gs.take_damage(damage_amount)
		return true
	return false
