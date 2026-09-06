@tool
extends McpTestSuite

func suite_name() -> String:
	return "the_hollow"

func test_hollow_house_and_waypoint_positions_match_world_graph() -> void:
	var scene = preload("res://scenes/zones/TheHollow.tscn").instantiate()
	var house = scene.find_child("HouseHollow", true, false)
	assert_true(house != null, "HouseHollow must exist in TheHollow")
	if house:
		assert_eq(house.position, Vector3(0, -20, 0), "House must be at (0, -20, 0) matching WorldGraph")
	
	var waypoint = scene.find_child("WaypointHollow", true, false)
	assert_true(waypoint != null, "WaypointHollow must exist in TheHollow")
	if waypoint:
		assert_eq(waypoint.position, Vector3(5, -20, 10), "Waypoint must be at (5, -20, 10) matching WorldGraph")
	scene.free()

func test_descent_well_transitions_player_to_the_hollow() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs._ready()
	
	var transition = preload("res://scripts/world/ZoneTransitionArea3D.gd").new()
	transition.custom_game_state = gs
	transition.target_zone = "TheHollow"
	transition.target_position = Vector3(0, -20, 0)
	
	var player = preload("res://scripts/player/PlayerController3D.gd").new()
	player.custom_game_state = gs
	player.position = Vector3(0, 0, 15)
	
	assert_eq(gs.loop_state.current_zone, "OverworldVillage", "Current zone should start at OverworldVillage")
	
	transition.trigger_transition(player)
	
	assert_eq(gs.loop_state.current_zone, "TheHollow", "Current zone must be updated to TheHollow")
	assert_eq(player.position, Vector3(0, -20, 0), "Player position must be moved to (0, -20, 0)")
	
	player.free()
	transition.free()
	gs.free()

func test_master_key_gate_requires_all_five_items() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs._ready()
	
	var gate = preload("res://scripts/world/MasterKeyGate.gd").new()
	gate.custom_game_state = gs
	
	# Try with 0 items
	assert_false(gate.can_unlock(gs), "Gate must not open with 0 items")
	assert_false(gate.try_unlock(gs), "Gate try_unlock must fail")
	
	# Add 4 items (missing WarmCloak)
	gs.add_item("Sword")
	gs.add_item("Lantern")
	gs.add_item("Fins")
	gs.add_item("Grapple")
	assert_false(gate.can_unlock(gs), "Gate must not open with 4 items")
	
	# Add 5th item
	gs.add_item("WarmCloak")
	assert_true(gate.can_unlock(gs), "Gate must be unlockable with all 5 items")
	assert_true(gate.try_unlock(gs), "Gate try_unlock must succeed")
	assert_true(gate.is_open, "Gate should now be open")
	assert_true(gs.is_shortcut_open("shortcut_master_gate"), "Shortcut should be marked open in GameState")
	
	gate.free()
	gs.free()

func test_final_boss_multi_phase_mechanics() -> void:
	var FinalBossScript = preload("res://scripts/combat/FinalBoss.gd")
	var boss = FinalBossScript.new()
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs._ready()
	boss.custom_game_state = gs
	boss._ready()
	
	assert_eq(boss.current_boss_phase, FinalBossScript.FinalPhase.PHASE_TELEGRAPH, "Boss starts in telegraph phase")
	
	# Phase 1: takes normal damage down to 8 HP
	boss.take_damage(4)
	assert_eq(boss.current_health, 8, "Boss health should be 8")
	assert_eq(boss.current_boss_phase, FinalBossScript.FinalPhase.PHASE_SUBMERGE, "Boss transitions to submerge phase at 8 HP")
	
	# Phase 2: invulnerable in submerge
	var hp_in_submerge = boss.current_health
	boss.take_damage(2)
	assert_eq(boss.current_health, hp_in_submerge, "Boss must not take damage while submerged")
	
	# Switch to armored phase at low health
	boss.set_phase(FinalBossScript.FinalPhase.PHASE_ARMORED)
	assert_true(boss.is_armored_phase, "Boss is armored")
	boss.take_damage(2)
	assert_eq(boss.current_health, hp_in_submerge, "Armored phase deflects standard damage")
	
	# Break armor and defeat
	boss.break_armor()
	assert_false(boss.is_armored_phase, "Armor is broken")
	boss.take_damage(8)
	assert_eq(boss.current_health, 0, "Boss is defeated")
	
	boss.free()
	gs.free()
