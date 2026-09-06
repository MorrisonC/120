extends Area3D

class_name MasterKeyGate

signal gate_unlocked

@export var required_items: Array[String] = ["Sword", "Lantern", "Fins", "Grapple", "WarmCloak"]
@export var is_open: bool = false
@export var shortcut_id: String = "shortcut_master_gate"

var custom_game_state: Node = null
var game_state: Node:
	get:
		if custom_game_state != null:
			return custom_game_state
		return get_node_or_null("/root/GameState")
	set(value):
		custom_game_state = value

func _ready() -> void:
	collision_layer = 16 # Interaction
	collision_mask = 0
	if game_state != null and game_state.is_shortcut_open(shortcut_id):
		set_open(true, false)

func can_unlock(gs: Node = null) -> bool:
	var state = gs if gs != null else game_state
	if state == null:
		return false
	var items = state.run_state.get("unlocked_items", [])
	for req in required_items:
		if not req in items:
			return false
	return true

func try_unlock(gs: Node = null) -> bool:
	var state = gs if gs != null else game_state
	if can_unlock(state):
		set_open(true, true)
		if state != null:
			state.open_shortcut(shortcut_id)
		gate_unlocked.emit()
		return true
	return false

func interact(_player: CharacterBody3D) -> void:
	var state = game_state
	if is_open:
		return
	if try_unlock(state):
		if get_tree() and get_tree().root:
			var hud = get_tree().root.find_child("HUD", true, false)
			if hud and hud.has_method("show_banner"):
				hud.show_banner("The Five Relics resonate! The Sanctum Unseals.")
	else:
		if get_tree() and get_tree().root:
			var hud = get_tree().root.find_child("HUD", true, false)
			if hud and hud.has_method("show_dialogue"):
				hud.show_dialogue("[Ancient Seal]:\n\"Only the bearer of Sword, Lantern, Fins, Grapple, and WarmCloak may pass into The Hollow.\"")

func set_open(open: bool, _animate: bool = true) -> void:
	is_open = open
	var col = find_child("GateCollision", true, false)
	if col and col is CollisionShape3D:
		col.set_deferred("disabled", open)
	var visual = find_child("GateVisual", true, false)
	if visual:
		visual.visible = not open
