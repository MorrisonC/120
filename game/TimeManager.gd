extends Node

signal second_ticked(remaining_time: float)
signal time_warning_entered
signal loop_expired

const MAX_TIME: float = 120.0
const WARNING_TIME: float = 15.0

var remaining_time: float = MAX_TIME
var is_running: bool = false
var _warning_emitted: bool = false
var ticks_elapsed: int = 0
var tick_rate: float = 1.0 / 60.0 # Standard 60 FPS tick rate
var _accumulator: float = 0.0

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS

func _physics_process(delta: float):
    if not is_running:
        return

    _accumulator += delta
    while _accumulator >= tick_rate:
        _tick(tick_rate)
        _accumulator -= tick_rate

func _tick(delta_tick: float):
    ticks_elapsed += 1
    remaining_time -= delta_tick
    emit_signal("second_ticked", remaining_time)

    if remaining_time <= WARNING_TIME and not _warning_emitted:
        _warning_emitted = true
        emit_signal("time_warning_entered")

    if remaining_time <= 0.0:
        remaining_time = 0.0
        is_running = false
        emit_signal("loop_expired")
        _on_loop_expired()

func start_loop():
    remaining_time = MAX_TIME
    is_running = true
    _warning_emitted = false
    ticks_elapsed = 0
    _accumulator = 0.0
    var tel = get_node_or_null("/root/TelemetryLogger")
    if is_instance_valid(tel):
        tel.log_event("loop_started", {"max_time": MAX_TIME})

func pause_loop():
    is_running = false

func resume_loop():
    if remaining_time > 0.0:
        is_running = true

func force_death(reason: String):
    is_running = false
    remaining_time = 0.0
    var tel = get_node_or_null("/root/TelemetryLogger")
    if is_instance_valid(tel):
        tel.log_event("player_death", {"cause": reason, "time_remaining": 0.0})
    emit_signal("loop_expired")
    _on_loop_expired()

func _on_loop_expired():
    if remaining_time <= 0.0:
        var tel = get_node_or_null("/root/TelemetryLogger")
        if is_instance_valid(tel):
            tel.log_event("loop_expired", {})
    var game_state = get_node_or_null("/root/GameState")
    if is_instance_valid(game_state) and game_state.has_method("respawn_player"):
        game_state.respawn_player()
