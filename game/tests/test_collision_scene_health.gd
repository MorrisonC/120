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
