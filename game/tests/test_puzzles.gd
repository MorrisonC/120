@tool
extends McpTestSuite

func suite_name() -> String:
	return "puzzles"

func test_push_block_requires_coffee_strength() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	var block = preload("res://scripts/puzzles/PushBlock3D.gd").new()
	block.initial_position = Vector3(0, 0, 0)
	block.target_position = Vector3(0, 0, 0)
	block.game_state = gs
	
	# Without coffee, pushing fails
	assert_false(gs.capabilities.can_push, "Push capability should be false initially")
	var pushed = block.push(Vector3.FORWARD)
	assert_false(pushed, "Should not be able to push block without Coffee strength")
	
	# With coffee, pushing succeeds
	gs.add_item("Coffee")
	assert_true(gs.capabilities.can_push, "Push capability must be active with Coffee")
	pushed = block.push(Vector3.FORWARD)
	assert_true(pushed, "Should be able to push block with Coffee capability")
	
	block.free()
	gs.free()

func test_pressure_plate_activates_gate() -> void:
	var plate = preload("res://scripts/puzzles/PressurePlate3D.gd").new()
	var gate = preload("res://scripts/puzzles/ShortcutGate3D.gd").new()
	
	assert_false(plate.is_pressed, "Pressure plate starts unpressed")
	assert_false(gate.is_open, "Gate starts closed")
	
	# Trigger press
	plate.occupying_bodies = 0
	plate._on_body_entered(null)
	assert_true(plate.is_pressed, "Pressure plate must be pressed when body enters")
	
	# Manually link gate open
	gate.set_gate_open(true, false)
	assert_true(gate.is_open, "Gate must open when triggered")
	
	# Trigger release
	plate._on_body_exited(null)
	assert_false(plate.is_pressed, "Pressure plate must release when body exits")
	
	plate.free()
	gate.free()

func test_pushed_block_state_resets_on_loop() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs.loop_state.pushed_blocks["block_ruins_1"] = Vector3(10, 0, 5)
	assert_true(gs.loop_state.pushed_blocks.has("block_ruins_1"), "Temporary block state registered")
	
	# Reset loop
	gs.reset_loop_state()
	assert_false(gs.loop_state.pushed_blocks.has("block_ruins_1"), "Temporary block positions must be wiped on loop reset")
	gs.free()

func test_shortcut_gate_persists_across_loops() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs.open_shortcut("shortcut_ruins_crypt")
	assert_true(gs.is_shortcut_open("shortcut_ruins_crypt"), "Shortcut should be open in run_state")
	
	# Reset loop
	gs.reset_loop_state()
	assert_true(gs.is_shortcut_open("shortcut_ruins_crypt"), "Opened shortcut gate must persist across loops in run_state")
	gs.free()
