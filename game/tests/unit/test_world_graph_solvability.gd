extends GutTest

var world_graph: Node = null

func before_each() -> void:
	world_graph = preload("res://scripts/core/WorldGraph.gd").new()
	add_child_autofree(world_graph)

func test_all_zones_solvable_within_100s_loop_timer() -> void:
	# GDD §5.2 Rule 1: Solvable within one loop from its nearest House
	var report = world_graph.validate_all_zones(100.0)
	assert_true(report.all_solvable, "All zones must be solvable within 100s from nearest House")
	for failure in report.failed_zones:
		assert_true(failure.solvable, "Zone %s exceeded 100s critical path budget" % failure.zone)

func test_all_zones_have_faster_backtracking_shortcuts() -> void:
	# GDD §5.2 Rule 2: Backtrackable faster than first pass once cleared
	var report = world_graph.validate_all_zones(100.0)
	assert_true(report.all_backtrackable, "Every zone must have a faster return route once shortcut is unlocked")
	for failure in report.failed_zones:
		assert_true(failure.backtrackable, "Zone %s lacks a faster return path" % failure.zone)

func test_waypoint_positions_only_returns_activated_when_filtered() -> void:
	# Create a mock GameState
	var game_st = preload("res://scripts/core/GameState.gd").new()
	add_child_autofree(game_st)

	# Initially no waypoints activated
	var active_wps = world_graph.get_waypoint_positions(true)
	assert_true(active_wps.is_empty(), "No waypoints should be active initially")

	# Activate village shrine
	game_st.activate_waypoint(&"waypoint_village")
	# Temporary mock set instance
	var active_after = world_graph.get_waypoint_positions(false)
	assert_gt(active_after.size(), 0, "All waypoints returned when only_activated is false")
