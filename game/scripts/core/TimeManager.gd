extends Node

# Autoload: TimeManager

static var instance = null

signal second_ticked(remaining_time: float)
signal time_warning_entered
signal loop_expired
signal loop_started(max_time: float)
signal loop_reset_completed

const MAX_TIME: float = 120.0
const WARNING_TIME: float = 20.0

var remaining_time: float = MAX_TIME
var is_running: bool = false
var _warning_emitted: bool = false
var ticks_elapsed: int = 0
var tick_rate: float = 1.0 / 60.0
var _accumulator: float = 0.0

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS

func _physics_process(delta: float) -> void:
	if not is_running:
		return

	_accumulator += delta
	while _accumulator >= tick_rate:
		_tick(tick_rate)
		_accumulator -= tick_rate

func _tick(delta_tick: float) -> void:
	ticks_elapsed += 1
	remaining_time -= delta_tick
	second_ticked.emit(remaining_time)

	if remaining_time <= WARNING_TIME and not _warning_emitted:
		_warning_emitted = true
		time_warning_entered.emit()

	if remaining_time <= 0.0:
		remaining_time = 0.0
		is_running = false
		loop_expired.emit()
		_on_loop_expired()

func start_loop() -> void:
	remaining_time = MAX_TIME
	is_running = true
	_warning_emitted = false
	ticks_elapsed = 0
	_accumulator = 0.0
	loop_started.emit(MAX_TIME)

func pause_loop() -> void:
	is_running = false

func resume_loop() -> void:
	if remaining_time > 0.0:
		is_running = true

func deduct_time(seconds: float) -> void:
	remaining_time = max(0.0, remaining_time - seconds)
	second_ticked.emit(remaining_time)
	if remaining_time <= WARNING_TIME and not _warning_emitted:
		_warning_emitted = true
		time_warning_entered.emit()
	if remaining_time <= 0.0:
		remaining_time = 0.0
		is_running = false
		loop_expired.emit()
		_on_loop_expired()

func force_death(reason: String = "manual") -> void:
	is_running = false
	remaining_time = 0.0
	loop_expired.emit()
	_on_loop_expired()

func get_remaining_time() -> float:
	return remaining_time

func is_loop_running() -> bool:
	return is_running

func _on_loop_expired() -> void:
	if is_inside_tree():
		var game_state = get_node_or_null("/root/GameState")
		if is_instance_valid(game_state) and game_state.has_method("respawn_player"):
			game_state.respawn_player()
	loop_reset_completed.emit()
