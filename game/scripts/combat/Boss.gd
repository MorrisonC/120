class_name BossController
extends CharacterBody3D

signal boss_defeated

enum State { IDLE, CRAWL, TURN_HOP, BURROW, EMERGE, SPIT, DEAD }

@export var boss_id: String = "boss_sunken_marsh"
@export var max_health: int = 12
@export var crawl_speed: float = 4.5
@export var burrow_speed: float = 6.5
@export var gravity: float = 18.0
@export var projectile_scene: PackedScene

var current_health: int
var current_state: State = State.IDLE
var target_player: CharacterBody3D = null
var is_enraged: bool = false
var spawn_position: Vector3 = Vector3.ZERO

var is_vulnerable: bool:
	get:
		return current_state != State.BURROW and current_state != State.DEAD

# Internal action counters & helpers
var hop_target_rot: float = 0.0
var spit_count: int = 0

@onready var visuals: Node3D = $Visuals
@onready var state_timer: Timer = $Timers/StateTimer
@onready var hit_box: Area3D = $Combat/HitBox
@onready var hurt_box: Area3D = $Combat/HurtBox
@onready var spawn_point: Marker3D = $ProjectileSpawnPoint

var anim_player: AnimationPlayer = null
var trail_particles: CPUParticles3D = null
var burrow_particles: CPUParticles3D = null
var erupt_particles: CPUParticles3D = null

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	spawn_position = global_position
	current_health = max_health

	if not projectile_scene:
		projectile_scene = load("res://scenes/enemies/SpitProjectile.tscn")

	anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	trail_particles = find_child("TrailParticles", true, false) as CPUParticles3D
	burrow_particles = find_child("BurrowParticles", true, false) as CPUParticles3D
	erupt_particles = find_child("EruptParticles", true, false) as CPUParticles3D

	if state_timer and not state_timer.timeout.is_connected(_on_state_timer_timeout):
		state_timer.timeout.connect(_on_state_timer_timeout)

	if hurt_box and not hurt_box.area_entered.is_connected(_on_hurt_box_area_entered):
		hurt_box.area_entered.connect(_on_hurt_box_area_entered)

	if hit_box and not hit_box.body_entered.is_connected(_on_hit_box_body_entered):
		hit_box.body_entered.connect(_on_hit_box_body_entered)

	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.loop_expired.connect(_on_loop_expired)

	_find_player()
	change_state(State.IDLE)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player") if get_tree() else []
	if players.size() > 0:
		target_player = players[0]

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_player):
		_find_player()

	# Apply standard gravity when not underground
	if current_state != State.BURROW:
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

		State.CRAWL:
			_process_crawl(delta)

		State.TURN_HOP:
			_process_turn_hop(delta)

		State.BURROW:
			_process_burrow(delta)

	move_and_slide()

func change_state(new_state: State) -> void:
	current_state = new_state
	if state_timer:
		state_timer.stop()

	match new_state:
		State.IDLE:
			if trail_particles: trail_particles.emitting = false
			if burrow_particles: burrow_particles.emitting = false
			if hit_box: hit_box.monitoring = false
			if hurt_box: hurt_box.monitoring = true
			if visuals: visuals.visible = true
			_play_anim("idle")
			if state_timer: state_timer.start(randf_range(1.2, 2.0))

		State.CRAWL:
			if trail_particles: trail_particles.emitting = true
			if burrow_particles: burrow_particles.emitting = false
			if hit_box: hit_box.monitoring = true
			if hurt_box: hurt_box.monitoring = true
			if visuals: visuals.visible = true
			_play_anim("crawl")
			if state_timer: state_timer.start(randf_range(2.5, 3.5))

		State.TURN_HOP:
			if trail_particles: trail_particles.emitting = false
			if burrow_particles: burrow_particles.emitting = false
			if hit_box: hit_box.monitoring = true
			if hurt_box: hurt_box.monitoring = true
			if visuals: visuals.visible = true
			velocity.y = 7.5 # Jump impulse
			if target_player:
				var dir: Vector3 = (target_player.global_position - global_position)
				dir.y = 0.0
				if dir.length_squared() > 0.01:
					hop_target_rot = atan2(-dir.x, -dir.z)
			_play_anim("jump")

		State.BURROW:
			if hit_box: hit_box.monitoring = false
			if hurt_box: hurt_box.monitoring = false # Invulnerable underground
			if trail_particles: trail_particles.emitting = false
			if burrow_particles: burrow_particles.emitting = true
			if visuals: visuals.visible = false
			if state_timer: state_timer.start(randf_range(2.0, 3.0))

		State.EMERGE:
			if burrow_particles: burrow_particles.emitting = false
			if erupt_particles: erupt_particles.restart()
			if visuals: visuals.visible = true
			if hurt_box: hurt_box.monitoring = true
			if hit_box: hit_box.monitoring = true
			velocity.y = 9.0 # Burst eruption
			_play_anim("emerge")
			_schedule_emerge_recovery()

		State.SPIT:
			velocity = Vector3.ZERO
			if hit_box: hit_box.monitoring = false
			if hurt_box: hurt_box.monitoring = true
			if visuals: visuals.visible = true
			_play_anim("spit")
			_execute_spit_sequence()

		State.DEAD:
			if trail_particles: trail_particles.emitting = false
			if burrow_particles: burrow_particles.emitting = false
			if hit_box: hit_box.monitoring = false
			if hurt_box: hurt_box.monitoring = false
			_play_anim("die")
			emit_signal("boss_defeated")
			_on_defeated()

