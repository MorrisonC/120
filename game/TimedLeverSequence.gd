extends "res://PuzzleNode.gd"
class_name TimedLeverSequence

var current_lever: int = 0
var required_levers: int
var time_limit: float
var current_time: float = 0.0
var sequence_started: bool = false

func _init(id: String, req: int, limit: float):
    puzzle_id = id
    required_levers = req
    time_limit = limit

func _process(delta: float):
    if sequence_started and not is_solved:
        current_time += delta
        if current_time > time_limit:
            _fail_sequence()

func interact(player_state: Node) -> bool:
    if is_solved:
        return false

    if not sequence_started:
        sequence_started = true
        current_time = 0.0

    current_lever += 1

    if current_lever >= required_levers:
        if current_time <= time_limit:
            solve()
            sequence_started = false
            return true
        else:
            _fail_sequence()
            return false

    return true

func _fail_sequence():
    sequence_started = false
    current_time = 0.0
    current_lever = 0
    emit_signal("puzzle_failed", puzzle_id)

func reset():
    super.reset()
    sequence_started = false
    current_time = 0.0
    current_lever = 0
