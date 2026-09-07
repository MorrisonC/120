@tool
extends McpTestSuite

func suite_name() -> String:
	return "collision_scene_health"

func test_breakable_prop_has_collision_layer() -> void:
	var prop = preload("res://scripts/world/BreakableProp3D.gd").new()
	prop._ready()
	assert_eq(prop.collision_layer, 4, "Breakable props must be on layer 4 for combat hit detection")
	prop.free()

func test_treasure_chest_has_interaction_layer() -> void:
	var chest = preload("res://scripts/world/TreasureChest3D.gd").new()
	chest._ready()
	assert_eq(chest.collision_layer, 16, "Treasure chest must be on layer 16 for player interaction detection")
	chest.free()

func test_push_block_collision_layer_and_mask() -> void:
	var block = preload("res://scripts/puzzles/PushBlock3D.gd").new()
	block._ready()
	assert_eq(block.collision_layer, 4, "Push block must be on layer 4")
	assert_eq(block.collision_mask, 1, "Push block must collide with world environment")
	block.free()

func test_pressure_plate_mask_detects_player_and_puzzle_blocks() -> void:
	var plate = preload("res://scripts/puzzles/PressurePlate3D.gd").new()
	plate._ready()
	assert_true((plate.collision_mask & 2) != 0, "Pressure plate must detect player (layer 2)")
	assert_true((plate.collision_mask & 4) != 0, "Pressure plate must detect puzzle blocks (layer 4)")
	plate.free()

func test_player_scene_3d_structure() -> void:
	var player_scene = load("res://scenes/player/Player.tscn")
	assert_true(player_scene != null, "Player.tscn scene must exist and load")
	var player_inst = player_scene.instantiate()
	assert_true(player_inst is CharacterBody3D, "Player scene root must be CharacterBody3D")
	var col_shape = player_inst.get_node_or_null("CollisionShape3D")
	assert_true(col_shape != null, "Player must have CollisionShape3D")
	assert_true(col_shape.shape != null, "Player CollisionShape3D must have a valid shape resource")
	player_inst.free()

func test_tier1_enemy_3d_structure() -> void:
	var enemy_scene = load("res://scenes/enemies/Tier1Enemy.tscn")
	assert_true(enemy_scene != null, "Tier1Enemy.tscn scene must exist and load")
	var enemy_inst = enemy_scene.instantiate()
	assert_true(enemy_inst is CharacterBody3D, "Tier1Enemy scene root must be CharacterBody3D")
	var col_shape = enemy_inst.get_node_or_null("CollisionShape3D")
	assert_true(col_shape != null, "Tier1Enemy must have CollisionShape3D")
	assert_true(col_shape.shape != null, "Tier1Enemy CollisionShape3D must have a valid shape resource")
	enemy_inst.free()
