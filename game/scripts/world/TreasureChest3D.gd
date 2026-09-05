extends Area3D

class_name TreasureChest3D

signal chest_opened(chest_id: String)

@export var chest_id: String = "chest_village_stamina"
@export var reward_item_id: String = "StaminaRing"
@export var reward_display_name: String = "Ancient Stamina Ring (-50% Roll Stamina)"

var is_open: bool = false

@onready var lid_node: Node3D = find_child("ChestLid", true, false)
@onready var gold_light: OmniLight3D = get_node_or_null("GoldLight")
@onready var gold_particles: CPUParticles3D = get_node_or_null("GoldParticles")

var custom_game_state: Node = null
var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

func _ready() -> void:
	collision_layer = 16 # Interactable
	collision_mask = 0

	if game_state != null and game_state.has_method("has_chest_opened") and game_state.has_chest_opened(chest_id):
		_set_instantly_open()

func interact(player: Node3D) -> void:
	if is_open:
		return
	open_chest()

func open_chest() -> void:
	is_open = true
	if game_state != null and game_state.has_method("open_chest"):
		game_state.open_chest(chest_id)
		game_state.add_item(reward_item_id)

	chest_opened.emit(chest_id)

	# Animate lid swing open backwards
	if lid_node:
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(lid_node, "rotation_degrees:x", -95.0, 0.6)

	if gold_light:
		gold_light.visible = true
		var lt = create_tween()
		lt.tween_property(gold_light, "light_energy", 3.0, 0.4)

	if gold_particles:
		gold_particles.restart()
		gold_particles.emitting = true

	_play_sfx("waypoint_activate")

	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("show_banner"):
		hud.show_banner("Treasure Found: " + reward_display_name)

func _set_instantly_open() -> void:
	is_open = true
	if lid_node:
		lid_node.rotation_degrees.x = -95.0
	if gold_light:
		gold_light.visible = true
		gold_light.light_energy = 1.0

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)
