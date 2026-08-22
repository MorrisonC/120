extends GutTest

var TouchControlsScript = load("res://TouchControls.gd")
var PlayerControllerScript = load("res://PlayerController.gd")

func test_touch_controls_initialization():
    var touch_controls = TouchControlsScript.new()
    add_child_autofree(touch_controls)

    assert_not_null(touch_controls, "TouchControls instance should be valid.")
    assert_eq(touch_controls.max_joystick_radius, 32.0, "Default max radius should be 32.")
    assert_eq(touch_controls.deadzone, 0.15, "Default deadzone should be 0.15.")
    assert_false(touch_controls.joystick_active, "Joystick should start inactive.")
    assert_false(touch_controls.is_attack_pressed(), "Attack button should start unpressed.")

func test_virtual_joystick_drag_and_vector_calculation():
    var touch_controls = TouchControlsScript.new()
    add_child_autofree(touch_controls)

    # Touch down in left zone (Joystick area)
    var touch_down = InputEventScreenTouch.new()
    touch_down.index = 0
    touch_down.pressed = true
    touch_down.position = Vector2(40, 100)
    touch_controls._process_touch_event(touch_down)

    assert_true(touch_controls.joystick_active, "Joystick should activate on left screen touch.")

    # Drag joystick full right (+32px on X axis)
    var touch_drag = InputEventScreenDrag.new()
    touch_drag.index = 0
    touch_drag.position = Vector2(72, 100)
    touch_controls._process_touch_event(touch_drag)

    var vector = touch_controls.get_joystick_vector()
    assert_almost_eq(vector.x, 1.0, 0.05, "Joystick vector X should be ~1.0 when dragged full right.")
    assert_almost_eq(vector.y, 0.0, 0.05, "Joystick vector Y should be ~0.0.")

    # Touch up
    var touch_up = InputEventScreenTouch.new()
    touch_up.index = 0
    touch_up.pressed = false
    touch_up.position = Vector2(72, 100)
    touch_controls._process_touch_event(touch_up)

    assert_false(touch_controls.joystick_active, "Joystick should deactivate on touch release.")
    assert_eq(touch_controls.get_joystick_vector(), Vector2.ZERO, "Joystick vector should reset to ZERO.")

func test_joystick_deadzone():
    var touch_controls = TouchControlsScript.new()
    add_child_autofree(touch_controls)

    # Touch down
    var touch_down = InputEventScreenTouch.new()
    touch_down.index = 0
    touch_down.pressed = true
    touch_down.position = Vector2(40, 100)
    touch_controls._process_touch_event(touch_down)

    # Tiny drag (2px, inside 15% deadzone of 32px)
    var touch_drag = InputEventScreenDrag.new()
    touch_drag.index = 0
    touch_drag.position = Vector2(42, 100)
    touch_controls._process_touch_event(touch_drag)

    assert_eq(touch_controls.get_joystick_vector(), Vector2.ZERO, "Vector should remain ZERO within deadzone.")

func test_attack_button_touch_event():
    var touch_controls = TouchControlsScript.new()
    add_child_autofree(touch_controls)

    watch_signals(touch_controls)

    # Touch down on Attack button (default position 280, 140)
    var touch_down = InputEventScreenTouch.new()
    touch_down.index = 1
    touch_down.pressed = true
    touch_down.position = Vector2(280, 140)
    touch_controls._process_touch_event(touch_down)

    assert_true(touch_controls.is_attack_pressed(), "Attack button state should be pressed.")
    assert_signal_emitted(touch_controls, "attack_pressed")

    # Touch up on Attack button
    var touch_up = InputEventScreenTouch.new()
    touch_up.index = 1
    touch_up.pressed = false
    touch_up.position = Vector2(280, 140)
    touch_controls._process_touch_event(touch_up)

    assert_false(touch_controls.is_attack_pressed(), "Attack button state should be unpressed.")
    assert_signal_emitted(touch_controls, "attack_released")

func test_multi_touch_concurrency():
    var touch_controls = TouchControlsScript.new()
    add_child_autofree(touch_controls)

    # Touch 0: Joystick on left
    var touch_0 = InputEventScreenTouch.new()
    touch_0.index = 0
    touch_0.pressed = true
    touch_0.position = Vector2(50, 100)
    touch_controls._process_touch_event(touch_0)

    # Touch 1: Attack button on right
    var touch_1 = InputEventScreenTouch.new()
    touch_1.index = 1
    touch_1.pressed = true
    touch_1.position = Vector2(280, 140)
    touch_controls._process_touch_event(touch_1)

    assert_true(touch_controls.joystick_active, "Joystick should be active on touch index 0.")
    assert_true(touch_controls.is_attack_pressed(), "Attack button should be active on touch index 1 concurrently.")

func test_player_controller_touch_input_movement():
    var player = PlayerControllerScript.new()
    add_child_autofree(player)

    player.touch_input_vector = Vector2(0, -1) # Upward touch input
    player._handle_input(0.01)

    assert_eq(player.input_vector, Vector2(0, -1), "Player input vector should match touch input vector.")
    assert_eq(player.facing_direction, Vector2.UP, "Player facing direction should snap to UP.")
