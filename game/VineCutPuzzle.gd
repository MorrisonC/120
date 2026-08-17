extends Node
class_name VineCutPuzzle

var vine_id: String

func _init(id: String = ""):
    vine_id = id

func try_cut(caps: Dictionary) -> bool:
    return caps.has("can_cut_vines") and caps["can_cut_vines"]
