extends GutTest

var procedural_generator_script = preload("res://ProceduralWorldGenerator.gd")
var generator: Node

func before_each():
    generator = procedural_generator_script.new()
    add_child(generator)

func after_each():
    generator.queue_free()

func test_generation_variety_across_seeds():
    # Generate world with seed 1
    seed(1)
    assert_true(generator.generate_valid_world(), "Should generate valid world for seed 1")
    var world1_edges = generator.rooms["village_0"].edges.keys().duplicate()
    var world1_items = {}
    for room_id in generator.rooms:
        if generator.rooms[room_id].item_contained != "":
            world1_items[room_id] = generator.rooms[room_id].item_contained

    # Generate world with seed 2
    seed(2)
    assert_true(generator.generate_valid_world(), "Should generate valid world for seed 2")
    var world2_edges = generator.rooms["village_0"].edges.keys().duplicate()
    var world2_items = {}
    for room_id in generator.rooms:
        if generator.rooms[room_id].item_contained != "":
            world2_items[room_id] = generator.rooms[room_id].item_contained

    # Verify that the outputs are meaningfully different
    # Note: Since the graph is highly random, it's very unlikely these will be identical
    # We check if item locations differ between seeds
    var items_differ = false
    for k in world1_items:
        if not world2_items.has(k) or world2_items[k] != world1_items[k]:
            items_differ = true
            break

    if not items_differ:
        for k in world2_items:
            if not world1_items.has(k):
                items_differ = true
                break

    assert_true(items_differ, "Item placements should differ across seeds indicating variety")

func test_solver_verifies_solvability():
    seed(42)
    assert_true(generator.generate_valid_world(), "Generator must produce a verified solvable world")
    assert_true(generator.verify_world(), "verify_world must return true for a valid world")
