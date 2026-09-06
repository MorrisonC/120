extends SceneTree

func _init() -> void:
	print("==================================================")
	print("     LOOPKEEPER 3D - GAUNTLET TEST RUNNER         ")
	print("==================================================")
	
	var runner = preload("res://addons/godot_ai/testing/test_runner.gd").new()
	var test_files = [
		"res://tests/test_loop_rules.gd",
		"res://tests/test_boss_encounter.gd",
		"res://tests/test_puzzles.gd",
		"res://tests/test_items_and_respawn.gd",
		"res://tests/test_collision_scene_health.gd",
		"res://tests/test_game_enhancements.gd",
		"res://tests/test_persistence_split.gd",
		"res://tests/test_world_graph_solvability.gd",
		"res://tests/test_whispering_woods.gd",
		"res://tests/test_sunken_marsh.gd",
		"res://tests/test_old_quarry.gd",
		"res://tests/test_frostpeak.gd",
		"res://tests/test_the_hollow.gd",
		"res://tests/test_touch_controls.gd"
	]
	
	var total_passed = 0
	var total_failed = 0
	var total_tests = 0
	var all_failures = []
	
	for path in test_files:
		if not ResourceLoader.exists(path):
			print("[WARN] Test file not found: ", path)
			continue
		runner.clear()
		var script = load(path)
		var suite = script.new()
		var s_name = suite.suite_name()
		print("\n--- Suite: ", s_name, " (", path.get_file(), ") ---")
		
		runner.run_suite(suite)
		var summary = runner.get_results(true)
		var res_list = summary.get("results", [])
		
		for r in res_list:
			total_tests += 1
			if r.get("passed", false):
				total_passed += 1
				print("  ✓ ", r.get("test"), " (", r.get("duration_ms", 0), "ms)")
			else:
				total_failed += 1
				var fail_msg = r.get("message", "Assertion failed")
				print("  ✗ ", r.get("test"), " FAILED: ", fail_msg)
				all_failures.append({"suite": s_name, "test": r.get("test"), "msg": fail_msg})
		
	print("\n==================================================")
	print("TEST RUN SUMMARY:")
	print("Total Suites Run: ", test_files.size())
	print("Total Tests:      ", total_tests)
	print("Passed:           ", total_passed, " (", int(float(total_passed) / max(1, total_tests) * 100), "%)")
	print("Failed:           ", total_failed)
	if all_failures.size() > 0:
		print("\nFAILURES:")
		for f in all_failures:
			print(" - [", f.suite, "] ", f.test, ": ", f.msg)
	print("==================================================")
	
	quit(1 if total_failed > 0 else 0)
