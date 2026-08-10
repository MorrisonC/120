extends GutTest

var world_gen_script = preload("res://ProceduralWorldGenerator.gd")

func test_procedural_generation_100_seeds():
    var fails = 0
    for i in range(100):
        seed(i)
        var world_gen = world_gen_script.new()
        add_child(world_gen)

        # Use max 20 retries for each generation seed
        var success = world_gen.generate_valid_world(20)
        if not success:
            fails += 1
        else:
            var factory_last = world_gen._get_last_room_in_biome("factory")
            assert_true(world_gen.rooms.has(factory_last), "Factory should exist in seed " + str(i))

        world_gen.queue_free()

    assert_eq(fails, 0, "All 100 seeds should successfully generate a valid world without softlocks.")

func test_item_gated_solvability():
    seed(42)
    var world_gen = world_gen_script.new()
    add_child(world_gen)

    world_gen.generate_valid_world(20)

    var no_items_dist = world_gen.evaluate_solvability("village_0", [])
    var factory_last = world_gen._get_last_room_in_biome("factory")

    assert_eq(no_items_dist[factory_last], INF, "Cannot reach end of game without items")

    world_gen.queue_free()

func test_bicycle_speed_boost():
    seed(42)
    var world_gen = world_gen_script.new()
    add_child(world_gen)
    world_gen.generate_valid_world(20)

    var speed_sand = world_gen.get_speed_for_terrain(world_gen.Terrain.SAND, [])
    var speed_bike_sand = world_gen.get_speed_for_terrain(world_gen.Terrain.SAND, ["Bicycle"])

    assert_eq(speed_sand, 80.0, "Sand speed is 80")
    assert_eq(speed_bike_sand, 175.0, "Bike speed on sand is 175")

    world_gen.queue_free()
