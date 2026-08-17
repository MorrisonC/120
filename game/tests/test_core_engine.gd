extends "res://addons/gut/test.gd"

var TimeManager = null
var GameState = null

func before_each():
    TimeManager = load("res://TimeManager.gd").new()
    add_child_autoqfree(TimeManager)

    GameState = load("res://GameState.gd").new()
    add_child_autoqfree(GameState)
    await get_tree().process_frame

func test_time_manager_lifecycle():
    TimeManager.start_loop()
    assert_true(TimeManager.is_running, "Time manager should be running after start_loop")
    assert_eq(TimeManager.remaining_time, 120.0, "Time should reset to 120.0")

    TimeManager._physics_process(1.0)
    assert_lt(TimeManager.remaining_time, 120.0, "Time should decrease during _physics_process")

    TimeManager.pause_loop()
    assert_false(TimeManager.is_running, "Time manager should stop after pause_loop")

    var time_after_pause = TimeManager.remaining_time
    TimeManager._physics_process(1.0)
    assert_eq(TimeManager.remaining_time, time_after_pause, "Time should not decrease while paused")

    TimeManager.resume_loop()
    assert_true(TimeManager.is_running, "Time manager should run after resume_loop")
    TimeManager._physics_process(1.0)
    assert_lt(TimeManager.remaining_time, time_after_pause, "Time should resume decreasing")

func test_time_warning():
    TimeManager.start_loop()
    TimeManager.remaining_time = 15.1
    TimeManager._physics_process(0.2)
    assert_true(TimeManager._warning_emitted, "Warning flag should be set when time drops below 15")

func test_force_death():
    TimeManager.start_loop()
    TimeManager.force_death("Test death")
    assert_false(TimeManager.is_running, "Time manager should not run after force_death")
    assert_eq(TimeManager.remaining_time, 0.0, "Time manager should have 0 remaining_time after force_death")

func test_game_state_items():
    assert_eq(GameState.move_speed_modifier, 1.0, "Initial speed should be 1.0")

    GameState.add_key_item("Bicycle")
    assert_eq(GameState.move_speed_modifier, 1.75, "Speed modifier should be 1.75 with Bicycle")

    GameState.add_key_item("Flippers")
    assert_true(GameState.terrain_capabilities.can_swim, "Flippers should grant can_swim capability")

    GameState.add_key_item("Shovel")
    assert_true(GameState.terrain_capabilities.can_dig, "Shovel should grant can_dig capability")

func test_respawn_persists_run_state():
    GameState.add_key_item("Bicycle")
    GameState.set_active_spawn_point(Vector2(100, 100), "spawn_1")

    GameState.loop_state["pushed_blocks"] = {"block1": Vector2(10, 10)}

    GameState.respawn_player()

    assert_eq(GameState.move_speed_modifier, 1.75, "Run state items should persist after respawn")
    assert_eq(GameState.active_spawn_point, Vector2(100, 100), "Spawn point should persist after respawn")
    assert_eq(GameState.loop_state["pushed_blocks"].size(), 0, "Loop state should be wiped on respawn")
