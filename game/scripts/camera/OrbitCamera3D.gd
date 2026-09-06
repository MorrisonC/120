extends Camera3D

class_name OrbitCamera3D

@export var target_path: NodePath
@export var follow_offset: Vector3 = Vector3(0.0, 7.5, 9.5)
@export var look_offset: Vector3 = Vector3(0.0, 1.2, 0.0)
@export var follow_speed: float = 8.0
@export var max_orbit_angle_deg: float = 45.0
@export var orbit_sensitivity: float = 0.003
@export var orbit_return_speed: float = 3.0

var target_node: Node3D = null
var current_orbit_yaw: float = 0.0
var _is_dragging_orbit: bool = false
var room_override_camera: Camera3D = null

@export var screen_shake_enabled: bool = true
var trauma: float = 0.0
var max_shake_offset: float = 0.35
var trauma_decay: float = 3.0

func add_trauma(amount: float) -> void:
	if not screen_shake_enabled:
		trauma = 0.0
		return
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _ready() -> void:
	if not target_path.is_empty():
		target_node = get_node_or_null(target_path)

func set_target(node: Node3D) -> void:
	target_node = node

func set_room_override(override_cam: Camera3D) -> void:
	room_override_camera = override_cam
	if room_override_camera != null:
		room_override_camera.make_current()
	else:
		make_current()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_dragging_orbit = event.pressed
	elif event is InputEventMouseMotion and _is_dragging_orbit:
		var yaw_delta = -event.relative.x * orbit_sensitivity
		var max_rad = deg_to_rad(max_orbit_angle_deg)
		current_orbit_yaw = clamp(current_orbit_yaw + yaw_delta, -max_rad, max_rad)

func _process(delta: float) -> void:
	if room_override_camera != null:
		return

	if not _is_dragging_orbit and abs(current_orbit_yaw) > 0.001:
		current_orbit_yaw = lerp(current_orbit_yaw, 0.0, orbit_return_speed * delta)

	if not is_instance_valid(target_node):
		return

	var rotated_offset = follow_offset.rotated(Vector3.UP, current_orbit_yaw)
	var desired_pos = target_node.global_position + rotated_offset
	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	var target_look = target_node.global_position + look_offset
	look_at(target_look, Vector3.UP)

	if trauma > 0.0:
		trauma = max(0.0, trauma - trauma_decay * delta)
		var shake = trauma * trauma
		var shake_offset = Vector3(
			randf_range(-1.0, 1.0) * max_shake_offset * shake,
			randf_range(-1.0, 1.0) * max_shake_offset * shake,
			randf_range(-1.0, 1.0) * max_shake_offset * shake
		)
		global_position += shake_offset

