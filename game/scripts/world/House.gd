extends Area3D

class_name House

@export var house_id: String = "house_village_1"
@export var display_name: String = "Starting Cabin"
@export var spawn_offset: Vector3 = Vector3(0.0, 0.5, 1.5)

@onready var lantern_light: OmniLight3D = $LanternLight
@onready var bookmark_particles: CPUParticles3D = $BookmarkParticles

var custom_game_state: Node = null
var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2 # Player layer

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and game_state != null:
		var spawn_pos = global_position + spawn_offset
		if game_state.run_state.bookmarked_house_id != house_id:
			game_state.set_bookmark(house_id, spawn_pos)
			_play_sfx("bookmark")
			if bookmark_particles:
				bookmark_particles.emitting = true

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)
