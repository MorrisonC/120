extends CharacterBody2D
class_name PlayerController

signal attacked(facing_direction: Vector2)
signal health_changed(current_hp: int, max_hp: int)

@export var base_speed: float = 100.0
@export var max_health: int = 3

var current_health: int = 3
var input_vector: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var invulnerability_timer: float = 0.0

var attack_hitbox: Area2D
var attack_shape: CollisionShape2D
var sprite_node: Sprite2D

func _ready() -> void:
    current_health = max_health
    _setup_visual_sprite()
    _setup_attack_hitbox()

func _setup_visual_sprite() -> void:
    # Use TextureGenerator if available
    var tex_gen = load("res://assets/TextureGenerator.gd")
    if is_instance_valid(tex_gen) and tex_gen.has_method("create_player_texture"):
        sprite_node = Sprite2D.new()
        sprite_node.name = "PlayerSprite"
        sprite_node.texture = tex_gen.create_player_texture()
        add_child(sprite_node)

func _setup_attack_hitbox() -> void:
    attack_hitbox = Area2D.new()
    attack_hitbox.name = "AttackHitbox"
    attack_hitbox.monitoring = false
    attack_hitbox.monitorable = false

    attack_shape = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(16, 16)
    attack_shape.shape = shape
    attack_shape.disabled = true
    attack_shape.position = Vector2(0, 16) # Default facing down

    attack_hitbox.add_child(attack_shape)
    add_child(attack_hitbox)

func _physics_process(delta: float) -> void:
    _handle_timers(delta)
    _handle_input(delta)
    _apply_movement()

func _handle_timers(delta: float) -> void:
    if attack_cooldown > 0.0:
        attack_cooldown -= delta
        if attack_cooldown <= 0.0:
            is_attacking = false
            attack_hitbox.monitoring = false
            attack_hitbox.monitorable = false
            if is_instance_valid(attack_shape):
                attack_shape.disabled = true

    if invulnerability_timer > 0.0:
        invulnerability_timer -= delta
        if is_instance_valid(sprite_node):
            sprite_node.modulate.a = 0.5 if fmod(invulnerability_timer * 10.0, 2.0) > 1.0 else 1.0
    else:
        if is_instance_valid(sprite_node):
            sprite_node.modulate.a = 1.0

func _handle_input(_delta: float) -> void:
    # Read movement input from InputMap or key polling
    var x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    var y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

    # Fallback to key checks if input actions not triggered
    if x == 0.0:
        if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
            x += 1.0
        if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
            x -= 1.0

    if y == 0.0:
        if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
            y += 1.0
        if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
            y -= 1.0

    input_vector = Vector2(x, y)

    if input_vector.length_squared() > 0.001:
        # Snap facing direction to 4 cardinal directions
        if abs(input_vector.x) > abs(input_vector.y):
            facing_direction = Vector2.RIGHT if input_vector.x > 0 else Vector2.LEFT
        else:
            facing_direction = Vector2.DOWN if input_vector.y > 0 else Vector2.UP
        _update_attack_hitbox_position()

    # Attack / Interact trigger
    if (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_J)) and not is_attacking:
        perform_attack()

func _update_attack_hitbox_position() -> void:
    if is_instance_valid(attack_shape):
        attack_shape.position = facing_direction * 16.0

func _apply_movement() -> void:
    var move_speed_modifier = 1.0
    var game_state = get_node_or_null("/root/GameState")
    if is_instance_valid(game_state):
        move_speed_modifier = game_state.move_speed_modifier

    if is_attacking:
        velocity = Vector2.ZERO
    else:
        velocity = input_vector.normalized() * (base_speed * move_speed_modifier)

    move_and_slide()

func perform_attack() -> void:
    is_attacking = true
    attack_cooldown = 0.25
    attack_hitbox.monitoring = true
    attack_hitbox.monitorable = true
    if is_instance_valid(attack_shape):
        attack_shape.disabled = false

    var juice = get_node_or_null("/root/VisualJuiceManager")
    if is_instance_valid(juice):
        juice.spawn_particles(global_position + facing_direction * 16.0, Color.WHITE, 6)

    emit_signal("attacked", facing_direction)

func take_damage(amount: int = 1) -> void:
    if invulnerability_timer > 0.0:
        return

    current_health = max(0, current_health - amount)
    invulnerability_timer = 1.0
    emit_signal("health_changed", current_health, max_health)

    var juice = get_node_or_null("/root/VisualJuiceManager")
    if is_instance_valid(juice):
        juice.trigger_screen_shake(0.2, 5.0)

    if current_health <= 0:
        var time_mgr = get_node_or_null("/root/TimeManager")
        if is_instance_valid(time_mgr):
            time_mgr.force_death("combat_damage")
