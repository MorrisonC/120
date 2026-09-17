class_name Unit3D
extends CharacterBody3D

signal died(unit)

@export var is_player: bool = true
var unit_id: String = ""
var unit_name: String = ""
var max_hp: float = 100.0
var hp: float = 100.0
var attack_damage: float = 10.0
var attack_range: float = 1.5
var move_speed: float = 3.0
var attack_type: String = "melee" # "melee", "ranged", "heavy", "boss"
var gold_reward: int = 20
var xp_reward: int = 30

var attack_cooldown: float = 0.0
var attack_rate: float = 1.2
var target_entity = null # Enemy Unit3D or Base3D

var health_bar_3d: Sprite3D

func setup(unit_dict: Dictionary, p_is_player: bool) -> void:
	unit_id = unit_dict.get("id", "unit")
	unit_name = unit_dict.get("name", "Unit")
	is_player = p_is_player
	max_hp = unit_dict.get("hp", 100.0)
	hp = max_hp
	attack_damage = unit_dict.get("damage", 10.0)
	attack_range = unit_dict.get("range", 1.5)
	move_speed = unit_dict.get("speed", 3.0)
	attack_type = unit_dict.get("type", "melee")
	gold_reward = int(unit_dict.get("cost", 15) * 1.5)
	xp_reward = int(unit_dict.get("cost", 15) * 2.0)

	var model_path = unit_dict.get("model", "")
	if FileAccess.file_exists(model_path):
		var gltf_scene = load(model_path)
		if gltf_scene:
			var instance = gltf_scene.instantiate()
			instance.scale = Vector3.ONE * unit_dict.get("scale", 1.0)
			# Face direction
			if not is_player:
				instance.rotation.y = PI
			add_child(instance)
	else:
		_create_placeholder_mesh(unit_dict.get("scale", 1.0))

	_setup_collision()
	_setup_health_bar()

func _create_placeholder_mesh(s: float) -> void:
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.8, 1.6, 0.8) * s
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 1.0) if is_player else Color(1.0, 0.3, 0.3)
	box.material = mat
	mesh_inst.mesh = box
	mesh_inst.position.y = box.size.y * 0.5
	add_child(mesh_inst)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 1.8
	col.shape = capsule
	col.position.y = 0.9
	add_child(col)

func _setup_health_bar() -> void:
	health_bar_3d = Sprite3D.new()
	health_bar_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar_3d.position.y = 2.2
	var img = Image.create(64, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.2, 0.2))
	for x in range(62):
		for y in range(1, 7):
			img.set_pixel(x + 1, y, Color(0.1, 0.9, 0.2) if is_player else Color(0.9, 0.2, 0.1))
	var tex = ImageTexture.create_from_image(img)
	health_bar_3d.texture = tex
	add_child(health_bar_3d)

func _update_health_bar() -> void:
	if not health_bar_3d:
		return
	var ratio = max(0.0, hp / max_hp)
	health_bar_3d.scale.x = ratio

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	# Find closest enemy unit or base
	_find_target()

	if is_instance_valid(target_entity):
		var dist = global_position.distance_to(target_entity.global_position)
		var effective_range = attack_range
		if target_entity is Base3D:
			# Account for base collision box width (2.5 units from center)
			effective_range += 2.5

		if dist <= effective_range:
			velocity = Vector3.ZERO
			if attack_cooldown <= 0.0:
				_perform_attack()
				attack_cooldown = attack_rate
		else:
			_move_towards(target_entity.global_position, delta)
	else:
		# Default move forward along X axis
		var move_dir = Vector3(1, 0, 0) if is_player else Vector3(-1, 0, 0)
		velocity = move_dir * move_speed
		move_and_slide()

func _move_towards(target_pos: Vector3, _delta: float) -> void:
	var dir = (target_pos - global_position)
	dir.y = 0
	dir = dir.normalized()
	velocity = dir * move_speed
	if dir.length() > 0.1:
		look_at(global_position + dir, Vector3.UP)
	move_and_slide()

func _find_target() -> void:
	var best_target = null
	var min_dist = 9999.0

	var main_scene = get_tree().current_scene
	if not main_scene:
		return

	# Look for units
	for child in main_scene.get_children():
		if child is Unit3D and child != self and child.is_player != is_player and child.hp > 0:
			var d = global_position.distance_to(child.global_position)
			if d < min_dist:
				min_dist = d
				best_target = child

	# If no units in range or closer, target enemy base
	var base_node = main_scene.get_node_or_null("EnemyBase") if is_player else main_scene.get_node_or_null("PlayerBase")
	if base_node and is_instance_valid(base_node):
		var d_base = global_position.distance_to(base_node.global_position)
		if d_base < min_dist:
			best_target = base_node

	target_entity = best_target

func _perform_attack() -> void:
	if not is_instance_valid(target_entity):
		return

	if attack_type == "ranged":
		var proj = Projectile3D.new()
		proj.setup(target_entity.global_position + Vector3(0, 0.5, 0), attack_damage, is_player, target_entity)
		proj.global_position = global_position + Vector3(0, 1.2, 0)
		get_tree().current_scene.add_child(proj)
	else:
		if target_entity.has_method("take_damage"):
			target_entity.take_damage(attack_damage)

func take_damage(amount: float) -> void:
	hp -= amount
	_update_health_bar()
	if hp <= 0:
		_die()

func _die() -> void:
	if is_player:
		AgeOfWarState.enemy_gold += int(gold_reward * 0.5)
	else:
		AgeOfWarState.add_player_gold(gold_reward)
		AgeOfWarState.add_player_xp(xp_reward)

	died.emit(self)
	queue_free()
