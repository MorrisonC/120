extends Node

# Autoload: QuestManager

signal quest_updated(quest_id: String, stage: int)
signal world_state_changed(flag_name: String, value: bool)

var world_flags: Dictionary = {
	"bridge_lowered": false,
	"has_machete": false,
	"brambles_cleared": false,
	"shrine_alpha_lit": false,
	"has_lead_boots": false,
	"spire_gate_open": false
}

var active_quest_id: String = "quest_waterwheel"

func _ready() -> void:
	load_state()

func is_flag_set(flag: String) -> bool:
	return world_flags.get(flag, false)

func set_flag(flag: String, value: bool = true) -> void:
	world_flags[flag] = value
	emit_signal("world_state_changed", flag, value)
	save_state()

func save_state() -> void:
	var config = ConfigFile.new()
	for key in world_flags.keys():
		config.set_value("world_flags", key, world_flags[key])
	config.set_value("quests", "active_quest", active_quest_id)
	config.save("user://world_save.cfg")

func load_state() -> void:
	var config = ConfigFile.new()
	if config.load("user://world_save.cfg") == OK:
		for key in world_flags.keys():
			world_flags[key] = config.get_value("world_flags", key, world_flags[key])
		active_quest_id = config.get_value("quests", "active_quest", active_quest_id)
