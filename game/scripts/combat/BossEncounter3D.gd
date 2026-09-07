extends "res://scripts/combat/EnemyBase3D.gd"

class_name BossEncounter3D

signal boss_defeated

@export var boss_id: String = "boss_ashen_ruins"
@export var arena_camera_path: NodePath
@export var boss_door_path: NodePath

var phase: int = 1
var attack_cooldown: float = 2.0
var is_targetable: bool = false
var is_vulnerable: bool = false

var custom_game_state: Node = null
var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

func _ready() -> void:
	max_health = 6
	current_health = 6
	move_speed = 2.8
	detection_radius = 20.0
	attack_reach = 2.5
	telegraph_duration = 0.8
	attack_damage = 2
	is_targetable = false
	is_vulnerable = false

	super._ready()

	if game_state != null and game_state.is_boss_cleared(boss_id):
		_on_already_cleared()

func _process_ai(delta: float) -> void:
	if current_health <= 0:
		return
	
	attack_cooldown -= delta
	super._process_ai(delta)

func _start_telegraph() -> void:
	is_targetable = true
	is_vulnerable = true
	super._start_telegraph()

func _execute_attack() -> void:
	super._execute_attack()
	is_targetable = false
	is_vulnerable = false
	attack_cooldown = 1.8

func take_damage(amount: int, _knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if not is_targetable:
		_play_sfx("hit")
		return
	super.take_damage(amount)

func take_hit(damage: int, source_pos: Vector3) -> void:
	if not is_targetable:
		_play_sfx("hit")
		return
	super.take_hit(damage, source_pos)

func _on_loop_expired() -> void:
	current_health = max_health
	is_targetable = false
	is_vulnerable = false
	is_telegraphing = false
	global_position = spawn_position
	visible = true
	set_physics_process(true)
	collision_layer = 4

func _on_defeated() -> void:
	super._on_defeated()
	if game_state != null:
		game_state.clear_boss(boss_id)
	boss_defeated.emit()
	
	if get_tree() and get_tree().root:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("show_banner"):
			hud.show_banner("Boss Defeated! Ashen Guardian Banished.")

	if not boss_door_path.is_empty():
		var door = get_node_or_null(boss_door_path)
		if door and door.has_method("set_gate_open"):
			door.set_gate_open(true)

	if get_tree() and get_tree().root:
		var main_cam = get_tree().root.find_child("OrbitCamera", true, false)
		if main_cam and main_cam.has_method("set_room_override"):
			main_cam.set_room_override(null)

func _on_already_cleared() -> void:
	visible = false
	collision_layer = 0
	set_physics_process(false)
	if not boss_door_path.is_empty():
		var door = get_node_or_null(boss_door_path)
		if door and door.has_method("set_gate_open"):
			door.set_gate_open(true, false)
