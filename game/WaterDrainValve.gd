extends Node
class_name WaterDrainValve

signal water_drained()

var valve_id: String
var is_drained: bool = false

func _init(id: String = ""):
    valve_id = id

func interact():
    is_drained = true
    emit_signal("water_drained")
    var juice = get_node_or_null("/root/VisualJuiceManager")
    if is_instance_valid(juice):
        juice.spawn_particles(Vector2.ZERO, Color(0.2, 0.4, 0.9))
