extends Node
class_name LightReflectorPuzzle

var reflector_id: String
var current_rotation_deg: float = 0.0

func _init(id: String = "", rot: float = 0.0):
    reflector_id = id
    current_rotation_deg = rot

func interact():
    current_rotation_deg += 90.0
    if current_rotation_deg >= 360.0:
        current_rotation_deg -= 360.0
