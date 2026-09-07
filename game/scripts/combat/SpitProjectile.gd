extends Area3D

var velocity: Vector3 = Vector3.ZERO
var gravity: float = 22.0
var damage: int = 1
var lifetime: float = 5.0

func _ready() -> void:
	add_to_group("boss_projectiles")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func set_velocity(initial_vel: Vector3, grav: float = 22.0) -> void:
	velocity = initial_vel
	gravity = grav

func _physics_process(delta: float) -> void:
	velocity.y -= gravity * delta
	global_position += velocity * delta

	lifetime -= delta
	if lifetime <= 0.0 or global_position.y < -10.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body == self:
		return
	if body.is_in_group("boss") or body.is_in_group("enemies"):
		return

	if body.is_in_group("player"):
		if body.has_method("take_damage_from"):
			body.take_damage_from(damage, global_position)
		elif body.has_method("take_damage"):
			body.take_damage(damage)
		_spawn_impact_vfx()
		queue_free()
	else:
		_spawn_impact_vfx()
		queue_free()

func _on_area_entered(area: Area3D) -> void:
	if area.owner and area.owner.is_in_group("player"):
		var p = area.owner
		if p.has_method("take_damage_from"):
			p.take_damage_from(damage, global_position)
		elif p.has_method("take_damage"):
			p.take_damage(damage)
		_spawn_impact_vfx()
		queue_free()

func _spawn_impact_vfx() -> void:
	if not is_inside_tree() or get_parent() == null:
		return
	var p = CPUParticles3D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 12
	p.lifetime = 0.35
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 4.0
	p.global_position = global_position
	get_parent().add_child(p)
	var ptw = create_tween()
	if ptw:
		ptw.tween_interval(0.4)
		ptw.tween_callback(p.queue_free)
