extends Area3D

class_name NPC

@export var npc_name: String = "Elder Finn"
@export_multiline var hint_text: String = "The clock is always running, traveler. When the bell tolls at 100, your flesh will return to the House lantern, but your knowledge and treasures will endure."

func _ready() -> void:
	collision_layer = 16
	collision_mask = 0

func interact(_player: CharacterBody3D) -> void:
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("show_dialogue"):
		hud.show_dialogue("[%s]:\n\"%s\"" % [npc_name, hint_text])
	_play_sfx("warning_tick")

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)
