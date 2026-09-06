@tool
extends McpTestSuite

func suite_name() -> String:
	return "sunken_marsh"

func test_marsh_house_and_waypoint_positions_match_world_graph() -> void:
	var scene = preload("res://scenes/zones/SunkenMarsh.tscn").instantiate()
	var house = scene.find_child("HouseMarsh", true, false)
	assert_true(house != null, "HouseMarsh must exist in SunkenMarsh")
	if house:
		assert_eq(house.position, Vector3(-100, 1, 0), "House must be at (-100, 1, 0) matching WorldGraph")
	
	var waypoint = scene.find_child("WaypointMarsh", true, false)
	assert_true(waypoint != null, "WaypointMarsh must exist in SunkenMarsh")
	if waypoint:
		assert_eq(waypoint.position, Vector3(-95, 1, 10), "Waypoint must be at (-95, 1, 10) matching WorldGraph")
	scene.free()

func test_water_plane_damage_requires_swim_capability() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs._ready()
	
	var water = preload("res://scripts/world/WaterPlane.gd").new()
	water.custom_game_state = gs
	water.damage_interval = 1.0
	water.damage_amount = 1
	
	var player = preload("res://scripts/player/PlayerController3D.gd").new()
	player.custom_game_state = gs
	
	# Initial health is 3
	assert_eq(gs.loop_state.current_health, 3, "Initial health should be 3")
	
	# Can't swim -> water damage is dealt
	var damaged = water.process_water_damage(player, 1.5)
	assert_true(damaged, "Water should deal damage when can_swim is false")
	assert_eq(gs.loop_state.current_health, 2, "Health should decrease by 1")
	
	# Give Fins -> can swim
	gs.add_item("Fins")
	assert_true(gs.capabilities.can_swim, "Player must have can_swim capability with Fins")
	
	var damaged_with_fins = water.process_water_damage(player, 1.5)
	assert_false(damaged_with_fins, "Water should not deal damage when can_swim is true")
	assert_eq(gs.loop_state.current_health, 2, "Health should remain unchanged with Fins")
	
	player.free()
	water.free()
	gs.free()

func test_marsh_boss_submerge_resurface_vulnerability() -> void:
	var boss = preload("res://scripts/combat/MarshBoss.gd").new()
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs._ready()
	boss.custom_game_state = gs
	boss._ready()
	
	assert_true(boss.is_surfaced(), "Boss should start surfaced")
	assert_true(boss.is_vulnerable, "Boss should be vulnerable while surfaced")
	
	# Submerge boss
	boss.submerge()
	assert_false(boss.is_surfaced(), "Boss should be submerged")
	assert_false(boss.is_vulnerable, "Boss should not be vulnerable while submerged")
	
	var hp_before = boss.current_health
	boss.take_damage(2)
	assert_eq(boss.current_health, hp_before, "Boss must not take damage while submerged")
	
	# Resurface boss
	boss.resurface()
	assert_true(boss.is_surfaced(), "Boss should be surfaced")
	assert_true(boss.is_vulnerable, "Boss should be vulnerable after resurfacing")
	
	boss.take_damage(2)
	assert_eq(boss.current_health, hp_before - 2, "Boss must take damage when surfaced")
	
	boss.free()
	gs.free()
