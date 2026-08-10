extends "res://PuzzleNode.gd"
class_name LightReflectorPuzzle

var mirrors_aligned: int = 0
var required_mirrors: int

func _init(id: String, req_mirrors: int):
    puzzle_id = id
    required_mirrors = req_mirrors

func interact(player_state: Node) -> bool:
    if is_solved:
        return false

    if player_state.terrain_capabilities.get("has_light", false):
        mirrors_aligned += 1
        if mirrors_aligned >= required_mirrors:
            solve()
        return true

    emit_signal("puzzle_failed", puzzle_id)
    return false

func reset():
    super.reset()
    mirrors_aligned = 0
