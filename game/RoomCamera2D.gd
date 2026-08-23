extends Camera2D
class_name RoomCamera2D

@export var room_size: Vector2 = Vector2(320, 180)
@export var smooth_transition: bool = true
@export var transition_speed: float = 10.0

signal room_changed(new_room: Vector2)

var target_position: Vector2 = Vector2.ZERO
var current_room: Vector2 = Vector2(-999, -999) # Init to invalid room to force update on frame 1

func _ready() -> void:
    set_process(true)
    top_level = true # Disconnect from parent transform
    zoom = Vector2(4.0, 4.0) # Scale 320x180 pixel-art room to fill 1280x720 viewport
    if get_parent() and get_parent() is Node2D:
        var parent_pos = get_parent().global_position
        var room = Vector2(
            floor(parent_pos.x / room_size.x),
            floor(parent_pos.y / room_size.y)
        )
        current_room = room
        target_position = room * room_size + (room_size / 2)
        global_position = target_position

func _process(delta: float) -> void:
    if get_parent() and get_parent() is Node2D:
        var parent_pos = get_parent().global_position

        # Calculate which room the parent is in
        var new_room = Vector2(
            floor(parent_pos.x / room_size.x),
            floor(parent_pos.y / room_size.y)
        )

        if new_room != current_room:
            current_room = new_room
            # Center of the current room
            target_position = current_room * room_size + (room_size / 2)
            emit_signal("room_changed", current_room)

            if not smooth_transition:
                global_position = target_position

        if smooth_transition and global_position != target_position:
            global_position = global_position.lerp(target_position, transition_speed * delta)

            # Snap to target if very close to prevent jitter
            if global_position.distance_to(target_position) < 0.5:
                global_position = target_position
