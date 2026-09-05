extends Area3D

class_name PressurePlate3D

signal plate_pressed
signal plate_released

@export var plate_id: String = "plate_1"
@export var target_gate_path: NodePath

var is_pressed: bool = false
var occupying_bodies: int = 0
var plate_mesh: MeshInstance3D = null

func _ready() -> void:
	plate_mesh = find_child("PlateMesh", true, false) as MeshInstance3D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 0
	collision_mask = 6 # Player (2) + Puzzle Objects (4)

func _on_body_entered(_body: Node3D) -> void:
	occupying_bodies += 1
	if occupying_bodies == 1 and not is_pressed:
		is_pressed = true
		_set_visual(true)
		_play_sfx("shortcut")
		plate_pressed.emit()
		_trigger_target(true)

func _on_body_exited(_body: Node3D) -> void:
	occupying_bodies = max(0, occupying_bodies - 1)
	if occupying_bodies == 0 and is_pressed:
		is_pressed = false
		_set_visual(false)
		plate_released.emit()
		_trigger_target(false)

func _set_visual(pressed: bool) -> void:
	if plate_mesh:
		plate_mesh.position.y = 0.02 if pressed else 0.1

func _trigger_target(open_flag: bool) -> void:
	if not target_gate_path.is_empty():
		var gate = get_node_or_null(target_gate_path)
		if gate and gate.has_method("set_gate_open"):
			gate.set_gate_open(open_flag)

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)
