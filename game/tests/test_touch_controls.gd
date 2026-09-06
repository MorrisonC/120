@tool
extends McpTestSuite

func suite_name() -> String:
	return "touch_controls"

func test_touch_controls_initialization() -> void:
	var touch_script = load("res://scripts/ui/TouchControls.gd")
	assert_true(touch_script != null, "TouchControls.gd script must exist and load")

	var touch = touch_script.new()
	assert_eq(touch.joystick_vector, Vector2.ZERO, "Joystick vector should initialize to ZERO")
	assert_false(touch.joystick_active, "Joystick should not be active initially")
	touch.free()

func test_touch_joystick_vector_calculation() -> void:
	var touch_script = load("res://scripts/ui/TouchControls.gd")
	var touch = touch_script.new()
	touch._update_positions()

	# Simulate touch press near joystick center
	var press_event = InputEventScreenTouch.new()
	press_event.pressed = true
	press_event.index = 1
	press_event.position = touch.joystick_center + Vector2(30, 0)

	touch._handle_screen_touch(press_event)
	assert_true(touch.joystick_active, "Joystick should activate on touch press")
	assert_gt(touch.joystick_vector.x, 0.0, "Joystick vector X should be positive for rightward drag")

	# Release touch
	var release_event = InputEventScreenTouch.new()
	release_event.pressed = false
	release_event.index = 1
	release_event.position = touch.joystick_center + Vector2(30, 0)

	touch._handle_screen_touch(release_event)
	assert_false(touch.joystick_active, "Joystick should deactivate on touch release")
	assert_eq(touch.joystick_vector, Vector2.ZERO, "Joystick vector should reset to ZERO on release")

	touch.free()

func test_touch_action_button_synthesis() -> void:
	var touch_script = load("res://scripts/ui/TouchControls.gd")
	var touch = touch_script.new()
	touch._update_positions()

	# Touch attack button
	var atk_event = InputEventScreenTouch.new()
	atk_event.pressed = true
	atk_event.index = 2
	atk_event.position = touch.attack_btn_center

	touch._handle_screen_touch(atk_event)
	assert_true(Input.is_action_pressed("attack"), "Attack action should be pressed via touch button")

	# Release attack button
	atk_event.pressed = false
	touch._handle_screen_touch(atk_event)
	assert_false(Input.is_action_pressed("attack"), "Attack action should be released")

	touch.free()

func test_player_controller_touch_input_integration() -> void:
	var player_script = load("res://scripts/player/PlayerController3D.gd")
	assert_true(player_script != null, "PlayerController3D.gd script must exist")

	var player = player_script.new()
	assert_eq(player.touch_input_vector, Vector2.ZERO, "Player touch_input_vector should default to ZERO")

	player.touch_input_vector = Vector2(0.5, -0.8)
	assert_eq(player.touch_input_vector, Vector2(0.5, -0.8), "Player touch_input_vector must update correctly")

	player.free()
