class_name Projectile3D
extends CharacterBody3D

var target_position: Vector3
var damage: float = 10.0
var speed: float = 18.0
var is_player_owned: bool = true
var target_unit = null

func setup(p_target_pos: Vector3, p_damage: float, p_is_player: bool, p_target_unit = null) -> void:
	target_position = p_target_pos
	damage = p_damage
	is_player_owned = p_is_player
	target_unit = p_target_unit

func _ready() -> void:
	# Add visual representation mesh if empty
	if get_child_count() == 0:
		var mesh_inst = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.2
		sphere.height = 0.4
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0.8, 0.2) if is_player_owned else Color(1, 0.2, 0.2)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		sphere.material = mat
		mesh_inst.mesh = sphere
		add_child(mesh_inst)

func _physics_process(delta: float) -> void:
	if is_instance_valid(target_unit):
		target_position = target_unit.global_position + Vector3(0, 0.5, 0)

	var dir = (target_position - global_position)
	if dir.length() < 0.5:
		_on_hit()
		return

	velocity = dir.normalized() * speed
	move_and_slide()

func _on_hit() -> void:
	if is_instance_valid(target_unit) and target_unit.has_method("take_damage"):
		target_unit.take_damage(damage)
	queue_free()
