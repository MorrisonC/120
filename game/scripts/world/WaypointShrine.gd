extends StaticBody3D

class_name WaypointShrine

@export var waypoint_id: StringName = &"waypoint_village"
@export var display_name: String = "Village Waypoint Shrine"

var is_activated: bool = false

@onready var crystal_light: OmniLight3D = $CrystalLight
@onready var crystal_mesh: MeshInstance3D = $CrystalMesh
@onready var activate_particles: CPUParticles3D = $ActivateParticles
@onready var interact_area: Area3D = $InteractArea

var custom_game_state: Node = null
var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

func _ready() -> void:
	if game_state != null and game_state.is_waypoint_activated(waypoint_id):
		_apply_activated_visuals(false)
	else:
		_apply_dim_visuals()

func interact(_player: CharacterBody3D) -> void:
	if is_activated:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("open_fast_travel_menu"):
			hud.open_fast_travel_menu()
		return
	
	is_activated = true
	if game_state != null:
		game_state.activate_waypoint(waypoint_id)
	_play_sfx("waypoint")
	_apply_activated_visuals(true)
	
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("show_banner"):
		hud.show_banner("Waypoint Activated: " + display_name)

func _apply_dim_visuals() -> void:
	is_activated = false
	if crystal_light:
		crystal_light.light_energy = 0.5
		crystal_light.light_color = Color(0.2, 0.4, 0.8)
	if crystal_mesh and crystal_mesh.material_override is StandardMaterial3D:
		var mat = crystal_mesh.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = 0.5

func _apply_activated_visuals(burst: bool) -> void:
	is_activated = true
	if crystal_light:
		crystal_light.light_energy = 3.0
		crystal_light.light_color = Color(0.2, 0.9, 1.0)
	if crystal_mesh and crystal_mesh.material_override is StandardMaterial3D:
		var mat = crystal_mesh.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = 3.5
	if burst and activate_particles:
		activate_particles.emitting = true

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)
