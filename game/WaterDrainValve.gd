extends Node
class_name WaterDrainValve

var valve_id: String
var is_drained: bool = false

func _init(id: String = ""):
    valve_id = id

func interact():
    is_drained = true
