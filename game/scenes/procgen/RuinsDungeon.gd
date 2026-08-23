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

	is_initialized = true

func reset_ruins_state(next_seed: int = -1) -> void:
	if next_seed < 0:
		next_seed = current_seed + 1
	generate_dungeon(next_seed)

func _on_time_loop_expired() -> void:
	reset_ruins_state()
