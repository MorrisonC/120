extends Node

signal second_ticked(remaining_time: float)
signal time_warning_entered
signal loop_expired

const MAX_TIME: float = 120.0
const WARNING_TIME: float = 15.0

var remaining_time: float = MAX_TIME
var is_running: bool = false
var _warning_emitted: bool = false

func _ready():
    # Make sure this runs even if the game is paused conceptually
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float):
    if not is_running:
        return

    remaining_time -= delta
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
    TelemetryLogger.log_event("loop_started", {"max_time": MAX_TIME})

func pause_loop():
    is_running = false

func resume_loop():
    if remaining_time > 0.0:
        is_running = true

func force_death(reason: String):
    print("Player died: " + reason)
    is_running = false
    remaining_time = 0.0
    TelemetryLogger.log_event("player_death", {"cause": reason, "time_remaining": 0.0})
    emit_signal("loop_expired")
    _on_loop_expired()

func _on_loop_expired():
    if remaining_time <= 0.0:
        TelemetryLogger.log_event("loop_expired", {})
    if GameState != null and GameState.has_method("respawn_player"):
        GameState.respawn_player()
