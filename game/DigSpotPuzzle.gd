extends "res://PuzzleNode.gd"
class_name DigSpotPuzzle

var item_contained: String

func _init(id: String, item: String = ""):
    puzzle_id = id
    item_contained = item

func interact(player_state: Node) -> bool:
    if is_solved:
        return false

    if player_state.terrain_capabilities.get("can_dig", false):
        solve()
        if item_contained != "":
            player_state.add_key_item(item_contained)
        return true

    emit_signal("puzzle_failed", puzzle_id)
    return false
