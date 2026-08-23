extends "res://addons/gut/test.gd"

var main_scene

func before_each():
    main_scene = load("res://Main.gd").new()
    main_scene._ready()

func after_each():
    if is_instance_valid(main_scene):
        main_scene.free()

func test_map_toggle():
    assert_not_null(main_scene.map_overlay, "Map overlay should be created")
    assert_false(main_scene.map_overlay.visible, "Map overlay should initially be hidden")

    main_scene.toggle_map()
    assert_true(main_scene.map_overlay.visible, "Map overlay should be visible after toggle")

    main_scene.toggle_map()
    assert_false(main_scene.map_overlay.visible, "Map overlay should be hidden after second toggle")

func test_room_boundary_changed_updates_hud():
    assert_not_null(main_scene.room_label, "Room label should exist")
    main_scene._on_room_changed(Vector2(0, 0))
    assert_true(main_scene.room_label.text.begins_with("BIOME: "), "Room label should reflect biome name")
