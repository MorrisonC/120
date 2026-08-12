extends GutTest

var generator: Node
var TelemetryLogger: Node

func before_all():
    TelemetryLogger = preload("res://TelemetryLogger.gd").new()
    add_child(TelemetryLogger)
    TelemetryLogger._ready()

func after_all():
    TelemetryLogger.queue_free()

func before_each():
    generator = preload("res://ProceduralWorldGenerator.gd").new()
    # Mock TelemetryLogger on ProceduralWorldGenerator to prevent null ref since we bypass Autoload in tests
    var tl = preload("res://TelemetryLogger.gd").new()
    add_child(tl)
    tl._ready()

    # In Godot we can't easily overwrite autoloads, so we'll just run it.
    # Godot should still trigger Autoloads if test is running as a full scene,
    # but since GUT headless might not, we should probably set up the autoload manually
    # if it doesn't exist, but it should be configured in project.godot.

    add_child_autoqfree(generator)

func test_bulk_simulation():
    var num_seeds = 100
    var successful_runs = 0
    var total_deaths = 0
    var total_time = 0.0

    var easy_nodes = 0
    var medium_nodes = 0
    var hard_nodes = 0
    var max_time = 120.0

    for i in range(num_seeds):
        seed(i)

        # 1. Generate World
        assert_true(generator.generate_valid_world(), "World should generate successfully for seed " + str(i))

        if not generator.rooms.has("factory_0"):
            continue # Could not find end, skip simulating this broken seed

        # Determine logical difficulty mapping (T_solve)
        # Using placeholder classification logic for difficulty since nodes aren't explicitly tagged in ProceduralWorldGenerator
        for room_id in generator.rooms:
            var room = generator.rooms[room_id]
            if room.obstacle == generator.Obstacle.NONE:
                easy_nodes += 1
            elif room.obstacle in [generator.Obstacle.VINES, generator.Obstacle.DIRT_MOUND]:
                medium_nodes += 1
            else:
                hard_nodes += 1

        # 2. Simulate AI Run (Logical Level)
        var remaining_time = max_time
        var deaths_this_run = 0
        var current_room = "village_0"
        var items_collected = []
        var run_time = 0.0

        var is_solvable = generator.verify_world() # We know it's solvable theoretically

        # Log telemetry for the simulation
        var tl = get_node("/root/TelemetryLogger") if has_node("/root/TelemetryLogger") else TelemetryLogger
        if tl:
            tl.log_event("run_started", {"seed": i})

        if is_solvable:
            successful_runs += 1
            if tl:
                tl.log_event("run_completed", {"seed": i, "deaths": 0, "total_time": 60.0}) # Placeholder stats
        else:
            total_deaths += 1
            if tl:
                tl.log_event("run_abandoned", {"seed": i, "reason": "unsolvable_in_time"})

    # Assert 0% soft-locks
    assert_eq(successful_runs, num_seeds, "All generated seeds must be fully solvable by the agent.")

    # Check difficulty distribution
    var total_nodes = easy_nodes + medium_nodes + hard_nodes
    if total_nodes > 0:
        var easy_ratio = float(easy_nodes) / total_nodes
        var hard_ratio = float(hard_nodes) / total_nodes

        # E.g. less than 50% hard nodes
        assert_lt(hard_ratio, 0.5, "Too many hard nodes! Rebalance difficulty.")


    # Save baseline stats
    var stats = {
        "completion_rate": float(successful_runs) / num_seeds,
        "avg_deaths": float(total_deaths) / num_seeds if num_seeds > 0 else 0,
        "seeds_tested": num_seeds
    }

    var dir = DirAccess.open("res://")
    if not dir.dir_exists("telemetry"):
        dir.make_dir("telemetry")

    var f = FileAccess.open("res://telemetry/baseline_stats.json", FileAccess.WRITE)
    f.store_string(JSON.stringify(stats, "\t"))
    f.close()
