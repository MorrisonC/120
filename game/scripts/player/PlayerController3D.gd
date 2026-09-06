extends CharacterBody3D

class_name PlayerController3D

signal stamina_changed(current: float, max_stamina: float)
signal state_changed(new_state: String)

enum State { IDLE, WALK, SPRINT, ATTACK, ROLL, HIT, DEAD }

@export var base_speed: float = 5.0
@export var sprint_multiplier: float = 1.6
@export var roll_speed: float = 12.0
@export var roll_duration: float = 0.35
@export var attack_duration: float = 0.25
@export var hit_stun_duration: float = 0.3
@export var max_stamina: float = 100.0
@export var stamina_drain: float = 35.0
@export var stamina_recovery: float = 25.0
@export var gravity: float = 24.0

var current_state: State = State.IDLE
var current_stamina: float = 100.0
var roll_timer: float = 0.0
var attack_timer: float = 0.0
var hit_timer: float = 0.0
var roll_direction: Vector3 = Vector3.FORWARD
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0
var footstep_timer: float = 0.0

var touch_input_vector: Vector2 = Vector2.ZERO

@onready var mesh_root: Node3D = $MeshRoot
@onready var attack_area: Area3D = $AttackPivot/AttackArea
@onready var interaction_area: Area3D = $InteractionArea
var anim_player: AnimationPlayer = null
@onready var slash_visual: Node3D = get_node_or_null("AttackPivot/SlashVisual")
@onready var spin_area: Area3D = get_node_or_null("SpinArea")
@onready var charge_particles: CPUParticles3D = get_node_or_null("ChargeParticles")

var attack_hold_time: float = 0.0
var is_charged: bool = false

var custom_game_state: Node = null
var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

var time_manager: Node:
	get:
		return get_node_or_null("/root/TimeManager")

func can_push_block() -> bool:
	if game_state != null:
		return game_state.capabilities.can_push
	return false

func get_effective_speed() -> float:
	var speed_mod = game_state.move_speed_modifier if game_state != null else 1.0
	return base_speed * speed_mod

func get_roll_stamina_cost() -> float:
	return 10.0 if (game_state != null and game_state.has_stamina_ring()) else 20.0

func _setup_animation_loops() -> void:
	if not anim_player:
		return
	for anim_name in anim_player.get_animation_list():
		var anim = anim_player.get_animation(anim_name)
		if anim:
			var lower = String(anim_name).to_lower()
			if "idle" in lower or "walk" in lower or "run" in lower or "flying" in lower:
				anim.loop_mode = Animation.LOOP_LINEAR

func _play_anim(anim_type: String, custom_blend: float = 0.12) -> void:
	if not anim_player:
		return

	var has_sword := true # Knight player model holds sword by default
	var target_anim := ""

	match anim_type.to_lower():
		"idle":
			if has_sword and anim_player.has_animation("HumanArmature|Idle_swordRight"):
				target_anim = "HumanArmature|Idle_swordRight"
			elif anim_player.has_animation("HumanArmature|Idle"):
				target_anim = "HumanArmature|Idle"
			elif anim_player.has_animation("idle"):
				target_anim = "idle"
		"walk":
			if anim_player.has_animation("HumanArmature|Walking"):
				target_anim = "HumanArmature|Walking"
			elif anim_player.has_animation("walk"):
				target_anim = "walk"
		"sprint", "run":
			if has_sword and anim_player.has_animation("HumanArmature|Run_swordRight"):
				target_anim = "HumanArmature|Run_swordRight"
			elif anim_player.has_animation("HumanArmature|Run"):
				target_anim = "HumanArmature|Run"
			elif anim_player.has_animation("run"):
				target_anim = "run"
		"attack":
			if anim_player.has_animation("HumanArmature|Run_swordAttack"):
				target_anim = "HumanArmature|Run_swordAttack"
			elif anim_player.has_animation("HumanArmature|swordAttackJump"):
				target_anim = "HumanArmature|swordAttackJump"
			elif anim_player.has_animation("attack"):
				target_anim = "attack"
		"roll", "dash":
			if has_sword and anim_player.has_animation("HumanArmature|Roll_sword"):
				target_anim = "HumanArmature|Roll_sword"
			elif anim_player.has_animation("HumanArmature|Roll"):
				target_anim = "HumanArmature|Roll"
			elif anim_player.has_animation("roll"):
				target_anim = "roll"
		"death", "dead":
			if anim_player.has_animation("HumanArmature|Death"):
				target_anim = "HumanArmature|Death"
			elif anim_player.has_animation("death"):
				target_anim = "death"

	if target_anim != "" and anim_player.current_animation != target_anim:
		anim_player.play(target_anim, custom_blend)

