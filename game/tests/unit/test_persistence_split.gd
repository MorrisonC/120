extends GutTest

var game_st: Node = null

func before_each() -> void:
	game_st = preload("res://scripts/core/GameState.gd").new()
	add_child_autofree(game_st)

func test_initial_health_and_capabilities() -> void:
	assert_eq(game_st.run_state.max_health, 3, "Starting health pool must be 3 hearts")
	assert_eq(game_st.loop_state.current_health, 3, "Initial loop health must match max health")
	assert_false(game_st.capabilities.has_sword, "Sword not unlocked initially")
	assert_false(game_st.capabilities.can_push, "Push not unlocked initially")

func test_item_pickup_persists_and_updates_capabilities() -> void:
	game_st.add_item("Sword")
	game_st.add_item("Coffee")
	assert_true(game_st.has_item("Sword"), "Sword must be registered in run_state")
	assert_true(game_st.capabilities.has_sword, "has_sword capability must be active")
	assert_true(game_st.capabilities.can_push, "can_push capability must be active with Coffee")

func test_heart_container_pickup_increases_max_health() -> void:
	game_st.add_item("HeartContainer")
	assert_eq(game_st.run_state.max_health, 4, "Heart container must increase max health to 4")
	assert_eq(game_st.loop_state.current_health, 4, "Current health should reflect upgrade")

func test_bookmark_and_waypoint_activation_persist_across_loop_resets() -> void:
	# Set bookmark and activate waypoint
	game_st.set_bookmark("house_ruins_1", Vector3(100.0, 1.0, 0.0))
	game_st.activate_waypoint(&"waypoint_ruins")
	game_st.open_shortcut("gate_ruins_shortcut")
	game_st.add_item("Boots")

	# Modify temporary per-loop state
	game_st.loop_state.pushed_blocks["b1"] = Vector3(12.0, 0.0, 4.0)
	game_st.loop_state.temp_switches["sw1"] = true
	game_st.take_damage(2)
	assert_eq(game_st.loop_state.current_health, 1, "Health dropped after damage")

	# Respawn / Loop reset
	game_st.reset_loop_state()

	# Assert permanent state persisted
	assert_eq(game_st.run_state.bookmarked_house_id, "house_ruins_1", "Bookmark house must persist across death")
	assert_eq(game_st.run_state.bookmarked_position, Vector3(100.0, 1.0, 0.0), "Bookmark pos must persist")
	assert_true(game_st.is_waypoint_activated(&"waypoint_ruins"), "Waypoint activation must survive loop death")
	assert_true(game_st.is_shortcut_open("gate_ruins_shortcut"), "Opened shortcut gate must survive loop death")
	assert_true(game_st.has_item("Boots"), "Permanent items must survive loop death")

	# Assert temporary state reset
	assert_eq(game_st.loop_state.current_health, game_st.run_state.max_health, "Health must reset to full on respawn")
	assert_true(game_st.loop_state.pushed_blocks.is_empty(), "Temporary pushed block state must be wiped on respawn")
	assert_true(game_st.loop_state.temp_switches.is_empty(), "Temporary switches must be wiped on respawn")
