extends "res://PuzzleNode.gd"
class_name VineCutPuzzle

func _init(id: String):
    puzzle_id = id

func interact(player_state: Node) -> bool:
    if is_solved:
        return false

    if player_state.terrain_capabilities.get("can_cut_vines", false):
        solve()
        return true

    emit_signal("puzzle_failed", puzzle_id)
    return false
