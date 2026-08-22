extends Node
class_name LightReflectorPuzzle

signal reflector_rotated(new_rotation_deg: float)

var reflector_id: String
var current_rotation_deg: float = 0.0

func _init(id: String = "", rot: float = 0.0):
    reflector_id = id
    current_rotation_deg = rot

func interact():
    current_rotation_deg += 90.0
    if current_rotation_deg >= 360.0:
        current_rotation_deg -= 360.0
    emit_signal("reflector_rotated", current_rotation_deg)
    var juice = get_node_or_null("/root/VisualJuiceManager")
    if is_instance_valid(juice):
        juice.apply_shake(2.0)
