class_name Turret3D
extends Node3D

var turret_id: String = ""
var turret_name: String = ""
var damage: float = 15.0
var attack_range: float = 12.0
var fire_rate: float = 1.5
var is_player: bool = true

var fire_cooldown: float = 0.0
var target_unit = null

func setup(turret_dict: Dictionary, p_is_player: bool) -> void:
	turret_id = turret_dict.get("id", "turret")
	turret_name = turret_dict.get("name", "Turret")
	damage = turret_dict.get("damage", 15.0)
	attack_range = turret_dict.get("range", 12.0)
	fire_rate = turret_dict.get("fire_rate", 1.5)
	is_player = p_is_player

	var model_path = turret_dict.get("model", "")
	if FileAccess.file_exists(model_path):
		var gltf_scene = load(model_path)
		if gltf_scene:
			var instance = gltf_scene.instantiate()
			add_child(instance)
	else:
		_create_placeholder()

func _create_placeholder() -> void:
	var mesh_inst = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.4
	cyl.height = 1.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.7, 0.9) if is_player else Color(0.9, 0.4, 0.1)
	cyl.material = mat
	mesh_inst.mesh = cyl
	mesh_inst.position.y = 0.5
	add_child(mesh_inst)

func _process(delta: float) -> void:
	if fire_cooldown > 0.0:
		fire_cooldown -= delta

	_find_target()

	if is_instance_valid(target_unit):
		look_at(Vector3(target_unit.global_position.x, global_position.y, target_unit.global_position.z), Vector3.UP)
		if fire_cooldown <= 0.0:
			_fire_shot()
			fire_cooldown = fire_rate

func _find_target() -> void:
	var best_target = null
	var min_dist = attack_range

	var main_scene = get_tree().current_scene
	if not main_scene:
		return

	for child in main_scene.get_children():
		if child is Unit3D and child.is_player != is_player and child.hp > 0:
			var d = global_position.distance_to(child.global_position)
			if d < min_dist:
				min_dist = d
				best_target = child

	target_unit = best_target

func _fire_shot() -> void:
	if not is_instance_valid(target_unit):
		return

	var proj = Projectile3D.new()
	proj.setup(target_unit.global_position + Vector3(0, 0.5, 0), damage, is_player, target_unit)
	proj.global_position = global_position + Vector3(0, 0.8, 0)
	get_tree().current_scene.add_child(proj)
