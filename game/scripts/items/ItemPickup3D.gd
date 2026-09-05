extends Area3D

class_name ItemPickup3D

@export var item_id: String = "Sword"
@export var display_name: String = "Cursed Melee Blade"
@export var rotation_speed: float = 2.0
@export var bob_amplitude: float = 0.15
@export var bob_frequency: float = 3.0

var _initial_y: float = 0.0
var _time_passed: float = 0.0

@onready var light: OmniLight3D = get_node_or_null("OmniLight3D")

var custom_game_state: Node = null
var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

func _ready() -> void:
	_initial_y = position.y
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2 # Player

	if game_state != null and game_state.has_item(item_id):
		queue_free()

func _process(delta: float) -> void:
	_time_passed += delta
	rotate_y(rotation_speed * delta)
	position.y = _initial_y + sin(_time_passed * bob_frequency) * bob_amplitude

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and game_state != null:
		game_state.add_item(item_id)
		_play_sfx("item_pickup")
		
		if get_tree() and get_tree().root:
			var hud = get_tree().root.find_child("HUD", true, false)
			if hud and hud.has_method("show_banner"):
				hud.show_banner("Acquired Item: " + display_name)
			
		queue_free()

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)
