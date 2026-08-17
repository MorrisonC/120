extends Node
class_name BlockPushPuzzle

var block_id: String
var start_pos: Vector2
var pushable: bool

func _init(id: String = "", pos: Vector2 = Vector2.ZERO, p: bool = false):
    block_id = id
    start_pos = pos
    pushable = p

func try_push(_dir: Vector2):
    pass
