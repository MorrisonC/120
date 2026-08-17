extends "res://addons/gut/test.gd"

var RoomCamera2D = load("res://RoomCamera2D.gd")

func test_camera_room_transition():
    var parent = Node2D.new()
    add_child_autoqfree(parent)

    var camera = RoomCamera2D.new()
    camera.room_size = Vector2(320, 180)
    camera.smooth_transition = false
    parent.add_child(camera)
    await get_tree().process_frame

    # Simulate first frame processing
    camera._process(0.1)

    assert_eq(camera.current_room, Vector2(0, 0), "Initial room should be 0,0")
    assert_eq(camera.global_position, Vector2(160, 90), "Camera should center on room 0,0")

    # Move parent to next room
    parent.global_position = Vector2(330, 100)
    camera._process(0.1)

    assert_eq(camera.current_room, Vector2(1, 0), "Room should update to 1,0")
    assert_eq(camera.global_position, Vector2(480, 90), "Camera should center on room 1,0")

    # Move parent to another room (down and left)
    parent.global_position = Vector2(-50, 200)
    camera._process(0.1)

    assert_eq(camera.current_room, Vector2(-1, 1), "Room should update to -1,1")
    assert_eq(camera.global_position, Vector2(-160, 270), "Camera should center on room -1,1")
