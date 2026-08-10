extends GutTest

var puzzle_node = preload("res://PuzzleNode.gd")
var block_push = preload("res://BlockPushPuzzle.gd")
var dig_spot = preload("res://DigSpotPuzzle.gd")
var vine_cut = preload("res://VineCutPuzzle.gd")
var water_drain = preload("res://WaterDrainValve.gd")
var light_reflector = preload("res://LightReflectorPuzzle.gd")
var timed_lever = preload("res://TimedLeverSequence.gd")
var game_state = preload("res://GameState.gd")

var gs: Node

func before_each():
    gs = game_state.new()
    add_child(gs)

func after_each():
    if gs:
        gs.queue_free()

func test_block_push_puzzle():
    var puzzle = block_push.new("p1", Vector2(0, 0), Vector2(32, 0))
    add_child(puzzle)

    # Should take a few pushes to get there (16px per push)
    puzzle.interact(gs)
    assert_false(puzzle.is_solved, "Should not be solved yet")

    puzzle.interact(gs)
    assert_true(puzzle.is_solved, "Should be solved now")

    puzzle.queue_free()

func test_dig_spot_puzzle():
    var puzzle = dig_spot.new("dig1", "Ancient Coin")
    add_child(puzzle)

    var solved_without_shovel = puzzle.interact(gs)
    assert_false(solved_without_shovel, "Cannot dig without shovel")
    assert_false(gs.run_state.unlocked_key_items.has("Ancient Coin"), "Should not have received item")

    gs.add_key_item("Shovel")

    var solved_with_shovel = puzzle.interact(gs)
    assert_true(solved_with_shovel, "Should dig with shovel")
    assert_true(gs.run_state.unlocked_key_items.has("Ancient Coin"), "Should receive the item")

    puzzle.queue_free()

func test_vine_cut_puzzle():
    var puzzle = vine_cut.new("vine1")
    add_child(puzzle)

    var solved_without_shears = puzzle.interact(gs)
    assert_false(solved_without_shears, "Cannot cut without shears")

    gs.add_key_item("Shears")

    var solved_with_shears = puzzle.interact(gs)
    assert_true(solved_with_shears, "Should cut with shears")

    puzzle.queue_free()

func test_water_drain_puzzle():
    var puzzle = water_drain.new("valve1")
    add_child(puzzle)

    assert_false(puzzle.interact(gs), "Cannot drain without capabilities")

    gs.add_key_item("Shovel") # using shovel as makeshift wrench per prompt

    assert_true(puzzle.interact(gs), "Should drain with shovel")

    puzzle.queue_free()

func test_light_reflector_puzzle():
    var puzzle = light_reflector.new("light1", 2)
    add_child(puzzle)

    assert_false(puzzle.interact(gs), "Cannot reflect without light")

    gs.add_key_item("Lantern")

    puzzle.interact(gs)
    assert_false(puzzle.is_solved, "Needs two mirrors aligned")

    puzzle.interact(gs)
    assert_true(puzzle.is_solved, "Both mirrors aligned, solved")

    puzzle.queue_free()

func test_timed_lever_sequence():
    var puzzle = timed_lever.new("timed1", 3, 2.0)
    add_child(puzzle)

    # Lever 1
    puzzle.interact(gs)
    assert_false(puzzle.is_solved, "Sequence incomplete")

    # Simulate time passing via _process
    puzzle._process(1.5)

    # Lever 2
    puzzle.interact(gs)
    assert_false(puzzle.is_solved, "Sequence incomplete")

    puzzle._process(1.0) # total 2.5s, limit is 2.0s

    # Lever 3 (too late)
    var success = puzzle.interact(gs)
    assert_false(success, "Should fail because time limit exceeded")
    assert_false(puzzle.is_solved, "Puzzle is not solved")

    # Retry and succeed
    puzzle.interact(gs) # Lever 1
    puzzle._process(0.5)
    puzzle.interact(gs) # Lever 2
    puzzle._process(0.5)
    var retry_success = puzzle.interact(gs) # Lever 3

    assert_true(retry_success, "Should succeed within time limit")
    assert_true(puzzle.is_solved, "Puzzle is solved")

    puzzle.queue_free()
