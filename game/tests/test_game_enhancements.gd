@tool
extends McpTestSuite

func suite_name() -> String:
	return "game_enhancements"

func test_chest_interaction_and_stamina_ring() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	assert_false(gs.has_stamina_ring(), "Player should not start with stamina ring")
	assert_false(gs.has_chest_opened("chest_village_stamina"), "Chest should not be open yet")
	
	gs.open_chest("chest_village_stamina")
	gs.add_item("StaminaRing")
	
	assert_true(gs.has_chest_opened("chest_village_stamina"), "Chest must be marked open")
	assert_true(gs.has_stamina_ring(), "Player must have stamina ring capability")
	gs.free()

func test_coin_collection() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	assert_eq(gs.run_state.coins, 0, "Coins should start at 0")
	gs.add_coins(5)
	assert_eq(gs.run_state.coins, 5, "Coins should increment by 5")
	gs.free()

func test_breakable_pot_logic() -> void:
	var prop = preload("res://scripts/world/BreakableProp3D.gd").new()
	assert_false(prop.is_broken, "Pot must start intact")
	prop.take_hit(1, Vector3.ZERO)
	assert_true(prop.is_broken, "Pot must break on hit")
	prop.free()