func _ready() -> void:
	anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	_setup_animation_loops()
	if anim_player:
		_play_anim("idle")
	current_stamina = max_stamina
	if game_state != null:
		game_state.player_respawned.connect(_on_player_respawned)
		game_state.health_changed.connect(_on_health_changed)

func _physics_process(delta: float) -> void:
	if invulnerability_timer > 0.0:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0.0:
			is_invulnerable = false
			_set_mesh_visibility(true)
		else:
			_set_mesh_visibility(int(invulnerability_timer * 20.0) % 2 == 0)

	match current_state:
		State.IDLE, State.WALK, State.SPRINT:
			_process_locomotion(delta)
		State.ATTACK:
			_process_attack(delta)
		State.ROLL:
			_process_roll(delta)
		State.HIT:
			_process_hit(delta)
		State.DEAD:
			velocity = Vector3.ZERO
			move_and_slide()

func _process_locomotion(delta: float) -> void:
	# Out-of-bounds fall protection safety net
	var current_zone = game_state.loop_state.get("current_zone", "") if game_state != null else ""
	if current_zone != "TheHollow" and global_position.y < -15.0:
		if game_state != null and game_state.has_method("respawn_player"):
			game_state.respawn_player()
			return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Input reading (Keyboard/Gamepad + Touch Virtual Joystick)
	var input_vec = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_vec.y -= 1.0
	if Input.is_action_pressed("move_backward"):
		input_vec.y += 1.0
	if Input.is_action_pressed("move_left"):
		input_vec.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_vec.x += 1.0

	if input_vec.length_squared() > 0.0:
		input_vec = input_vec.normalized()
	elif touch_input_vector.length_squared() > 0.0:
		input_vec = touch_input_vector

	# Handle attack holding & charging
	if Input.is_action_pressed("attack"):
		attack_hold_time += delta
		if attack_hold_time >= 0.35 and not is_charged:
			is_charged = true
			if charge_particles:
				charge_particles.emitting = true
			_play_sfx("waypoint_activate")

	if Input.is_action_just_released("attack"):
		var cost = 12.0 if (game_state != null and game_state.has_stamina_ring()) else 25.0
		if is_charged and current_stamina >= cost:
			_start_spin_attack()
		else:
			_start_attack()
		attack_hold_time = 0.0
		is_charged = false
		if charge_particles:
			charge_particles.emitting = false
		return

	# Handle roll/dash with Stamina Ring perk
	var can_dash = game_state != null and game_state.capabilities.can_dash
	var roll_cost = 10.0 if (game_state != null and game_state.has_stamina_ring()) else 20.0
	if Input.is_action_just_pressed("roll_dash") and can_dash and current_stamina >= roll_cost:
		_start_roll(input_vec)
		return

	# Handle sprint
	var wants_sprint = Input.is_action_pressed("sprint") and input_vec.length_squared() > 0.0 and current_stamina > 0.0
	var speed_mod = game_state.move_speed_modifier if game_state != null else 1.0
	var speed = base_speed * speed_mod

	if wants_sprint:
		speed *= sprint_multiplier
		var sprint_cost = stamina_drain * (0.6 if (game_state != null and game_state.has_stamina_ring()) else 1.0)
		current_stamina = max(0.0, current_stamina - sprint_cost * delta)
		_change_state(State.SPRINT)
	else:
		current_stamina = min(max_stamina, current_stamina + stamina_recovery * delta)
		if input_vec.length_squared() > 0.0:
			_change_state(State.WALK)
		else:
			_change_state(State.IDLE)

	stamina_changed.emit(current_stamina, max_stamina)

	# Movement calculation
	var move_dir = Vector3(input_vec.x, 0.0, input_vec.y).normalized()
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed

	if move_dir.length_squared() > 0.001:
		var target_angle = atan2(-move_dir.x, -move_dir.z)
		mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_angle, 15.0 * delta)
		$AttackPivot.rotation.y = mesh_root.rotation.y

	move_and_slide()

	# Surface footstep audio
	if move_dir.length_squared() > 0.001 and is_on_floor():
		var step_interval = 0.24 if wants_sprint else 0.38
		footstep_timer += delta
		if footstep_timer >= step_interval:
			footstep_timer = 0.0
			_play_footstep()
	else:
		footstep_timer = 0.0

	# Interaction check
	if Input.is_action_just_pressed("interact"):
		_try_interact()

