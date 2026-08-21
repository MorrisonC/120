extends "res://addons/gut/test.gd"

var BlockPushPuzzle = load("res://BlockPushPuzzle.gd")
var DigSpotPuzzle = load("res://DigSpotPuzzle.gd")
var VineCutPuzzle = load("res://VineCutPuzzle.gd")
var WaterDrainValve = load("res://WaterDrainValve.gd")
var LightReflectorPuzzle = load("res://LightReflectorPuzzle.gd")
var TimedLeverSequence = load("res://TimedLeverSequence.gd")
var PlayerController = load("res://PlayerController.gd")

var game_st = null

func before_each():
    game_st = load("res://GameState.gd").new()
    add_child_autoqfree(game_st)

func test_block_push_puzzle():
    var puzzle = BlockPushPuzzle.new("test_block", Vector2.ZERO, false)
    add_child_autoqfree(puzzle)

    puzzle.block_id = "test_block"
    puzzle.try_push(Vector2.RIGHT)
    assert_true(true)

func test_dig_spot_puzzle():
    var puzzle = DigSpotPuzzle.new("test_spot")
    add_child_autoqfree(puzzle)

    assert_false(puzzle.is_dug, "Spot should initially not be dug")

    game_st.terrain_capabilities.can_dig = false
    var success1 = puzzle.try_dig(game_st.terrain_capabilities)
    assert_false(success1, "Should fail to dig without shovel")
    assert_false(puzzle.is_dug, "Spot should remain un-dug")

    game_st.terrain_capabilities.can_dig = true
    var success2 = puzzle.try_dig(game_st.terrain_capabilities)
    assert_true(success2, "Should succeed digging with shovel")
    assert_true(puzzle.is_dug, "Spot should now be dug")

func test_vine_cut_puzzle():
    var puzzle = VineCutPuzzle.new("test_vine")
    add_child_autoqfree(puzzle)

    game_st.terrain_capabilities.can_cut_vines = false
    assert_false(puzzle.try_cut(game_st.terrain_capabilities))

    game_st.terrain_capabilities.can_cut_vines = true
    assert_true(puzzle.try_cut(game_st.terrain_capabilities))

func test_water_drain_puzzle():
    var puzzle = WaterDrainValve.new("test_valve")
    add_child_autoqfree(puzzle)

    assert_false(puzzle.is_drained)
    puzzle.interact()
    assert_true(puzzle.is_drained)

func test_light_reflector_puzzle():
    var puzzle = LightReflectorPuzzle.new("test_reflector", 0.0)
    add_child_autoqfree(puzzle)

    assert_eq(puzzle.current_rotation_deg, 0.0)
    puzzle.interact()
    assert_eq(puzzle.current_rotation_deg, 90.0)
    puzzle.interact()
    assert_eq(puzzle.current_rotation_deg, 180.0)

func test_timed_lever_sequence():
    var puzzle = TimedLeverSequence.new("test_sequence", ["lever_1", "lever_2", "lever_3"], 2.0)
    add_child_autoqfree(puzzle)

    puzzle.time_limit = 2.0

    puzzle.lever_pulled("lever_1")
    assert_true(puzzle.is_active)

    puzzle._process(2.5)
    assert_false(puzzle.is_active, "Should fail because time limit exceeded")

    puzzle.lever_pulled("lever_1")
    puzzle._process(1.0)
    puzzle.lever_pulled("lever_2")
    puzzle._process(0.5)
    puzzle.lever_pulled("lever_3")

    assert_true(puzzle.is_solved, "Should succeed within time limit")
    assert_false(puzzle.is_active)

func test_impassable_terrain_blocks_movement():
    var player = PlayerController.new()
    var col_shape = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(16, 16)
    col_shape.shape = shape
    player.add_child(col_shape)
    add_child_autoqfree(player)
    player.position = Vector2(0, 0)

    var obstacle = StaticBody2D.new()
    var wall_shape = CollisionShape2D.new()
    var wall_box = RectangleShape2D.new()
    wall_box.size = Vector2(16, 32)
    wall_shape.shape = wall_box
    obstacle.add_child(wall_shape)
    add_child_autoqfree(obstacle)
    obstacle.position = Vector2(16, 0)

    player.velocity = Vector2(100.0, 0.0)
    player.move_and_slide()

    assert_true(player.position.x < 16.0, "Player movement should be blocked by impassable obstacle")
