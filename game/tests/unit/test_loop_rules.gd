extends GutTest

var time_mgr: Node = null

func before_each() -> void:
	time_mgr = preload("res://scripts/core/TimeManager.gd").new()
	add_child_autofree(time_mgr)

func test_initial_max_time_is_100_seconds() -> void:
	assert_eq(time_mgr.MAX_TIME, 100.0, "Loop timer must be 100 seconds per GDD section 1")
	assert_eq(time_mgr.WARNING_TIME, 15.0, "Warning vignette trigger must be at 15 seconds")

func test_start_loop_initializes_countdown() -> void:
	time_mgr.start_loop()
	assert_true(time_mgr.is_loop_running(), "Loop should be running after start_loop")
	assert_eq(time_mgr.get_remaining_time(), 100.0, "Remaining time should start at 100s")

func test_timer_deduction_for_fast_travel() -> void:
	time_mgr.start_loop()
	time_mgr.deduct_time(10.0)
	assert_almost_eq(time_mgr.get_remaining_time(), 90.0, 0.1, "Fast travel must deduct 10s of loop time")

func test_warning_signal_emitted_at_15_seconds() -> void:
	watch_signals(time_mgr)
	time_mgr.start_loop()
	time_mgr.deduct_time(86.0) # Brings remaining to 14.0s
	assert_signal_emitted(time_mgr, "time_warning_entered", "Warning signal must emit when <= 15s")

func test_loop_expiration_triggers_at_zero() -> void:
	watch_signals(time_mgr)
	time_mgr.start_loop()
	time_mgr.deduct_time(100.0)
	assert_signal_emitted(time_mgr, "loop_expired", "loop_expired signal must emit when timer reaches 0")
	assert_false(time_mgr.is_loop_running(), "Loop must stop running upon expiration")
