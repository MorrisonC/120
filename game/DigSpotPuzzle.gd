extends Node
class_name DigSpotPuzzle

var spot_id: String
var is_dug: bool = false

func _init(id: String = ""):
    spot_id = id

func try_dig(caps: Dictionary) -> bool:
    if caps.has("can_dig") and caps["can_dig"]:
        is_dug = true
        return true
    return false
