extends Node
class_name PuzzleNode

signal puzzle_solved(puzzle_id: String)
signal puzzle_failed(puzzle_id: String)

@export var puzzle_id: String = ""
var is_solved: bool = false

func interact(player_state: Node) -> bool:
    # Virtual method to be overridden
    return false

func solve():
    if not is_solved:
        is_solved = true
        TelemetryLogger.log_event("puzzle_solved", {"id": puzzle_id, "time_taken": 0.0}) # Replace 0.0 with actual time tracking later if feasible at node level
        emit_signal("puzzle_solved", puzzle_id)

func failed_attempt():
    TelemetryLogger.log_event("puzzle_failed_attempt", {"id": puzzle_id})
    emit_signal("puzzle_failed", puzzle_id)

func reset():
    is_solved = false
