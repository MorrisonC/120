extends GutTest

var time_manager = preload("res://TimeManager.gd")
var game_state = preload("res://GameState.gd")

var tm: Node
var gs: Node

func before_each():
    # Make sure we don't have autoload conflicts by managing them manually
    var root = get_tree().root

    # Ensure they exist as global Singletons first
    if not root.has_node("TimeManager"):
        var t = time_manager.new()
        t.name = "TimeManager"
        root.add_child(t)
    if not root.has_node("GameState"):
        var g = game_state.new()
        g.name = "GameState"
        root.add_child(g)

    tm = root.get_node("TimeManager")
    gs = root.get_node("GameState")

    # Reset states for each test
    tm.remaining_time = tm.MAX_TIME
    tm.is_running = false
    tm._warning_emitted = false

    gs.loop_state = {}
    gs.run_state = {
        "unlocked_key_items": [],
        "unlocked_shortcuts": [],
        "discovered_spawns": [],
        "cleared_puzzle_bitmask": 0
    }
    gs.active_spawn_point = Vector2.ZERO
    gs.update_capabilities_from_items()

func after_all():
    # Cleanup autoloads after all tests
    var root = get_tree().root
    if root.has_node("TimeManager"):
        var t = root.get_node("TimeManager")
        root.remove_child(t)
        t.queue_free()
    if root.has_node("GameState"):
        var g = root.get_node("GameState")
        root.remove_child(g)
        g.queue_free()

func test_time_manager_lifecycle():
    assert_false(tm.is_running, "Time manager should not run before start_loop")
    tm.start_loop()
    assert_true(tm.is_running, "Time manager should run after start_loop")
    assert_eq(tm.remaining_time, tm.MAX_TIME, "Time manager should start with MAX_TIME")

    tm._process(1.0)
    assert_eq(tm.remaining_time, tm.MAX_TIME - 1.0, "Time manager should decrease remaining_time in _process")

func test_time_warning():
    tm.start_loop()
    tm.remaining_time = tm.WARNING_TIME + 1.0
    tm._process(0.5)
    assert_false(tm._warning_emitted, "Warning should not be emitted before WARNING_TIME")

    tm._process(1.0)
    assert_true(tm._warning_emitted, "Warning should be emitted after remaining_time drops below WARNING_TIME")

func test_force_death():
    tm.start_loop()
    gs.loop_state["test"] = "test"
    tm.force_death("Test death")

    assert_false(tm.is_running, "Time manager should not run after force_death")
    assert_eq(tm.remaining_time, 0.0, "Time manager should have 0 remaining_time after force_death")

    assert_does_not_have(gs.loop_state, "test", "Loop state should be reset on respawn")

func test_game_state_items():
    assert_eq(gs.move_speed_modifier, 1.0, "Base move speed is 1.0")
    assert_false(gs.terrain_capabilities["can_swim"], "Base can_swim is false")

    gs.add_key_item("Bicycle")
    assert_eq(gs.move_speed_modifier, 1.75, "Bicycle gives 1.75 speed multiplier")

    gs.add_key_item("Flippers")
    assert_true(gs.terrain_capabilities["can_swim"], "Flippers give can_swim")

    gs.add_key_item("Shovel")
    assert_true(gs.terrain_capabilities["can_dig"], "Shovel gives can_dig")

    gs.add_key_item("Shears")
    assert_true(gs.terrain_capabilities["can_cut_vines"], "Shears gives can_cut_vines")

    gs.add_key_item("Lantern")
    assert_true(gs.terrain_capabilities["has_light"], "Lantern gives has_light")

func test_respawn_persists_run_state():
    gs.add_key_item("Bicycle")
    gs.set_active_spawn_point(Vector2(100, 100), "town_01")

    gs.loop_state["pushed_blocks"] = {"block_1": Vector2(10, 10)}
    gs.respawn_player()

    assert_eq(gs.move_speed_modifier, 1.75, "Run state items persist")
    assert_eq(gs.active_spawn_point, Vector2(100, 100), "Active spawn point persists")
    assert_has(gs.run_state["discovered_spawns"], "town_01", "Discovered spawns persist")
    assert_does_not_have(gs.loop_state["pushed_blocks"], "block_1", "Loop state resets")
