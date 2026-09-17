extends Node3D

@onready var player_base: Base3D
@onready var enemy_base: Base3D
@onready var camera_3d: Camera3D

var enemy_spawn_timer: float = 0.0
var enemy_spawn_interval: float = 8.0

func _ready() -> void:
	_setup_environment()
	_setup_bases()
	_setup_hud()

func _setup_environment() -> void:
	# Directional Light (Sun)
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	# WorldEnvironment
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.bg_color = Color(0.4, 0.6, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.7, 0.8)
	env.ambient_light_energy = 0.8
	env_node.environment = env
	add_child(env_node)

	# Camera
	camera_3d = Camera3D.new()
	camera_3d.name = "Camera3D"
	camera_3d.position = Vector3(0, 18, 22)
	camera_3d.rotation_degrees = Vector3(-40, 0, 0)
	add_child(camera_3d)

	# Ground Plane
	var ground_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(80, 20)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.55, 0.25) # Grass green
	plane.material = mat
	ground_mesh.mesh = plane
	ground_mesh.position = Vector3(0, 0, 0)
	add_child(ground_mesh)

func _setup_bases() -> void:
	# Player Base at Left (-25, 0, 0)
	player_base = Base3D.new()
	player_base.name = "PlayerBase"
	player_base.is_player = true
	player_base.position = Vector3(-25, 0, 0)
	add_child(player_base)

	# Enemy Base at Right (25, 0, 0)
	enemy_base = Base3D.new()
	enemy_base.name = "EnemyBase"
	enemy_base.is_player = false
	enemy_base.position = Vector3(25, 0, 0)
	add_child(enemy_base)

func _setup_hud() -> void:
	var hud_scene = load("res://scenes/ui/AgeOfWarHUD.tscn")
	if hud_scene:
		var hud_instance = hud_scene.instantiate()
		add_child(hud_instance)

func _process(delta: float) -> void:
	_handle_enemy_ai(delta)

func _handle_enemy_ai(delta: float) -> void:
	enemy_spawn_timer += delta
	if enemy_spawn_timer >= enemy_spawn_interval:
		enemy_spawn_timer = 0.0

		# Enemy attempts to evolve if possible
		if AgeOfWarState.can_evolve_enemy():
			AgeOfWarState.evolve_enemy()

		# Enemy unit spawn decision
		var available_units = AgeOfWarState.ERA_UNITS[AgeOfWarState.enemy_era]
		var random_unit = available_units[randi() % available_units.size()]
		if AgeOfWarState.enemy_gold >= random_unit["cost"]:
			AgeOfWarState.enemy_gold -= random_unit["cost"]
			enemy_base.spawn_unit(random_unit)

func spawn_player_unit(unit_dict: Dictionary) -> bool:
	if AgeOfWarState.player_gold >= unit_dict["cost"]:
		AgeOfWarState.add_player_gold(-unit_dict["cost"])
		player_base.spawn_unit(unit_dict)
		return true
	return false

func build_player_turret(slot_idx: int, turret_dict: Dictionary) -> bool:
	if AgeOfWarState.player_gold >= turret_dict["cost"]:
		AgeOfWarState.add_player_gold(-turret_dict["cost"])
		player_base.add_turret(slot_idx, turret_dict)
		return true
	return false

func trigger_player_special() -> void:
	if AgeOfWarState.trigger_special(true):
		# Deal heavy damage to all enemy units on battlefield
		for child in get_children():
			if child is Unit3D and not child.is_player:
				child.take_damage(250.0 + AgeOfWarState.player_era * 150.0)
