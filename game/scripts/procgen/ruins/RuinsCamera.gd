extends Camera3D
class_name RuinsCamera

@export var target_path: NodePath
var target: Node3D
var follow_offset: Vector3 = Vector3(0, 10, 8)
var lerp_speed: float = 5.0

var occluding_nodes: Array = []

func _ready() -> void:
	make_current()
	rotation_degrees = Vector3(-50, 0, 0)
	if not target_path.is_empty():
		target = get_node_or_null(target_path)

func set_target(new_target: Node3D) -> void:
	target = new_target

func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		var target_pos := target.global_position + follow_offset
		global_position = global_position.lerp(target_pos, lerp_speed * delta)
		check_occlusion(target.global_position)

func check_occlusion(target_pos: Vector3) -> void:
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return

	var ray_query := PhysicsRayQueryParameters3D.create(global_position, target_pos)
	var result := space_state.intersect_ray(ray_query)

	if not result.is_empty() and result.collider != target:
		var collider = result.collider
		if not occluding_nodes.has(collider):
			occluding_nodes.append(collider)
			apply_dither_fade(collider, true)
	else:
		_clear_occlusion()

func apply_dither_fade(node: Object, fade_out: bool) -> void:
	if node is MeshInstance3D:
		var mat = node.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if fade_out else BaseMaterial3D.TRANSPARENCY_DISABLED
			mat.albedo_color.a = 0.4 if fade_out else 1.0

func _clear_occlusion() -> void:
	for node in occluding_nodes:
		if is_instance_valid(node):
			apply_dither_fade(node, false)
	occluding_nodes.clear()
