extends Control

class_name TouchControls

signal joystick_moved(vector: Vector2)
signal attack_pressed()
signal roll_pressed()
signal interact_pressed()

# Joystick configuration
var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var joystick_current_pos: Vector2 = Vector2.ZERO
var joystick_radius: float = 70.0
var joystick_deadzone: float = 10.0
var joystick_vector: Vector2 = Vector2.ZERO

# Touch Buttons config & bounds
var attack_touch_index: int = -1
var roll_touch_index: int = -1
var interact_touch_index: int = -1

var attack_btn_center: Vector2 = Vector2.ZERO
var roll_btn_center: Vector2 = Vector2.ZERO
var interact_btn_center: Vector2 = Vector2.ZERO
var btn_radius: float = 40.0

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_PASS
	_update_positions()
	get_viewport().size_changed.connect(_update_positions)

func _update_positions() -> void:
	var viewport_size = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(1280, 720)

	joystick_center = Vector2(viewport_size.x * 0.15, viewport_size.y * 0.78)
	if not joystick_active:
		joystick_current_pos = joystick_center

	attack_btn_center = Vector2(viewport_size.x * 0.88, viewport_size.y * 0.76)
	roll_btn_center = Vector2(viewport_size.x * 0.76, viewport_size.y * 0.84)
	interact_btn_center = Vector2(viewport_size.x * 0.88, viewport_size.y * 0.58)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	var pos = event.position
	var idx = event.index

	if event.pressed:
		# Check if touch is on joystick area
		if not joystick_active and pos.distance_to(joystick_center) <= joystick_radius * 2.0:
			joystick_active = true
			joystick_touch_index = idx
			joystick_center = pos
			joystick_current_pos = pos
			_update_joystick_vector()
			queue_redraw()
			return

		# Check Attack Button
		if pos.distance_to(attack_btn_center) <= btn_radius * 1.3:
			attack_touch_index = idx
			Input.action_press("attack")
			attack_pressed.emit()
			queue_redraw()
			return

		# Check Roll/Dash Button
		if pos.distance_to(roll_btn_center) <= btn_radius * 1.3:
			roll_touch_index = idx
			Input.action_press("roll_dash")
			roll_pressed.emit()
			queue_redraw()
			return

		# Check Interact Button
		if pos.distance_to(interact_btn_center) <= btn_radius * 1.3:
			interact_touch_index = idx
			Input.action_press("interact")
			interact_pressed.emit()
			queue_redraw()
			return
	else:
		# Released event
		if idx == joystick_touch_index:
			joystick_active = false
			joystick_touch_index = -1
			_update_positions()
			joystick_vector = Vector2.ZERO
			joystick_moved.emit(Vector2.ZERO)
			queue_redraw()

		if idx == attack_touch_index:
			attack_touch_index = -1
			Input.action_release("attack")
			queue_redraw()

		if idx == roll_touch_index:
			roll_touch_index = -1
			Input.action_release("roll_dash")
			queue_redraw()

		if idx == interact_touch_index:
			interact_touch_index = -1
			Input.action_release("interact")
			queue_redraw()

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_index:
		joystick_current_pos = event.position
		_update_joystick_vector()
		queue_redraw()

func _update_joystick_vector() -> void:
	var diff = joystick_current_pos - joystick_center
	var dist = diff.length()
	if dist < joystick_deadzone:
		joystick_vector = Vector2.ZERO
	else:
		var clamped_dist = min(dist, joystick_radius)
		joystick_current_pos = joystick_center + diff.normalized() * clamped_dist
		joystick_vector = diff.normalized() * ((clamped_dist - joystick_deadzone) / (joystick_radius - joystick_deadzone))

	joystick_moved.emit(joystick_vector)

func _draw() -> void:
	if not is_visible_in_tree():
		return

	# Draw Joystick Base
	var base_col = Color(0.2, 0.2, 0.25, 0.45) if not joystick_active else Color(0.2, 0.5, 0.8, 0.55)
	draw_circle(joystick_center, joystick_radius, base_col)
	draw_arc(joystick_center, joystick_radius, 0, TAU, 32, Color(0.8, 0.9, 1.0, 0.6), 2.0)

	# Draw Joystick Handle
	var handle_col = Color(0.9, 0.95, 1.0, 0.8) if joystick_active else Color(0.6, 0.7, 0.8, 0.5)
	draw_circle(joystick_current_pos, joystick_radius * 0.4, handle_col)

	# Draw Attack Button
	var atk_col = Color(0.9, 0.2, 0.2, 0.7) if attack_touch_index != -1 else Color(0.8, 0.2, 0.2, 0.4)
	draw_circle(attack_btn_center, btn_radius, atk_col)
	draw_arc(attack_btn_center, btn_radius, 0, TAU, 24, Color(1.0, 0.6, 0.6, 0.8), 2.0)
	draw_string(ThemeDB.fallback_font, attack_btn_center + Vector2(-22, 6), "SWORD", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)

	# Draw Roll / Dash Button
	var roll_col = Color(0.2, 0.7, 0.9, 0.7) if roll_touch_index != -1 else Color(0.2, 0.6, 0.8, 0.4)
	draw_circle(roll_btn_center, btn_radius * 0.85, roll_col)
	draw_arc(roll_btn_center, btn_radius * 0.85, 0, TAU, 24, Color(0.6, 0.9, 1.0, 0.8), 2.0)
	draw_string(ThemeDB.fallback_font, roll_btn_center + Vector2(-16, 5), "DASH", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)

	# Draw Interact Button
	var int_col = Color(0.9, 0.7, 0.2, 0.7) if interact_touch_index != -1 else Color(0.8, 0.6, 0.2, 0.4)
	draw_circle(interact_btn_center, btn_radius * 0.85, int_col)
	draw_arc(interact_btn_center, btn_radius * 0.85, 0, TAU, 24, Color(1.0, 0.9, 0.6, 0.8), 2.0)
	draw_string(ThemeDB.fallback_font, interact_btn_center + Vector2(-26, 5), "INTERACT", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color.WHITE)
