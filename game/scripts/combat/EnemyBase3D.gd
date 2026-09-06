extends CharacterBody3D

class_name EnemyBase3D

signal enemy_defeated

@export var max_health: int = 1
@export var move_speed: float = 3.2
@export var detection_radius: float = 8.0
@export var attack_reach: float = 1.6
@export var telegraph_duration: float = 0.5
@export var attack_damage: int = 1

var current_health: int = 1
var spawn_position: Vector3 = Vector3.ZERO
var target_player: CharacterBody3D = null
var is_telegraphing: bool = false
var telegraph_timer: float = 0.0
var hit_stun_timer: float = 0.0

@onready var mesh_root: Node3D = $MeshRoot
@onready var telegraph_light: OmniLight3D = $TelegraphLight

var anim_player: AnimationPlayer = null

func _setup_animation_loops() -> void:
	if not anim_player:
		return
	for anim_name in anim_player.get_animation_list():
		var anim = anim_player.get_animation(anim_name)
		if anim:
			var lower = String(anim_name).to_lower()
			if "idle" in lower or "walk" in lower or "run" in lower or "flying" in lower or "gallop" in lower:
				anim.loop_mode = Animation.LOOP_LINEAR

func play_anim(anim_type: String, custom_blend: float = 0.15) -> void:
	if not anim_player:
		return
	var target_anim = _find_best_anim_name(anim_type)
	if target_anim != "" and anim_player.current_animation != target_anim:
		anim_player.play(target_anim, custom_blend)

func _find_best_anim_name(anim_type: String, visited: Array = []) -> String:
	if not anim_player:
		return ""
	var list = anim_player.get_animation_list()
	if list.size() == 0:
		return ""

	var lower_type = anim_type.to_lower()
	if lower_type in visited:
		return String(list[0])
	visited.append(lower_type)

	var matches = []
	for anim_name in list:
		var lower_name = String(anim_name).to_lower()
		if lower_type in lower_name:
			matches.append(String(anim_name))

	if matches.size() > 0:
		for m in matches:
			if "armature" in m.to_lower() or "human" in m.to_lower() or "rat" in m.to_lower() or "spider" in m.to_lower() or "frog" in m.to_lower() or "wasp" in m.to_lower():
				return m
		return matches[0]

	# Fallbacks based on type
	if lower_type == "walk":
		return _find_best_anim_name("run", visited)
	elif lower_type == "run":
		return _find_best_anim_name("walk", visited)
	elif lower_type == "attack":
		return _find_best_anim_name("jump", visited)

	return String(list[0])

func _ready() -> void:
	spawn_position = global_position
	current_health = max_health
	collision_layer = 4 # Enemies / Objects
	collision_mask = 3 # Environment + Player

	anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	_setup_animation_loops()
	play_anim("idle")

	var tm = get_node_or_null("/root/TimeManager")
	if tm != null:
		tm.loop_expired.connect(_on_loop_expired)

func _physics_process(delta: float) -> void:
	if hit_stun_timer > 0.0:
		hit_stun_timer -= delta
		move_and_slide()
		return

	if is_telegraphing:
		telegraph_timer -= delta
		velocity = Vector3.ZERO
		_update_telegraph_visuals()
		if telegraph_timer <= 0.0:
			_execute_attack()
		move_and_slide()
		return

	_process_ai(delta)

func _process_ai(delta: float) -> void:
	if not is_instance_valid(target_player):
		_find_player()

	if is_instance_valid(target_player):
		var dist = global_position.distance_to(target_player.global_position)
		if dist <= attack_reach:
			_start_telegraph()
			return
		elif dist <= detection_radius:
			var dir = (target_player.global_position - global_position).normalized()
			dir.y = 0.0
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed

			var target_angle = atan2(-dir.x, -dir.z)
			mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_angle, 10.0 * delta)
			play_anim("run")
			move_and_slide()
			return

	if velocity.length_squared() > 0.01:
		play_anim("walk")
	else:
		play_anim("idle")
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _start_telegraph() -> void:
	is_telegraphing = true
	telegraph_timer = telegraph_duration
	play_anim("attack", 0.05)
	if telegraph_light:
		telegraph_light.visible = true
		telegraph_light.light_energy = 2.0

func _update_telegraph_visuals() -> void:
	if telegraph_light:
		telegraph_light.light_energy = 1.0 + (1.0 - (telegraph_timer / telegraph_duration)) * 4.0

func _execute_attack() -> void:
	is_telegraphing = false
	if telegraph_light:
		telegraph_light.visible = false

	if is_instance_valid(target_player):
		var dist = global_position.distance_to(target_player.global_position)
		if dist <= attack_reach + 0.5:
			if target_player.has_method("take_damage_from"):
				target_player.take_damage_from(attack_damage, global_position)

func take_hit(damage: int, source_pos: Vector3) -> void:
	current_health -= damage
	hit_stun_timer = 0.25
	play_anim("jump") # Hit reaction jump/twitch
	
	var knockback = (global_position - source_pos).normalized()
	knockback.y = 0.0
	velocity = knockback * 6.5
	
	# Visceral screen shake
	var vp = get_viewport()
	if vp:
		var cam = vp.get_camera_3d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.28)

	# Impact squish & recovery
	if is_inside_tree() and mesh_root:
		var tw = create_tween()
		if tw:
			tw.tween_property(mesh_root, "scale", Vector3(1.2, 0.8, 1.2), 0.05)
			tw.tween_property(mesh_root, "scale", Vector3.ONE, 0.1)

	_play_sfx("hit")

	# Impact flash particles
	if is_inside_tree() and get_parent():
		var p = CPUParticles3D.new()
		p.emitting = true
		p.one_shot = true
		p.explosiveness = 0.95
		p.amount = 10
		p.lifetime = 0.25
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.3
		p.initial_velocity_min = 2.0
		p.initial_velocity_max = 5.0
		p.global_position = global_position + Vector3.UP * 0.8
		get_parent().add_child(p)
		var ptw = create_tween()
		if ptw:
			ptw.tween_interval(0.3)
			ptw.tween_callback(p.queue_free)
	
	if current_health <= 0:
		enemy_defeated.emit()
		_on_defeated()

func take_damage(amount: int) -> void:
	take_hit(amount, global_position)

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)

func _on_defeated() -> void:
	collision_layer = 0
	set_physics_process(false)
	var death_anim = _find_best_anim_name("death")
	if death_anim != "" and anim_player:
		anim_player.play(death_anim, 0.1)
		var tw = create_tween()
		tw.tween_interval(1.2)
		tw.tween_callback(func(): visible = false)
	else:
		visible = false

func _on_loop_expired() -> void:
	# Reset state and position on each loop
	global_position = spawn_position
	current_health = max_health
	visible = true
	collision_layer = 4
	is_telegraphing = false
	telegraph_timer = 0.0
	hit_stun_timer = 0.0
	if telegraph_light:
		telegraph_light.visible = false
	set_physics_process(true)
