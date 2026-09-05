extends Node3D

class_name ShortcutGate3D

@export var shortcut_id: String = "gate_ruins_shortcut"
@export var is_permanent: bool = true

var is_open: bool = false
@onready var gate_mesh: MeshInstance3D = $GateMesh
@onready var gate_collision: CollisionShape3D = $StaticBody3D/CollisionShape3D

var custom_game_state: Node = null
var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

func _ready() -> void:
	if is_permanent and game_state != null and game_state.is_shortcut_open(shortcut_id):
		set_gate_open(true, false)
	else:
		set_gate_open(false, false)

func set_gate_open(open_flag: bool, save_state: bool = true) -> void:
	is_open = open_flag
	if gate_collision:
		gate_collision.set_deferred("disabled", open_flag)
	if gate_mesh:
		gate_mesh.visible = not open_flag

	if open_flag and is_permanent and save_state and game_state != null:
		game_state.open_shortcut(shortcut_id)
		_play_sfx("shortcut")

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)
