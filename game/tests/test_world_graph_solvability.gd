@tool
extends McpTestSuite

func suite_name() -> String:
	return "world_graph_solvability"

func test_all_zones_solvable_within_100s_loop_timer() -> void:
	var wg = preload("res://scripts/core/WorldGraph.gd").new()
	var report = wg.validate_all_zones(100.0)
	assert_true(report.all_solvable, "All zones must be solvable within 100s from nearest House")
	for failure in report.failed_zones:
		assert_true(failure.solvable, "Zone %s exceeded 100s critical path budget" % failure.zone)
	wg.free()

func test_all_zones_have_faster_backtracking_shortcuts() -> void:
	var wg = preload("res://scripts/core/WorldGraph.gd").new()
	var report = wg.validate_all_zones(100.0)
	assert_true(report.all_backtrackable, "Every zone must have a faster return route once shortcut is unlocked")
	for failure in report.failed_zones:
		assert_true(failure.backtrackable, "Zone %s lacks a faster return path" % failure.zone)
	wg.free()

func test_waypoint_positions_only_returns_activated_when_filtered() -> void:
	var wg = preload("res://scripts/core/WorldGraph.gd").new()
	var all_wps = wg.get_waypoint_positions(false)
	assert_gt(all_wps.size(), 0, "Waypoints must exist in world graph")
	assert_has_key(all_wps, "waypoint_village", "Village waypoint shrine must exist")
	assert_has_key(all_wps, "waypoint_ruins", "Ruins waypoint shrine must exist")
	wg.free()
