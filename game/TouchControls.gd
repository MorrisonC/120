extends Control
class_name TouchControls

signal joystick_moved(vector: Vector2)
signal attack_pressed
signal attack_released

@export var max_joystick_radius: float = 32.0
@export var deadzone: float = 0.15
@export var attack_button_center: Vector2 = Vector2(280, 140)
@export var attack_button_radius: float = 20.0
@export var default_joystick_center: Vector2 = Vector2(48, 132)

var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var joystick_knob_position: Vector2 = Vector2.ZERO
var current_joystick_vector: Vector2 = Vector2.ZERO

var attack_touch_index: int = -1
var attack_pressed_state: bool = false

var is_touch_device_detected: bool = false

func _ready() -> void:
    set_process_input(true)
    mouse_filter = MOUSE_FILTER_PASS
    # Default position for display when inactive
    joystick_center = default_joystick_center
    joystick_knob_position = default_joystick_center

    # Auto-detect touch capability
    if DisplayServer.has_feature(DisplayServer.FEATURE_TOUCHSCREEN) or OS.has_feature("mobile") or OS.has_feature("web") or OS.has_feature("touchscreen"):
        is_touch_device_detected = true

func _gui_input(event: InputEvent) -> void:
    _process_touch_event(event)

func _unhandled_input(event: InputEvent) -> void:
    _process_touch_event(event)

func _process_touch_event(event: InputEvent) -> void:
    var viewport_size = get_viewport_rect().size
    if viewport_size == Vector2.ZERO:
        viewport_size = Vector2(320, 180)

    if event is InputEventScreenTouch:
        is_touch_device_detected = true
        if event.pressed:
            _handle_touch_down(event.index, event.position, viewport_size)
        else:
            _handle_touch_up(event.index)
        queue_redraw()

    elif event is InputEventScreenDrag:
        is_touch_device_detected = true
        _handle_touch_drag(event.index, event.position)
        queue_redraw()

    elif event is InputEventMouseButton:
        # Fallback for mouse testing touch controls in editor/web browser
        var touch_pos = event.position
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _handle_touch_down(99, touch_pos, viewport_size)
        elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _handle_touch_up(99)
        queue_redraw()

    elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
        _handle_touch_drag(99, event.position)
        queue_redraw()

func _handle_touch_down(index: int, pos: Vector2, viewport_size: Vector2) -> void:
    # Check attack button first (Right half of screen or near button)
    if pos.distance_to(attack_button_center) <= attack_button_radius * 1.5 or pos.x >= viewport_size.x * 0.65:
        if pos.distance_to(attack_button_center) <= attack_button_radius * 2.0:
            attack_touch_index = index
            attack_pressed_state = true
            emit_signal("attack_pressed")
            return

    # Check joystick area (Left half of screen)
    if pos.x < viewport_size.x * 0.55:
        if joystick_touch_index == -1:
            joystick_touch_index = index
            joystick_active = true
            joystick_center = pos
            joystick_knob_position = pos
            _update_joystick_vector(pos)

func _handle_touch_drag(index: int, pos: Vector2) -> void:
    if index == joystick_touch_index and joystick_active:
        _update_joystick_vector(pos)

    if index == attack_touch_index and attack_pressed_state:
        # If dragged too far away from attack button, release it
        if pos.distance_to(attack_button_center) > attack_button_radius * 2.5:
            attack_pressed_state = false
            attack_touch_index = -1
            emit_signal("attack_released")

func _handle_touch_up(index: int) -> void:
    if index == joystick_touch_index:
        joystick_active = false
        joystick_touch_index = -1
        current_joystick_vector = Vector2.ZERO
        joystick_center = default_joystick_center
        joystick_knob_position = default_joystick_center
        emit_signal("joystick_moved", Vector2.ZERO)

    if index == attack_touch_index:
        attack_pressed_state = false
        attack_touch_index = -1
        emit_signal("attack_released")

func _update_joystick_vector(pos: Vector2) -> void:
    var diff = pos - joystick_center
    var dist = diff.length()

    if dist > max_joystick_radius:
        diff = diff.normalized() * max_joystick_radius
        dist = max_joystick_radius

    joystick_knob_position = joystick_center + diff

    var norm_dist = dist / max_joystick_radius
    if norm_dist < deadzone:
        current_joystick_vector = Vector2.ZERO
    else:
        var remapped = (norm_dist - deadzone) / (1.0 - deadzone)
        current_joystick_vector = diff.normalized() * remapped

    emit_signal("joystick_moved", current_joystick_vector)

func get_joystick_vector() -> Vector2:
    return current_joystick_vector

func is_attack_pressed() -> bool:
    return attack_pressed_state

func _draw() -> void:
    # Always render touch controls on web/mobile or when touch detected
    # Outer Joystick Base Ring
    var base_color = Color(0.2, 0.2, 0.35, 0.45)
    var border_color = Color(0.8, 0.85, 1.0, 0.6)
    if joystick_active:
        base_color = Color(0.25, 0.3, 0.5, 0.65)
        border_color = Color(0.9, 0.95, 1.0, 0.85)

    draw_circle(joystick_center, max_joystick_radius, base_color)
    draw_arc(joystick_center, max_joystick_radius, 0.0, TAU, 32, border_color, 1.5)

    # D-Pad Cardinal Guide Cross lines inside base
    var guide_color = Color(1.0, 1.0, 1.0, 0.25)
    draw_line(joystick_center - Vector2(max_joystick_radius * 0.7, 0), joystick_center + Vector2(max_joystick_radius * 0.7, 0), guide_color, 1.0)
    draw_line(joystick_center - Vector2(0, max_joystick_radius * 0.7), joystick_center + Vector2(0, max_joystick_radius * 0.7), guide_color, 1.0)

    # Inner Stick Knob
    var knob_color = Color(0.85, 0.9, 1.0, 0.8) if joystick_active else Color(0.6, 0.65, 0.8, 0.5)
    draw_circle(joystick_knob_position, 12.0, knob_color)
    draw_arc(joystick_knob_position, 12.0, 0.0, TAU, 24, Color.WHITE, 1.0)

    # Action / Attack Button ("A")
    var btn_color = Color(0.85, 0.25, 0.25, 0.6)
    var btn_border = Color(1.0, 0.8, 0.8, 0.8)
    if attack_pressed_state:
        btn_color = Color(1.0, 0.4, 0.4, 0.9)
        btn_border = Color(1.0, 1.0, 1.0, 0.95)

    draw_circle(attack_button_center, attack_button_radius, btn_color)
    draw_arc(attack_button_center, attack_button_radius, 0.0, TAU, 32, btn_border, 2.0)

    # Draw "A" / Sword label on Attack button
    var font = ThemeDB.fallback_font
    if font:
        draw_string(font, attack_button_center + Vector2(-4, 5), "A", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
