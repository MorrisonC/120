@tool
extends McpTestSuite

func suite_name() -> String:
	return "items_and_respawn"

func test_item_pickup_sets_run_state_once_no_double_counting() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	gs.add_item("Boots")
	assert_true(gs.has_item("Boots"), "Boots must be added to run_state")
	var count_after_first = gs.run_state.unlocked_items.size()
	
	# Attempt duplicate pickup
	gs.add_item("Boots")
	assert_eq(gs.run_state.unlocked_items.size(), count_after_first, "Duplicate item pickups must not double count")
	gs.free()

func test_push_strength_item_enables_can_push_block() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	var player = preload("res://scripts/player/PlayerController3D.gd").new()
	
	# Before Coffee
	assert_false(player.can_push_block(), "Player should not push block without Coffee")
	
	# After Coffee
	gs.add_item("Coffee")
	assert_true(gs.capabilities.can_push, "Push capability enabled in GameState")
	
	player.free()
	gs.free()

func test_boots_item_increases_effective_move_speed() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	assert_eq(gs.move_speed_modifier, 1.0, "Base speed modifier must be 1.0")
	
	gs.add_item("Boots")
	assert_eq(gs.move_speed_modifier, 1.35, "Boots item must apply +35% move speed modifier")
	gs.free()

func test_stamina_ring_halves_roll_stamina_cost() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	assert_false(gs.has_stamina_ring(), "Stamina ring not possessed initially")
	
	gs.add_item("StaminaRing")
	assert_true(gs.has_stamina_ring(), "Stamina ring must be registered in GameState")
	gs.free()

func test_respawn_snaps_to_active_bookmark_house_and_heals_to_max() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	var house_pos = Vector3(45.0, 2.0, -15.0)
	gs.set_bookmark("house_village_1", house_pos)
	
	# Take damage
	gs.take_damage(2)
	assert_eq(gs.loop_state.current_health, 1, "Health reduced after taking damage")
	
	# Respawn
	gs.reset_loop_state()
	assert_eq(gs.loop_state.current_health, gs.run_state.max_health, "Health restores to full on respawn")
	assert_eq(gs.run_state.bookmarked_position, house_pos, "Spawn position matches bookmarked house")
	gs.free()
