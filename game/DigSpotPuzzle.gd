extends Node
class_name DigSpotPuzzle

signal spot_dug()

var spot_id: String
var is_dug: bool = false

func _init(id: String = ""):
    spot_id = id

func try_dig(caps: Dictionary) -> bool:
    if caps.has("can_dig") and caps["can_dig"]:
        is_dug = true
        emit_signal("spot_dug")
        var juice = get_node_or_null("/root/VisualJuiceManager")
        if is_instance_valid(juice):
            juice.spawn_particles(Vector2.ZERO, Color(0.6, 0.4, 0.2))
        return true
    return false
