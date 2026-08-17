extends "res://addons/gut/test.gd"

var visual_juice = null
var time_mgr = null

func before_each():
    # Only load the node for isolated unit testing
    visual_juice = load("res://VisualJuiceManager.gd").new()
    add_child_autoqfree(visual_juice)

    time_mgr = load("res://TimeManager.gd").new()
    add_child_autoqfree(time_mgr)

    await get_tree().process_frame

func test_particles_spawn():
    visual_juice.spawn_particles(Vector2(100, 100))
    var active_count = 0
    for p in visual_juice.particle_pool:
        if p.emitting:
            active_count += 1
    assert_eq(active_count, 1, "Should have 1 active particle emitter")

func test_screen_shake():
    visual_juice.apply_shake(20.0)
    assert_eq(visual_juice.shake_strength, 20.0, "Shake strength should be set")
    visual_juice._process(0.1)
    assert_lt(visual_juice.shake_strength, 20.0, "Shake should decay")

func test_vignette_low_time():
    visual_juice._on_time_ticked(15.0)
    assert_eq(visual_juice.vignette.color.a, 0.0, "Vignette should be invisible at 15s")

    visual_juice._on_time_ticked(7.5)
    assert_gt(visual_juice.vignette.color.a, 0.0, "Vignette should be partially visible at 7.5s")
    assert_lt(visual_juice.vignette.color.a, 0.5, "Vignette should be partially visible at 7.5s")

    visual_juice._on_time_ticked(16.0)
    assert_eq(visual_juice.vignette.color.a, 0.0, "Vignette should be invisible above 15s")
