extends CharacterBody2D
class_name PlayerController

@export var base_speed: float = 100.0
var input_vector: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
    var move_speed_modifier = 1.0
    var game_state = get_node_or_null("/root/GameState")
    if is_instance_valid(game_state):
        move_speed_modifier = game_state.move_speed_modifier

    input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    velocity = input_vector.normalized() * (base_speed * move_speed_modifier)
    move_and_slide()
