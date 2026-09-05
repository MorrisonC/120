@tool
extends McpTestSuite

func suite_name() -> String:
	return "loop_rules"

func test_initial_max_time_is_120_seconds() -> void:
	var tm = preload("res://scripts/core/TimeManager.gd").new()
	assert_eq(tm.MAX_TIME, 120.0, "Loop timer must be 120 seconds per Weird West GDD and HUD Mockup")
	assert_eq(tm.WARNING_TIME, 20.0, "Warning vignette trigger must be at 20 seconds")
	tm.free()

func test_start_loop_initializes_countdown() -> void:
	var tm = preload("res://scripts/core/TimeManager.gd").new()
	tm.start_loop()
	assert_true(tm.is_loop_running(), "Loop should be running after start_loop")
	assert_eq(tm.get_remaining_time(), 120.0, "Remaining time should start at 120s")
	tm.free()

func test_timer_deduction_for_fast_travel() -> void:
	var tm = preload("res://scripts/core/TimeManager.gd").new()
	tm.start_loop()
	tm.deduct_time(10.0)
	assert_eq(tm.get_remaining_time(), 110.0, "Fast travel must deduct 10s of loop time")
	tm.free()

func test_warning_signal_at_20_seconds() -> void:
	var tm = preload("res://scripts/core/TimeManager.gd").new()
	var box := {"warning": false}
	tm.time_warning_entered.connect(func(): box.warning = true)
	tm.start_loop()
	tm.deduct_time(102.0) # Brings remaining to 18.0s (<= 20.0s)
	assert_true(box.warning, "Warning signal must emit when <= 20s")
	tm.free()

func test_loop_expiration_at_zero() -> void:
	var tm = preload("res://scripts/core/TimeManager.gd").new()
	var box := {"expired": false}
	tm.loop_expired.connect(func(): box.expired = true)
	tm.start_loop()
	tm.deduct_time(120.0)
	assert_true(box.expired, "loop_expired signal must emit when timer reaches 0")
	assert_false(tm.is_loop_running(), "Loop must stop running upon expiration")
	tm.free()
