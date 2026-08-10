extends "res://PuzzleNode.gd"
class_name BlockPushPuzzle

var start_pos: Vector2
var current_pos: Vector2
var target_pos: Vector2

func _init(id: String, start: Vector2, target: Vector2):
    puzzle_id = id
    start_pos = start
    current_pos = start
    target_pos = target

func interact(player_state: Node) -> bool:
    # Simple logic: player just interacts to push block toward target
    # Real game would use physics/collisions
    var dir = (target_pos - current_pos).normalized()
    current_pos += dir * 16.0 # Arbitrary grid push

    if current_pos.distance_to(target_pos) < 1.0:
        current_pos = target_pos
        solve()
        return true

    return false

func reset():
    super.reset()
    current_pos = start_pos
