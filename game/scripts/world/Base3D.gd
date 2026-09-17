class_name Base3D
extends StaticBody3D

@export var is_player: bool = true
var base_mesh: MeshInstance3D
var turret_slots: Array = []

func _ready() -> void:
	_build_base_mesh()
	_setup_turret_slots()

func _build_base_mesh() -> void:
	base_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(5.0, 6.0, 6.0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.5, 0.8) if is_player else Color(0.8, 0.3, 0.3)
	box.material = mat
	base_mesh.mesh = box
	base_mesh.position.y = 3.0
	add_child(base_mesh)

	# Collision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	col.position.y = 3.0
	add_child(col)

func _setup_turret_slots() -> void:
	for i in range(3):
		var slot = Node3D.new()
		slot.name = "TurretSlot_" + str(i)
		slot.position = Vector3(0, 6.2, -2.0 + i * 2.0)
		add_child(slot)
		turret_slots.append(slot)

func take_damage(amount: float) -> void:
	if is_player:
		AgeOfWarState.damage_player_base(amount)
	else:
		AgeOfWarState.damage_enemy_base(amount)

func spawn_unit(unit_dict: Dictionary) -> Unit3D:
	var unit = Unit3D.new()
	unit.setup(unit_dict, is_player)
	var spawn_pos = global_position + (Vector3(3.5, 0, 0) if is_player else Vector3(-3.5, 0, 0))
	unit.global_position = spawn_pos
	get_tree().current_scene.add_child(unit)
	return unit

func add_turret(slot_idx: int, turret_dict: Dictionary) -> Turret3D:
	if slot_idx < 0 or slot_idx >= turret_slots.size():
		return null

	var slot = turret_slots[slot_idx]
	for child in slot.get_children():
		child.queue_free()

	var turret = Turret3D.new()
	turret.setup(turret_dict, is_player)
	slot.add_child(turret)
	return turret
