extends Node3D
class_name RuinsDungeon

const RuinsGraphGeneratorScript = preload("res://scripts/procgen/ruins/RuinsGraphGenerator.gd")
const RuinsGridMapBuilderScript = preload("res://scripts/procgen/ruins/RuinsGridMapBuilder.gd")
const RuinsPropScattererScript = preload("res://scripts/procgen/ruins/RuinsPropScatterer.gd")
const RuinsNavigationManagerScript = preload("res://scripts/procgen/ruins/RuinsNavigationManager.gd")
const RuinsEnvironmentScript = preload("res://scripts/procgen/ruins/RuinsEnvironment.gd")
const RuinsCameraScript = preload("res://scripts/procgen/ruins/RuinsCamera.gd")

@export var current_seed: int = 42
@export var grid_width: int = 32
@export var grid_depth: int = 32

var graph_generator
var grid_builder
var prop_scatterer
var nav_manager
var environment_setup
var dungeon_camera

var dungeon_data: Dictionary = {}
var is_initialized: bool = false

func _ready() -> void:
	graph_generator = RuinsGraphGeneratorScript.new()

	grid_builder = RuinsGridMapBuilderScript.new()
	add_child(grid_builder)

	prop_scatterer = RuinsPropScattererScript.new()
	add_child(prop_scatterer)

	nav_manager = RuinsNavigationManagerScript.new()
	add_child(nav_manager)

	environment_setup = RuinsEnvironmentScript.new()
	add_child(environment_setup)

	dungeon_camera = RuinsCameraScript.new()
	add_child(dungeon_camera)

	var time_mgr = get_node_or_null("/root/TimeManager")
	if is_instance_valid(time_mgr) and time_mgr.has_signal("loop_expired"):
		time_mgr.loop_expired.connect(_on_time_loop_expired)

	generate_dungeon(current_seed)

func generate_dungeon(seed_val: int) -> void:
	current_seed = seed_val
	dungeon_data = graph_generator.generate(seed_val, grid_width, grid_depth, 4, 8)

	var grid_map = grid_builder.build_grid_map(dungeon_data)
	prop_scatterer.scatter_props(dungeon_data, grid_map, seed_val)
	nav_manager.build_navigation_graph(dungeon_data)

	if dungeon_data.has("spawn_pos"):
		var sp: Vector3i = dungeon_data.spawn_pos
		var spawn_world := Vector3(sp.x + 0.5, 0.0, sp.z + 0.5)
		_spawn_3d_player(spawn_world)

	is_initialized = true

func _spawn_3d_player(spawn_world: Vector3) -> void:
	var p3d = get_node_or_null("Player3D")
	if not is_instance_valid(p3d):
		p3d = Node3D.new()
		p3d.name = "Player3D"

		var mesh_inst := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.3
		cm.bottom_radius = 0.3
		cm.height = 1.6
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#4CAF50") # Link tunic green
		cm.material = mat
		mesh_inst.mesh = cm
		mesh_inst.position = Vector3(0, 0.8, 0)
		p3d.add_child(mesh_inst)

		add_child(p3d)

	p3d.global_position = spawn_world
	if is_instance_valid(dungeon_camera):
		dungeon_camera.global_position = spawn_world + Vector3(0, 10, 8)
		dungeon_camera.look_at(spawn_world)
		dungeon_camera.make_current()
		dungeon_camera.set_target(p3d)

func reset_ruins_state(next_seed: int = -1) -> void:
	if next_seed < 0:
		next_seed = current_seed + 1
	generate_dungeon(next_seed)

func _on_time_loop_expired() -> void:
	reset_ruins_state()
