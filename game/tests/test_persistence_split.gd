@tool
extends McpTestSuite

func suite_name() -> String:
	return "persistence_split"

func test_initial_health_and_capabilities() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	assert_eq(gs.run_state.max_health, 3, "Starting health pool must be 3 hearts")
	assert_eq(gs.loop_state.current_health, 3, "Initial loop health must match max health")
	assert_false(gs.capabilities.has_sword, "Sword not unlocked initially")
	assert_false(gs.capabilities.can_push, "Push not unlocked initially")
	gs.free()

func test_item_pickup_persists_and_updates_capabilities() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs.add_item("Sword")
	gs.add_item("Coffee")
	assert_true(gs.has_item("Sword"), "Sword must be registered in run_state")
	assert_true(gs.capabilities.has_sword, "has_sword capability must be active")
	assert_true(gs.capabilities.can_push, "can_push capability must be active with Coffee")
	gs.free()

func test_heart_container_pickup_increases_max_health() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs.add_item("HeartContainer")
	assert_eq(gs.run_state.max_health, 4, "Heart container must increase max health to 4")
	assert_eq(gs.loop_state.current_health, 4, "Current health should reflect upgrade")
	gs.free()

func test_bookmark_and_waypoint_activation_persist_across_loop_resets() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	# Set bookmark, activate waypoint, unlock shortcut, get boots
	gs.set_bookmark("house_ruins_1", Vector3(100.0, 1.0, 0.0))
	gs.activate_waypoint(&"waypoint_ruins")
	gs.open_shortcut("gate_ruins_shortcut")
	gs.add_item("Boots")

	# Modify temporary per-loop state
	gs.loop_state.pushed_blocks["b1"] = Vector3(12.0, 0.0, 4.0)
	gs.loop_state.temp_switches["sw1"] = true
	gs.take_damage(2)
	assert_eq(gs.loop_state.current_health, 1, "Health dropped after damage")

	# Respawn / Loop reset
	gs.reset_loop_state()

	# Assert permanent state persisted
	assert_eq(gs.run_state.bookmarked_house_id, "house_ruins_1", "Bookmark house must persist across death")
	assert_eq(gs.run_state.bookmarked_position, Vector3(100.0, 1.0, 0.0), "Bookmark pos must persist")
	assert_true(gs.is_waypoint_activated(&"waypoint_ruins"), "Waypoint activation must survive loop death")
	assert_true(gs.is_shortcut_open("gate_ruins_shortcut"), "Opened shortcut gate must survive loop death")
	assert_true(gs.has_item("Boots"), "Permanent items must survive loop death")

	# Assert temporary state reset
	assert_eq(gs.loop_state.current_health, gs.run_state.max_health, "Health must reset to full on respawn")
	assert_true(gs.loop_state.pushed_blocks.is_empty(), "Temporary pushed block state must be wiped on respawn")
	assert_true(gs.loop_state.temp_switches.is_empty(), "Temporary switches must be wiped on respawn")
	gs.free()
