extends Node
class_name VineCutPuzzle

signal vine_cut()

var vine_id: String
var is_cut: bool = false

func _init(id: String = ""):
    vine_id = id

func try_cut(caps: Dictionary) -> bool:
    if caps.has("can_cut_vines") and caps["can_cut_vines"]:
        is_cut = true
        emit_signal("vine_cut")
        var juice = get_node_or_null("/root/VisualJuiceManager")
        if is_instance_valid(juice):
            juice.spawn_particles(Vector2.ZERO, Color(0.2, 0.8, 0.2))
        return true
    return false