func _schedule_emerge_recovery() -> void:
	if is_inside_tree():
		var tw = create_tween()
		if tw:
			tw.tween_interval(0.6)
			tw.tween_callback(func():
				if current_state == State.EMERGE:
					if hit_box: hit_box.monitoring = false
					change_state(State.SPIT)
			)

func _process_crawl(delta: float) -> void:
	if not target_player:
		return
	var active_speed = crawl_speed * (1.25 if is_enraged else 1.0)
	var dir = (target_player.global_position - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		velocity.x = dir.x * active_speed
		velocity.z = dir.z * active_speed
		var target_angle = atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 8.0 * delta)

func _process_turn_hop(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, hop_target_rot, 8.0 * delta)
	if is_on_floor() and velocity.y <= 0.0:
		if hit_box: hit_box.monitoring = false
		change_state(State.IDLE)

func _process_burrow(delta: float) -> void:
	if not target_player:
		return
	var active_speed = burrow_speed * (1.25 if is_enraged else 1.0)
	var dir = (target_player.global_position - global_position)
	dir.y = 0.0
	if dir.length() > 0.5:
		var norm = dir.normalized()
		velocity.x = norm.x * active_speed
		velocity.z = norm.z * active_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func _execute_spit_sequence() -> void:
	spit_count = 2 if is_enraged else 1
	for i in range(spit_count):
		if target_player and is_instance_valid(target_player):
			_spawn_lobbed_projectile(target_player.global_position)
		if spit_count > 1 and i == 0 and is_inside_tree():
			await get_tree().create_timer(0.4).timeout

	if is_inside_tree():
		await get_tree().create_timer(0.8).timeout
		if current_state == State.SPIT:
			change_state(State.IDLE)

func _on_spit_release_frame() -> void:
	_spawn_lobbed_projectile(target_player.global_position if target_player else global_position + -transform.basis.z * 5.0)

func _spawn_lobbed_projectile(target_pos: Vector3) -> void:
	if not projectile_scene or not is_inside_tree():
		return
	var proj = projectile_scene.instantiate() as Area3D
	if not proj:
		return

	var parent_node = get_parent() if get_parent() else self
	parent_node.add_child(proj)
	var launch_origin = spawn_point.global_position if spawn_point else global_position + Vector3.UP * 1.5
	proj.global_position = launch_origin

	var displacement = target_pos - launch_origin
	var gravity_mag: float = 22.0
	var flight_time: float = 0.95

	var vx = displacement.x / flight_time
	var vz = displacement.z / flight_time
	var vy = (displacement.y / flight_time) + (0.5 * gravity_mag * flight_time)

	if proj.has_method("set_velocity"):
		proj.set_velocity(Vector3(vx, vy, vz), gravity_mag)

func _on_state_timer_timeout() -> void:
	match current_state:
		State.IDLE:
			_choose_next_attack()
		State.CRAWL:
			if _is_player_behind():
				change_state(State.TURN_HOP)
			else:
				change_state(State.IDLE)
		State.BURROW:
			change_state(State.EMERGE)

func _choose_next_attack() -> void:
	if _is_player_behind():
		change_state(State.TURN_HOP)
		return

	var roll = randf()
	if roll < 0.4:
		change_state(State.CRAWL)
	elif roll < 0.75:
		change_state(State.BURROW)
	else:
		change_state(State.SPIT)

func _is_player_behind() -> bool:
	if not target_player:
		return false
	var to_player = (target_player.global_position - global_position).normalized()
	to_player.y = 0.0
	var forward = -transform.basis.z
	return forward.dot(to_player) < 0.2

func take_damage(amount: int) -> void:
	if current_state == State.BURROW or current_state == State.DEAD:
		return # Invulnerable while submerged or dead

	current_health = clampi(current_health - amount, 0, max_health)

	if not is_enraged and current_health <= int(max_health * 0.5):
		is_enraged = true

	if current_health <= 0:
		change_state(State.DEAD)

func take_hit(damage: int, _source_pos: Vector3) -> void:
	take_damage(damage)

func _play_anim(anim_name: String) -> void:
	if anim_player:
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name)
		else:
			var list = anim_player.get_animation_list()
			for a in list:
				if anim_name in String(a).to_lower():
					anim_player.play(a)
					return

func _on_hurt_box_area_entered(area: Area3D) -> void:
	if current_state == State.BURROW or current_state == State.DEAD:
		return
	if area.is_in_group("player_weapon") or area.name == "AttackArea":
		take_damage(1)

func _on_hit_box_body_entered(body: Node3D) -> void:
	if current_state == State.DEAD:
		return
	if body.is_in_group("player"):
		if body.has_method("take_damage_from"):
			body.take_damage_from(2, global_position)
		elif body.has_method("take_damage"):
			body.take_damage(2)

func _on_defeated() -> void:
	collision_layer = 0
	set_physics_process(false)
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("clear_boss"):
		gs.clear_boss(boss_id)

func _on_loop_expired() -> void:
	current_health = max_health
	is_enraged = false
	global_position = spawn_position
	visible = true
	collision_layer = 4
	set_physics_process(true)
	change_state(State.IDLE)
