extends Node3D
class_name RuinsEnvironment

var world_env: WorldEnvironment
var dir_light: DirectionalLight3D

func _ready() -> void:
	_setup_environment()
	_setup_lighting()

func _setup_environment() -> void:
	world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1A1D24") # Dark Slate
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#D8DCE6")
	env.ambient_light_energy = 0.45
	world_env.environment = env
	add_child(world_env)

func _setup_lighting() -> void:
	dir_light = DirectionalLight3D.new()
	dir_light.light_color = Color("#FFF3E0") # Warm rim light
	dir_light.light_energy = 0.8
	dir_light.shadow_enabled = true
	dir_light.rotation_degrees = Vector3(-45, 30, 0)
	add_child(dir_light)

func add_brazier_light(pos: Vector3) -> Light3D:
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 0.8, 0)
	light.light_color = Color("#FFA726") # Warm brazier orange
	light.light_energy = 1.2
	light.omni_range = 6.0
	add_child(light)

	# Subtle flicker animation
	var tween := create_tween().set_loops()
	tween.tween_property(light, "light_energy", 1.4, 0.2 + randf() * 0.1)
	tween.tween_property(light, "light_energy", 1.0, 0.2 + randf() * 0.1)

	return light