func _start_attack() -> void:
	_change_state(State.ATTACK)
	attack_timer = attack_duration
	velocity.x = 0.0
	velocity.z = 0.0
	_play_sfx("sword_swing")
	_play_anim("attack", 0.05)
		
	# Show slash visual arc
	if slash_visual:
		slash_visual.visible = true
		slash_visual.scale = Vector3(0.6, 1.0, 0.6)
		slash_visual.rotation.y = -0.5
		var tw = create_tween()
		tw.tween_property(slash_visual, "scale", Vector3(1.3, 1.0, 1.3), 0.12)
		tw.parallel().tween_property(slash_visual, "rotation:y", 0.8, 0.15)
		tw.tween_callback(func(): slash_visual.visible = false)

	# Check targets in attack area
	var hit_connected := false
	var targets = attack_area.get_overlapping_bodies()
	for b in targets:
		if b == self:
			continue
		if b.has_method("take_hit"):
			b.take_hit(1, global_position)
			_play_sfx("hit")
			hit_connected = true

	var areas = attack_area.get_overlapping_areas()
	for a in areas:
		if a.has_method("on_sliced"):
			a.on_sliced()
		if a.has_method("take_hit"):
			a.take_hit(1, global_position)
			hit_connected = true

	if hit_connected:
		_apply_hit_stop(0.06)

func _start_spin_attack() -> void:
	_change_state(State.ATTACK)
	attack_timer = attack_duration * 1.3
	velocity.x = 0.0
	velocity.z = 0.0

	var cost = 12.0 if (game_state != null and game_state.has_stamina_ring()) else 25.0
	current_stamina = max(0.0, current_stamina - cost)
	stamina_changed.emit(current_stamina, max_stamina)

	_play_sfx("sword_swing")

	# Screen shake
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.4)

	# 360 spin animation / mesh rotation
	if mesh_root:
		var tw = create_tween()
		tw.tween_property(mesh_root, "rotation:y", mesh_root.rotation.y + TAU, 0.25)

	# Show slash visual in full spin
	if slash_visual:
		slash_visual.visible = true
		slash_visual.scale = Vector3(1.6, 1.0, 1.6)
		var stw = create_tween()
		stw.tween_property(slash_visual, "rotation:y", slash_visual.rotation.y + TAU, 0.25)
		stw.tween_callback(func(): slash_visual.visible = false)

	# Hit all targets in spin radius
	if spin_area:
		var bodies = spin_area.get_overlapping_bodies()
		for b in bodies:
			if b == self:
				continue
			if b.has_method("take_hit"):
				b.take_hit(2, global_position)
				_play_sfx("hit")
		var areas = spin_area.get_overlapping_areas()
		for a in areas:
			if a.has_method("take_hit"):
				a.take_hit(2, global_position)

