extends "res://PuzzleNode.gd"
class_name WaterDrainValve

func _init(id: String):
    puzzle_id = id

func interact(player_state: Node) -> bool:
    if is_solved:
        return false

    # Example logic: Shovel can be used as a makeshift wrench, or maybe player needs nothing but interaction
    # The prompt specified Wrench/Shovel
    if player_state.terrain_capabilities.get("can_dig", false):
        solve()
        return true

    emit_signal("puzzle_failed", puzzle_id)
    return false
