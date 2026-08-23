extends "res://addons/gut/test.gd"

var GraphGenerator = load("res://scripts/procgen/ruins/RuinsGraphGenerator.gd")
var Catalog = load("res://scripts/procgen/ruins/RuinsTileCatalog.gd")
var GridMapBuilder = load("res://scripts/procgen/ruins/RuinsGridMapBuilder.gd")
var NavigationManager = load("res://scripts/procgen/ruins/RuinsNavigationManager.gd")
var RuinsDungeon = load("res://scenes/procgen/RuinsDungeon.gd")

var generator

func before_each():
	generator = GraphGenerator.new()

func test_100_seeds_connectivity() -> void:
	for seed_val in range(100):
		var dungeon_data: Dictionary = generator.generate(seed_val, 32, 32, 4, 8)
		assert_true(dungeon_data.has("spawn_pos"), "Dungeon must have a valid spawn position")
		assert_true(dungeon_data.has("exit_pos"), "Dungeon must have a valid exit position")

		var is_solvable: bool = generator.verify_reachability(
			dungeon_data.walkable_tiles,
			dungeon_data.spawn_pos,
			dungeon_data.exit_pos
		)
		assert_true(is_solvable, "Seed %d failed reachability check from spawn to exit" % seed_val)

func test_seed_determinism() -> void:
	var seed_val := 12345
	var dungeon_a: Dictionary = generator.generate(seed_val, 32, 32, 5, 8)
	var dungeon_b: Dictionary = generator.generate(seed_val, 32, 32, 5, 8)

	assert_eq(dungeon_a.spawn_pos, dungeon_b.spawn_pos, "Spawn positions must match for identical seed")
	assert_eq(dungeon_a.exit_pos, dungeon_b.exit_pos, "Exit positions must match for identical seed")
	assert_eq(dungeon_a.walkable_tiles.size(), dungeon_b.walkable_tiles.size(), "Walkable tile count must match for identical seed")

func test_tile_catalog_quaternius_rotations() -> void:
	# Straight Wall N (0 deg)
	var res_n = Catalog.resolve_wall_placement(Catalog.N)
	assert_eq(res_n.item, Catalog.TILE_WALL_STRAIGHT)
	assert_eq(res_n.orientation, 0)

	# Straight Wall E (90 deg -> 22)
	var res_e = Catalog.resolve_wall_placement(Catalog.E)
	assert_eq(res_e.item, Catalog.TILE_WALL_STRAIGHT)
	assert_eq(res_e.orientation, 22)

	# Corner In N|E
	var res_ne = Catalog.resolve_wall_placement(Catalog.N | Catalog.E)
	assert_eq(res_ne.item, Catalog.TILE_WALL_CORNER_IN)
	assert_eq(res_ne.orientation, 0)

	# Corner In E|S
	var res_es = Catalog.resolve_wall_placement(Catalog.E | Catalog.S)
	assert_eq(res_es.item, Catalog.TILE_WALL_CORNER_IN)
	assert_eq(res_es.orientation, 22)

func test_grid_map_builder_population() -> void:
	var builder = GridMapBuilder.new()
	add_child_autoqfree(builder)

	var dungeon_data: Dictionary = generator.generate(42, 32, 32, 4, 6)
	var grid_map: GridMap = builder.build_grid_map(dungeon_data)

	assert_not_null(grid_map, "GridMap instance should be created")
	assert_not_null(grid_map.mesh_library, "GridMap should have a non-null MeshLibrary assigned")

	var spawn_cell = dungeon_data.spawn_pos
	var spawn_item = grid_map.get_cell_item(spawn_cell)
	assert_eq(spawn_item, Catalog.TILE_FLOOR, "Spawn cell must contain a floor tile item")

func test_navigation_pathfinding() -> void:
	var nav_mgr = NavigationManager.new()
	add_child_autoqfree(nav_mgr)

	var dungeon_data: Dictionary = generator.generate(99, 32, 32, 4, 6)
	nav_mgr.build_navigation_graph(dungeon_data)

	var spawn_pos: Vector3i = dungeon_data.spawn_pos
	var exit_pos: Vector3i = dungeon_data.exit_pos

	var start_world := Vector3(spawn_pos.x + 0.5, 0.0, spawn_pos.z + 0.5)
	var target_world := Vector3(exit_pos.x + 0.5, 0.0, exit_pos.z + 0.5)

	var path: PackedVector3Array = nav_mgr.find_path(start_world, target_world)
	assert_true(path.size() > 0, "Navigation manager should find valid path from spawn to exit")

func test_ruins_dungeon_time_loop_reset() -> void:
	var dungeon = RuinsDungeon.new()
	add_child_autoqfree(dungeon)

	assert_true(dungeon.is_initialized, "Dungeon should be initialized on ready")
	var initial_seed = dungeon.current_seed

	dungeon.reset_ruins_state(888)
	assert_eq(dungeon.current_seed, 888, "Dungeon current seed should update after reset")
