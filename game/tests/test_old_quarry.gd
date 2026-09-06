@tool
extends McpTestSuite

func suite_name() -> String:
	return "old_quarry"

func test_quarry_house_and_waypoint_positions_match_world_graph() -> void:
	var scene = preload("res://scenes/zones/OldQuarry.tscn").instantiate()
	var house = scene.find_child("HouseQuarry", true, false)
	assert_true(house != null, "HouseQuarry must exist in OldQuarry")
	if house:
		assert_eq(house.position, Vector3(0, 1, -100), "House must be at (0, 1, -100) matching WorldGraph")
	
	var waypoint = scene.find_child("WaypointQuarry", true, false)
	assert_true(waypoint != null, "WaypointQuarry must exist in OldQuarry")
	if waypoint:
		assert_eq(waypoint.position, Vector3(15, 1, -90), "Waypoint must be at (15, 1, -90) matching WorldGraph")
	scene.free()

func test_grapple_pickup_grants_climb_capability() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs._ready()
	assert_false(gs.capabilities.can_climb, "Player should not have climb capability initially")
	
	gs.add_item("Grapple")
	assert_true(gs.capabilities.can_climb, "Collecting Grapple must set can_climb = true")
	gs.free()

func test_quarry_boss_boulder_redirect_damage() -> void:
	var boss = preload("res://scripts/combat/QuarryBoss.gd").new()
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs._ready()
	boss.custom_game_state = gs
	boss._ready()
	
	var initial_hp = boss.current_health
	
	# Normal hit deflected by armor
	boss.take_damage(1)
	assert_eq(boss.current_health, initial_hp, "Boss should deflect normal attacks while armored")
	
	# Boulder without grapple redirect does not damage boss
	var hit_normal = boss.hit_by_boulder(false)
	assert_false(hit_normal, "Non-redirected boulder should be deflected")
	assert_eq(boss.current_health, initial_hp, "Boss should not take damage from non-redirected boulder")
	
	# Grapple redirected boulder damages boss
	var hit_redirected = boss.hit_by_boulder(true)
	assert_true(hit_redirected, "Grapple redirected boulder must hit boss")
	assert_eq(boss.current_health, initial_hp - 2, "Boss must lose 2 HP from redirected boulder")
	
	boss.free()
	gs.free()
