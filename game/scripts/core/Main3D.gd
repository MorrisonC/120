extends Node3D

class_name Main3D

@onready var player: Node3D = $Player
@onready var orbit_camera: Camera3D = $OrbitCamera
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	if is_instance_valid(player) and is_instance_valid(orbit_camera):
		player.add_to_group("player")
		orbit_camera.set_target(player)
		orbit_camera.make_current()

	var tm = get_node_or_null("/root/TimeManager")
	if tm and tm.has_method("start_loop"):
		tm.start_loop()
