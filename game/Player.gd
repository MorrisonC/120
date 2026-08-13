extends CharacterBody2D

var base_speed = 100.0

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

func _ready():
    # Make sure we start at the right respawn point from GameState
    if GameState.active_spawn_point != Vector2.ZERO:
        global_position = GameState.active_spawn_point

func _physics_process(delta):
    var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    # Calculate speed dynamically based on GameState modifiers
    var current_speed = base_speed * GameState.move_speed_modifier

    # Simple check for terrain modifier right beneath player (if we had complex terrain handling)
    # E.g. query tilemap for mud/sand

    if direction:
        velocity = direction * current_speed

        # Simple animation handling (if we have an animation player setup)
        if animation_player and animation_player.has_animation("walk"):
            animation_player.play("walk")

        # Flip sprite based on direction
        if sprite:
            if direction.x < 0:
                sprite.flip_h = true
            elif direction.x > 0:
                sprite.flip_h = false
    else:
        velocity = Vector2.ZERO
        if animation_player and animation_player.has_animation("idle"):
            animation_player.play("idle")

    move_and_slide()

    # Check collisions for enemies/hazards
    for i in get_slide_collision_count():
        var collision = get_slide_collision(i)
        var collider = collision.get_collider()
        if collider and collider.is_in_group("enemies"):
            die("Touched Enemy")

func die(reason: String):
    # Use TimeManager to force a death reset
    TimeManager.force_death(reason)
    # The GameState respawn_player handles state reset, we just need to move ourselves
    global_position = GameState.active_spawn_point
