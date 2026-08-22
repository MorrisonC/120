extends "res://addons/gut/test.gd"

var BlockPushPuzzle = load("res://BlockPushPuzzle.gd")
var DigSpotPuzzle = load("res://DigSpotPuzzle.gd")
var VineCutPuzzle = load("res://VineCutPuzzle.gd")
var WaterDrainValve = load("res://WaterDrainValve.gd")
var LightReflectorPuzzle = load("res://LightReflectorPuzzle.gd")
var TimedLeverSequence = load("res://TimedLeverSequence.gd")
var PlayerController = load("res://PlayerController.gd")
var NPCDialogueTrigger = load("res://NPCDialogueTrigger.gd")
var AudioManager = load("res://AudioManager.gd")

var game_st = null

func before_each():
    game_st = load("res://GameState.gd").new()
    add_child_autoqfree(game_st)

func test_block_push_puzzle():
    var unpushable = BlockPushPuzzle.new("unpushable_block", Vector2.ZERO, false)
    add_child_autoqfree(unpushable)
    assert_false(unpushable.try_push(Vector2.RIGHT), "Unpushable block should return false")

    var pushable_block = BlockPushPuzzle.new("pushable_block", Vector2.ZERO, true)
    add_child_autoqfree(pushable_block)
    watch_signals(pushable_block)

    var res = pushable_block.try_push(Vector2.RIGHT)
    assert_true(res, "Pushable block should return true")
    assert_eq(pushable_block.position, Vector2(16, 0), "Block position should shift on push")
    assert_signal_emitted_with_parameters(pushable_block, "block_pushed", [Vector2.RIGHT])

func test_dig_spot_puzzle():
    var puzzle = DigSpotPuzzle.new("test_spot")
    add_child_autoqfree(puzzle)
    watch_signals(puzzle)

    assert_false(puzzle.is_dug, "Spot should initially not be dug")

    game_st.terrain_capabilities.can_dig = false
    var success1 = puzzle.try_dig(game_st.terrain_capabilities)
    assert_false(success1, "Should fail to dig without shovel")
    assert_false(puzzle.is_dug, "Spot should remain un-dug")

    game_st.terrain_capabilities.can_dig = true
    var success2 = puzzle.try_dig(game_st.terrain_capabilities)
    assert_true(success2, "Should succeed digging with shovel")
    assert_true(puzzle.is_dug, "Spot should now be dug")
    assert_signal_emitted(puzzle, "spot_dug")

func test_vine_cut_puzzle():
    var puzzle = VineCutPuzzle.new("test_vine")
    add_child_autoqfree(puzzle)
    watch_signals(puzzle)

    game_st.terrain_capabilities.can_cut_vines = false
    assert_false(puzzle.try_cut(game_st.terrain_capabilities))

    game_st.terrain_capabilities.can_cut_vines = true
    assert_true(puzzle.try_cut(game_st.terrain_capabilities))
    assert_signal_emitted(puzzle, "vine_cut")

func test_water_drain_puzzle():
    var puzzle = WaterDrainValve.new("test_valve")
    add_child_autoqfree(puzzle)
    watch_signals(puzzle)

    assert_false(puzzle.is_drained)
    puzzle.interact()
    assert_true(puzzle.is_drained)
    assert_signal_emitted(puzzle, "water_drained")

func test_light_reflector_puzzle():
    var puzzle = LightReflectorPuzzle.new("test_reflector", 0.0)
    add_child_autoqfree(puzzle)
    watch_signals(puzzle)

    assert_eq(puzzle.current_rotation_deg, 0.0)
    puzzle.interact()
    assert_eq(puzzle.current_rotation_deg, 90.0)
    assert_signal_emitted_with_parameters(puzzle, "reflector_rotated", [90.0])

func test_timed_lever_sequence():
    var puzzle = TimedLeverSequence.new("test_sequence", ["lever_1", "lever_2", "lever_3"], 2.0)
    add_child_autoqfree(puzzle)
    watch_signals(puzzle)

    puzzle.time_limit = 2.0

    puzzle.lever_pulled("lever_1")
    assert_true(puzzle.is_active)
    assert_signal_emitted_with_parameters(puzzle, "lever_pulled_signal", ["lever_1"])

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

func test_npc_dialogue_trigger():
    var npc = NPCDialogueTrigger.new()
    add_child_autoqfree(npc)
    watch_signals(npc)

    var first_line = npc.interact()
    assert_true(npc.has_met)
    assert_true(npc.is_dialogue_open)
    assert_eq(first_line, npc.first_meeting_text)
    assert_signal_emitted_with_parameters(npc, "dialogue_opened", [npc.first_meeting_text])

    var second_line = npc.interact()
    assert_eq(second_line, npc.repeat_text)

    npc.close_dialogue()
    assert_false(npc.is_dialogue_open)
    assert_signal_emitted(npc, "dialogue_closed")

func test_audio_manager_nodes():
    var audio_mgr = AudioManager.new()
    add_child_autoqfree(audio_mgr)
    assert_not_null(audio_mgr.bgm_player)
    assert_not_null(audio_mgr.sfx_player)

func test_player_controller_facing_and_attack():
    var player = PlayerController.new()
    add_child_autoqfree(player)
    watch_signals(player)

    assert_eq(player.facing_direction, Vector2.DOWN)
    player.input_vector = Vector2(1, 0) # Moving right
    player._physics_process(0.016)
    assert_eq(player.facing_direction, Vector2.RIGHT)

    player.perform_attack()
    assert_true(player.is_attacking)
    assert_signal_emitted_with_parameters(player, "attacked", [Vector2.RIGHT])

func test_player_controller_health_and_damage():
    var player = PlayerController.new()
    add_child_autoqfree(player)
    watch_signals(player)

    assert_eq(player.current_health, 3)
    player.take_damage(1)
    assert_eq(player.current_health, 2)
    assert_signal_emitted_with_parameters(player, "health_changed", [2, 3])
