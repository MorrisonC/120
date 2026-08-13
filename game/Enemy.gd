extends CharacterBody2D

enum Behavior { STATIONARY, PATROL, CHASER }
@export var behavior: Behavior = Behavior.STATIONARY
@export var patrol_radius: float = 100.0
@export var move_speed: float = 50.0

var start_pos: Vector2
var patrol_target: Vector2
var _rng = RandomNumberGenerator.new()

@onready var sprite = $Sprite2D

func _ready():
    start_pos = global_position
    _rng.randomize()
    _pick_new_patrol_target()

func _physics_process(delta):
    if behavior == Behavior.STATIONARY:
        return

    var direction = Vector2.ZERO

    if behavior == Behavior.PATROL:
        if global_position.distance_to(patrol_target) < 5.0:
            _pick_new_patrol_target()
        direction = (patrol_target - global_position).normalized()

    elif behavior == Behavior.CHASER:
        # Get player if exists
        var players = get_tree().get_nodes_in_group("player")
        if players.size() > 0:
            var player = players[0]
            # Simple line-of-sight chase within a radius
            if global_position.distance_to(player.global_position) < 300.0:
                direction = (player.global_position - global_position).normalized()
            else:
                # Fall back to patrol if player out of range
                if global_position.distance_to(patrol_target) < 5.0:
                    _pick_new_patrol_target()
                direction = (patrol_target - global_position).normalized()

    if direction:
        velocity = direction * move_speed
        if sprite:
            if direction.x < 0:
                sprite.flip_h = true
            elif direction.x > 0:
                sprite.flip_h = false
    else:
        velocity = Vector2.ZERO

    move_and_slide()

func _pick_new_patrol_target():
    var random_offset = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)).normalized() * _rng.randf_range(10.0, patrol_radius)
    patrol_target = start_pos + random_offset
