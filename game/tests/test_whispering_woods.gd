@tool
extends McpTestSuite

func suite_name() -> String:
	return "whispering_woods"

func test_woods_house_and_waypoint_positions_match_world_graph() -> void:
	var scene = preload("res://scenes/zones/WhisperingWoods.tscn").instantiate()
	var house = scene.find_child("HouseWoods", true, false)
	assert_true(house != null, "HouseWoods must exist in WhisperingWoods")
	if house:
		assert_eq(house.position, Vector3(0, 1, 100), "House must be at (0, 1, 100) matching WorldGraph")
	
	var waypoint = scene.find_child("WaypointWoods", true, false)
	assert_true(waypoint != null, "WaypointWoods must exist in WhisperingWoods")
	if waypoint:
		assert_eq(waypoint.position, Vector3(10, 1, 115), "Waypoint must be at (10, 1, 115) matching WorldGraph")
	scene.free()

func test_entrance_gate_requires_sword_and_persists() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs._ready()
	
	var gate = preload("res://scripts/world/BreakableProp3D.gd").new()
	gate.custom_game_state = gs
	gate.required_item = "Sword"
	gate.shortcut_id = "gate_woods_shortcut"
	gate.health = 1
	gate._ready()
	
	# Try hit without sword
	gate.take_hit(1, Vector3.ZERO)
	assert_false(gate.is_broken, "Gate must not break without Sword equipped")
	assert_false(gs.is_shortcut_open("gate_woods_shortcut"), "Shortcut must not be open yet")
	
	# Give sword and hit again
	gs.add_item("Sword")
	gate.take_hit(1, Vector3.ZERO)
	assert_true(gate.is_broken, "Gate must break when hit with Sword")
	assert_true(gs.is_shortcut_open("gate_woods_shortcut"), "Shortcut must be permanently open in GameState")
	
	gate.free()
	gs.free()

func test_hunter_npc_quest_progression() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs._ready()
	assert_eq(gs.get_quest_stage("hunter_wolves"), 0, "Default quest stage must be 0")
	
	var npc = preload("res://scripts/world/NPC.gd").new()
	npc.quest_id = "hunter_wolves"
	npc.dialogue_by_stage = ["Stage 0: Den active", "Stage 1: Den cleared"]
	npc._ready()
	
	gs.advance_quest("hunter_wolves", 1)
	assert_eq(gs.get_quest_stage("hunter_wolves"), 1, "Quest stage must advance to 1")
	
	npc.free()
	gs.free()

func test_push_block_requires_coffee() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs._ready()
	var player = preload("res://scripts/player/PlayerController3D.gd").new()
	player.custom_game_state = gs
	assert_false(player.can_push_block(), "Cannot push block without coffee")
	gs.add_item("Coffee")
	assert_true(player.can_push_block(), "Can push block after acquiring coffee")
	player.free()
	gs.free()
