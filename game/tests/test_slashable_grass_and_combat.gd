extends "res://addons/gut/test.gd"

var grass_node
var player_node

func before_each():
    grass_node = load("res://SlashableGrass.gd").new()
    grass_node._ready()

    player_node = load("res://PlayerController.gd").new()
    player_node._ready()

func after_each():
    if is_instance_valid(grass_node):
        grass_node.free()
    if is_instance_valid(player_node):
        player_node.free()

func test_slashable_grass_destruction_on_hit():
    assert_false(grass_node.is_cut, "Grass tile should not initially be cut")
    var mock_area = Area2D.new()
    mock_area.name = "AttackHitbox"

    grass_node._on_area_entered(mock_area)
    assert_true(grass_node.is_cut, "Grass tile should be cut when entered by AttackHitbox")
    mock_area.free()

func test_sword_visual_spawn_on_attack():
    assert_not_null(player_node.sword_visual, "Player should have sword_visual node")
    assert_false(player_node.sword_visual.visible, "Sword visual should be hidden initially")

    player_node.perform_attack()
    assert_true(player_node.sword_visual.visible, "Sword visual should become visible on attack")
