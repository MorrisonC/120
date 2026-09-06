@tool
extends McpTestSuite

func suite_name() -> String:
	return "frostpeak"

func test_frostpeak_house_and_waypoint_positions_match_world_graph() -> void:
	var scene = preload("res://scenes/zones/Frostpeak.tscn").instantiate()
	var house = scene.find_child("HouseFrost", true, false)
	assert_true(house != null, "HouseFrost must exist in Frostpeak")
	if house:
		assert_eq(house.position, Vector3(80, 10, -80), "House must be at (80, 10, -80) matching WorldGraph")
	
	var waypoint = scene.find_child("WaypointFrost", true, false)
	assert_true(waypoint != null, "WaypointFrost must exist in Frostpeak")
	if waypoint:
		assert_eq(waypoint.position, Vector3(90, 10, -70), "Waypoint must be at (90, 10, -70) matching WorldGraph")
	scene.free()

func test_frost_hazard_damage_requires_warmth_capability() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs._ready()
	
	var frost = preload("res://scripts/world/FrostHazard.gd").new()
	frost.custom_game_state = gs
	frost.damage_interval = 1.0
	frost.damage_amount = 1
	
	var player = preload("res://scripts/player/PlayerController3D.gd").new()
	player.custom_game_state = gs
	
	assert_eq(gs.loop_state.current_health, 3, "Initial health should be 3")
	
	# Cold deals damage without WarmCloak
	var damaged = frost.process_frost_damage(player, 1.5)
	assert_true(damaged, "Blizzard should deal damage when has_warmth is false")
	assert_eq(gs.loop_state.current_health, 2, "Health should decrease by 1 from frost")
	
	# Give WarmCloak -> has_warmth
	gs.add_item("WarmCloak")
	assert_true(gs.capabilities.has_warmth, "Player must have has_warmth capability with WarmCloak")
	
	var damaged_with_cloak = frost.process_frost_damage(player, 1.5)
	assert_false(damaged_with_cloak, "Blizzard should not deal damage when has_warmth is true")
	assert_eq(gs.loop_state.current_health, 2, "Health should remain unchanged with WarmCloak")
	
	player.free()
	frost.free()
	gs.free()
