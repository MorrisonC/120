extends Area3D

class_name BreakableProp3D

signal prop_broken(prop_id: String)

@export var prop_id: String = "pot_1"
@export var health: int = 1
@export var drop_chance: float = 0.6 # 60% chance to drop loot
@export var required_item: String = ""
@export var shortcut_id: String = ""

var current_health: int = 1
var is_broken: bool = false
var spawn_pos: Vector3

@onready var visual_root: Node3D = $VisualRoot
@onready var static_col: CollisionShape3D = get_node_or_null("StaticBody3D/CollisionShape3D")
@onready var hit_col: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var break_particles: CPUParticles3D = get_node_or_null("BreakParticles")

var custom_game_state: Node = null

var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

func _ready() -> void:
	spawn_pos = global_position
	current_health = health
	collision_layer = 4 # Objects / Breakables (hittable by player attacks on layer 4)
	collision_mask = 2 # Detect player roll dash

	body_entered.connect(_on_body_entered)

	var tm = get_node_or_null("/root/TimeManager")
	if tm != null:
		tm.loop_expired.connect(_on_loop_expired)

	if not shortcut_id.is_empty() and game_state != null and game_state.is_shortcut_open(shortcut_id):
		is_broken = true
		if visual_root:
			visual_root.visible = false
		if static_col:
			static_col.set_deferred("disabled", true)
		if hit_col:
			hit_col.set_deferred("disabled", true)

func _on_body_entered(body: Node3D) -> void:
	# If player rolls into pot, smash it!
	if is_broken:
		return
	if body is CharacterBody3D and body.has_method("get") and body.get("current_state") == 3: # State.ROLL
		take_hit(1, body.global_position)

func take_hit(damage: int, source_pos: Vector3) -> void:
	if is_broken:
		return
	if not required_item.is_empty() and game_state != null and not game_state.has_item(required_item):
		_play_sfx("hit_metal")
		return
	current_health -= damage
	if current_health <= 0:
		break_prop()

func break_prop() -> void:
	is_broken = true
	prop_broken.emit(prop_id)

	if not shortcut_id.is_empty() and game_state != null:
		game_state.open_shortcut(shortcut_id)
		_play_sfx("shortcut")

	# Hide intact visual
	if visual_root:
		visual_root.visible = false

	# Disable collision
	if static_col:
		static_col.set_deferred("disabled", true)
	if hit_col:
		hit_col.set_deferred("disabled", true)

	# Particle burst
	if break_particles:
		break_particles.restart()
		break_particles.emitting = true

	# Play SFX
	_play_sfx("pot_break")

	# Screen shake
	var vp = get_viewport()
	if vp:
		var cam = vp.get_camera_3d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.2)

	# Roll drop
	if randf() <= drop_chance:
		_spawn_drop()

func _spawn_drop() -> void:
	if randf() > 0.4 and game_state != null:
		var cur_hp = game_state.loop_state.get("current_health", 3)
		var max_hp = game_state.run_state.get("max_health", 3)
		if cur_hp < max_hp:
			_spawn_pickup_heart()
		else:
			_spawn_pickup_coin()
	else:
		_spawn_pickup_coin()

func _spawn_pickup_coin() -> void:
	if game_state != null and game_state.has_method("add_coins"):
		game_state.add_coins(1)
		if get_tree() and get_tree().root:
			var hud = get_tree().root.find_child("HUD", true, false)
			if hud and hud.has_method("show_banner"):
				hud.show_banner("+1 Gold Coin!")

func _spawn_pickup_heart() -> void:
	if game_state != null and game_state.has_method("heal"):
		game_state.heal(1)
		if get_tree() and get_tree().root:
			var hud = get_tree().root.find_child("HUD", true, false)
			if hud and hud.has_method("show_banner"):
				hud.show_banner("+1 Heart Restored!")

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)

func _on_loop_expired() -> void:
	# Respawn on time loop
	is_broken = false
	current_health = health
	if visual_root:
		visual_root.visible = true
	if static_col:
		static_col.set_deferred("disabled", false)
	if hit_col:
		hit_col.set_deferred("disabled", false)
