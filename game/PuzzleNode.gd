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
        emit_signal("puzzle_solved", puzzle_id)

func reset():
    is_solved = false
