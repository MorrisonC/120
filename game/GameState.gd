extends Node

signal hint_triggered(hint_text: String)

var loop_state: Dictionary = {}
var checkpoint_death_counts: Dictionary = {}
var triggered_hints: Dictionary = {}
var run_state: Dictionary = {
    "unlocked_key_items": [],
    "unlocked_shortcuts": [],
    "discovered_spawns": [],
    "cleared_puzzle_bitmask": 0
}

var active_spawn_point: Vector2 = Vector2.ZERO

var move_speed_modifier: float = 1.0
var terrain_capabilities: Dictionary = {
    "can_swim": false,
    "can_dig": false,
    "has_light": false,
    "can_cut_vines": false
}

func _ready():
    reset_loop_state()

func reset_loop_state():
    loop_state = {
        "enemy_positions": {},
        "pushed_blocks": {},
        "temp_levers": {}
    }

func update_capabilities_from_items():
    # Base speeds
    move_speed_modifier = 1.0
    terrain_capabilities.can_swim = false
    terrain_capabilities.can_dig = false
    terrain_capabilities.has_light = false
    terrain_capabilities.can_cut_vines = false

    for item in run_state.unlocked_key_items:
        match item:
            "Bicycle":
                move_speed_modifier = 1.75
            "Shovel":
                terrain_capabilities.can_dig = true
            "Flippers":
                terrain_capabilities.can_swim = true
            "Shears":
                terrain_capabilities.can_cut_vines = true
            "Lantern":
                terrain_capabilities.has_light = true

func respawn_player():
    reset_loop_state()
    update_capabilities_from_items()
    if TimeManager != null and TimeManager.has_method("start_loop"):
        TimeManager.start_loop()

func set_active_spawn_point(pos: Vector2, spawn_id: String):
    active_spawn_point = pos
    active_checkpoint_id = spawn_id
    if not spawn_id in run_state.discovered_spawns:
        run_state.discovered_spawns.append(spawn_id)
        TelemetryLogger.log_event("checkpoint_reached", {"id": spawn_id})

var active_checkpoint_id: String = ""

func record_checkpoint_death(checkpoint_id: String):
    if not checkpoint_death_counts.has(checkpoint_id):
        checkpoint_death_counts[checkpoint_id] = 0
    checkpoint_death_counts[checkpoint_id] += 1

    if checkpoint_death_counts[checkpoint_id] >= 2 and not triggered_hints.has(checkpoint_id):
        triggered_hints[checkpoint_id] = true
        var hint = "Hint: Search nearby rooms for tools before advancing through blocked paths."
        emit_signal("hint_triggered", hint)

func add_key_item(item_id: String):
    if not item_id in run_state.unlocked_key_items:
        run_state.unlocked_key_items.append(item_id)
        update_capabilities_from_items()
        TelemetryLogger.log_event("item_collected", {"id": item_id})

func run_completed(total_time: float, deaths: int):
    TelemetryLogger.log_event("run_completed", {"total_time": total_time, "deaths": deaths})

func run_abandoned(reason: String):
    TelemetryLogger.log_event("run_abandoned", {"reason": reason})
