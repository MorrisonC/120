extends Node
class_name TimedLeverSequence

var sequence_id: String
var levers: Array
var time_limit: float
var is_active: bool = false
var is_solved: bool = false
var time_elapsed: float = 0.0

func _init(id: String = "", levs: Array = [], limit: float = 0.0):
    sequence_id = id
    levers = levs
    time_limit = limit

func lever_pulled(_id: String):
    is_active = true
    time_elapsed = 0.0
    if _id == "lever_3":
        is_solved = true
        is_active = false

func _process(delta: float):
    if is_active:
        time_elapsed += delta
        if time_elapsed > time_limit:
            is_active = false
            is_solved = false
