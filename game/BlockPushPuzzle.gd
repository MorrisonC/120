extends Node
class_name BlockPushPuzzle

signal block_pushed(direction: Vector2)

var block_id: String
var start_pos: Vector2
var position: Vector2
var pushable: bool

func _init(id: String = "", pos: Vector2 = Vector2.ZERO, p: bool = false):
    block_id = id
    start_pos = pos
    position = pos
    pushable = p

func try_push(dir: Vector2) -> bool:
    if pushable:
        position += dir * 16.0
        emit_signal("block_pushed", dir)
        var juice = get_node_or_null("/root/VisualJuiceManager")
        if is_instance_valid(juice):
            juice.apply_shake(3.0)
            juice.spawn_particles(position)
        return true
    return false
