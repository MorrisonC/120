extends Node

# Autoload: GameState

static var instance = null

signal player_respawned(spawn_pos: Vector3)
signal bookmark_set(house_id: String, pos: Vector3)
signal waypoint_activated(waypoint_id: StringName)
signal item_collected(item_id: String)
signal health_changed(current: int, max_hp: int)
signal shortcut_opened(shortcut_id: String)
signal boss_cleared(boss_id: String)
signal hint_triggered(hint: String)

var run_state: Dictionary = {
	"unlocked_items": [],
	"bookmarked_house_id": "house_village_1",
	"bookmarked_position": Vector3(0.0, 1.0, 0.0),
	"activated_waypoints": [] as Array[StringName],
	"opened_shortcuts": [],
	"cleared_bosses": [],
	"max_health": 3,
	"heart_containers": 0,
	"coins": 0,
	"opened_chests": [],
	"discovered_zones": ["OverworldVillage"],
	"quests": {}
}

signal coin_collected(total_coins: int)
signal chest_opened(chest_id: String)
signal quest_advanced(quest_id: String, stage: int)

func get_quest_stage(quest_id: String) -> int:
	var q = run_state.get("quests", {})
	if q is Dictionary:
		return q.get(quest_id, 0)
	return 0

func advance_quest(quest_id: String, stage: int) -> void:
	if not run_state.has("quests") or not (run_state["quests"] is Dictionary):
		run_state["quests"] = {}
	run_state["quests"][quest_id] = stage
	quest_advanced.emit(quest_id, stage)

var loop_state: Dictionary = {}

var move_speed_modifier: float = 1.0
var capabilities: Dictionary = {
	"can_push": false,
	"has_light": false,
	"can_swim": false,
	"can_climb": false,
	"has_warmth": false,
	"can_dash": false,
	"has_sword": false
}

func _init() -> void:
	reset_loop_state()

func _ready() -> void:
	instance = self
	reset_loop_state()
	update_capabilities_from_items()

func reset_loop_state() -> void:
	loop_state = {
		"current_health": run_state.max_health,
		"current_zone": "OverworldVillage",
		"enemy_states": {},
		"pushed_blocks": {},
		"temp_switches": {},
		"stone_positions": {}
	}
	health_changed.emit(loop_state.current_health, run_state.max_health)

func update_capabilities_from_items() -> void:
	move_speed_modifier = 1.0
	capabilities.can_push = false
	capabilities.has_light = false
	capabilities.can_swim = false
	capabilities.can_climb = false
	capabilities.has_warmth = false
	capabilities.can_dash = false
	capabilities.has_sword = false

	for item in run_state.unlocked_items:
		match item:
			"Sword":
				capabilities.has_sword = true
			"Boots":
				move_speed_modifier = 1.35
			"Coffee":
				capabilities.can_push = true
			"Lantern":
				capabilities.has_light = true
			"Fins":
				capabilities.can_swim = true
			"Grapple":
				capabilities.can_climb = true
			"WarmCloak":
				capabilities.has_warmth = true
			"RollDash":
				capabilities.can_dash = true

func respawn_player() -> void:
	reset_loop_state()
	update_capabilities_from_items()
	var spawn_pos: Vector3 = run_state.bookmarked_position
	player_respawned.emit(spawn_pos)
	
	var tm = get_node_or_null("/root/TimeManager")
	if is_instance_valid(tm) and tm.has_method("start_loop"):
		tm.start_loop()

func set_bookmark(house_id: String, pos: Vector3) -> void:
	run_state.bookmarked_house_id = house_id
	run_state.bookmarked_position = pos
	bookmark_set.emit(house_id, pos)

func activate_waypoint(waypoint_id: StringName) -> void:
	if not waypoint_id in run_state.activated_waypoints:
		run_state.activated_waypoints.append(waypoint_id)
		waypoint_activated.emit(waypoint_id)

func is_waypoint_activated(waypoint_id: StringName) -> bool:
	return waypoint_id in run_state.activated_waypoints

func add_item(item_id: String) -> void:
	if not item_id in run_state.unlocked_items:
		run_state.unlocked_items.append(item_id)
		if item_id == "HeartContainer":
			run_state.heart_containers += 1
			run_state.max_health = min(6, run_state.max_health + 1)
			loop_state.current_health = run_state.max_health
			health_changed.emit(loop_state.current_health, run_state.max_health)
		update_capabilities_from_items()
		item_collected.emit(item_id)

func has_item(item_id: String) -> bool:
	return item_id in run_state.unlocked_items

func take_damage(amount: int = 1) -> void:
	loop_state.current_health = max(0, loop_state.current_health - amount)
	health_changed.emit(loop_state.current_health, run_state.max_health)
	if loop_state.current_health <= 0:
		var tm = get_node_or_null("/root/TimeManager")
		if is_instance_valid(tm) and tm.has_method("force_death"):
			tm.force_death("damage")

func heal(amount: int = 1) -> void:
	loop_state.current_health = min(run_state.max_health, loop_state.current_health + amount)
	health_changed.emit(loop_state.current_health, run_state.max_health)

func open_shortcut(shortcut_id: String) -> void:
	if not shortcut_id in run_state.opened_shortcuts:
		run_state.opened_shortcuts.append(shortcut_id)
		shortcut_opened.emit(shortcut_id)

func is_shortcut_open(shortcut_id: String) -> bool:
	return shortcut_id in run_state.opened_shortcuts

func clear_boss(boss_id: String) -> void:
	if not boss_id in run_state.cleared_bosses:
		run_state.cleared_bosses.append(boss_id)
		boss_cleared.emit(boss_id)

func is_boss_cleared(boss_id: String) -> bool:
	return boss_id in run_state.cleared_bosses

func trigger_hint(hint: String) -> void:
	hint_triggered.emit(hint)

func has_chest_opened(chest_id: String) -> bool:
	return chest_id in run_state.opened_chests

func open_chest(chest_id: String) -> void:
	if not chest_id in run_state.opened_chests:
		run_state.opened_chests.append(chest_id)
		chest_opened.emit(chest_id)

func add_coins(amount: int) -> void:
	run_state.coins += amount
	coin_collected.emit(run_state.coins)

func has_stamina_ring() -> bool:
	return has_item("StaminaRing")