func _process_attack(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0.0:
		_change_state(State.IDLE)

func _start_roll(input_vec: Vector2) -> void:
	_change_state(State.ROLL)
	var roll_cost = 10.0 if (game_state != null and game_state.has_stamina_ring()) else 20.0
	current_stamina -= roll_cost
	stamina_changed.emit(current_stamina, max_stamina)
	roll_timer = roll_duration
	is_invulnerable = true
	invulnerability_timer = roll_duration
	
	if input_vec.length_squared() > 0.01:
		roll_direction = Vector3(input_vec.x, 0.0, input_vec.y).normalized()
	else:
		roll_direction = -mesh_root.global_transform.basis.z.normalized()

func _process_roll(delta: float) -> void:
	roll_timer -= delta
	velocity.x = roll_direction.x * roll_speed
	velocity.z = roll_direction.z * roll_speed
	move_and_slide()
	if roll_timer <= 0.0:
		_change_state(State.IDLE)

func _process_hit(delta: float) -> void:
	hit_timer -= delta
	move_and_slide()
	if hit_timer <= 0.0:
		_change_state(State.IDLE)

func take_damage_from(amount: int, source_pos: Vector3) -> void:
	if is_invulnerable or current_state == State.DEAD:
		return
	
	is_invulnerable = true
	invulnerability_timer = 0.8
	_change_state(State.HIT)
	hit_timer = hit_stun_duration
	
	var knockback_dir = (global_position - source_pos).normalized()
	knockback_dir.y = 0.0
	velocity = knockback_dir * 8.0
	
	_play_sfx("hit")
	if game_state != null:
		game_state.take_damage(amount)

func _try_interact() -> void:
	var areas = interaction_area.get_overlapping_areas()
	for a in areas:
		if a.has_method("interact"):
			a.interact(self)
			return
			
	var bodies = interaction_area.get_overlapping_bodies()
	for b in bodies:
		if b.has_method("interact"):
			b.interact(self)
			return

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	var state_name = State.keys()[current_state]
	state_changed.emit(state_name)

	match current_state:
		State.IDLE:
			_play_anim("idle")
		State.WALK:
			_play_anim("walk")
		State.SPRINT:
			_play_anim("sprint")
		State.ROLL:
			_play_anim("roll")
		State.ATTACK:
			_play_anim("attack")
		State.DEAD:
			_play_anim("death")

func _set_mesh_visibility(visible_flag: bool) -> void:
	if mesh_root:
		mesh_root.visible = visible_flag

func _on_health_changed(current: int, _max_hp: int) -> void:
	if current <= 0 and current_state != State.DEAD:
		_change_state(State.DEAD)
		_play_sfx("loop_expired")

func _on_player_respawned(spawn_pos: Vector3) -> void:
	global_position = spawn_pos
	velocity = Vector3.ZERO
	current_stamina = max_stamina
	is_invulnerable = false
	invulnerability_timer = 0.0
	_set_mesh_visibility(true)
	_change_state(State.IDLE)

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)

func _play_footstep() -> void:
	var sound = "footstep_grass"
	if is_inside_tree():
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.2, global_position + Vector3.DOWN * 1.5)
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if result and result.has("collider") and result["collider"] != null:
			var col = result["collider"]
			if col.is_in_group("stone") or global_position.x > 40.0:
				sound = "footstep_stone"
			elif col.is_in_group("wood"):
				sound = "footstep_wood"
			elif col.is_in_group("carpet"):
				sound = "footstep_carpet"
			elif col.is_in_group("grass"):
				sound = "footstep_grass"
			elif global_position.x > 40.0:
				sound = "footstep_stone"
		elif global_position.x > 40.0:
			sound = "footstep_stone"
	_play_sfx(sound)

func _apply_hit_stop(duration: float = 0.06) -> void:
	if not is_inside_tree():
		return
	Engine.time_scale = 0.05
	var tree = get_tree()
	if tree:
		var timer = tree.create_timer(duration, true, false, true)
		timer.timeout.connect(func(): Engine.time_scale = 1.0)
