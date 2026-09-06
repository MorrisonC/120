extends Area3D

class_name NPC

@export var npc_name: String = "Elder Finn"
@export_multiline var hint_text: String = "The clock is always running, traveler. When the bell tolls at 100, your flesh will return to the House lantern, but your knowledge and treasures will endure."
@export var quest_id: String = ""
@export var dialogue_by_stage: Array = []

func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	_play_idle_animation()

func _play_idle_animation() -> void:
	var anim: AnimationPlayer = null
	anim = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if not anim and get_parent():
		anim = get_parent().find_child("AnimationPlayer", true, false) as AnimationPlayer
		
	if anim:
		var anim_list = anim.get_animation_list()
		for anim_name in ["HumanArmature|Idle", "AnimalArmature|Idle", "Idle", "idle", "Stand", "stand"]:
			if anim.has_animation(anim_name):
				var a = anim.get_animation(anim_name)
				if a:
					a.loop_mode = Animation.LOOP_LINEAR
				anim.play(anim_name)
				return
		if anim_list.size() > 0:
			var first = anim_list[0]
			var a = anim.get_animation(first)
			if a:
				a.loop_mode = Animation.LOOP_LINEAR
			anim.play(first)

func interact(_player: CharacterBody3D) -> void:
	var text_to_show = hint_text
	var gs = get_node_or_null("/root/GameState")
	if not quest_id.is_empty() and dialogue_by_stage.size() > 0 and gs != null:
		var stage = gs.get_quest_stage(quest_id)
		if stage < dialogue_by_stage.size():
			text_to_show = dialogue_by_stage[stage]
		else:
			text_to_show = dialogue_by_stage[-1]

	var hud = get_tree().root.find_child("HUD", true, false) if (get_tree() and get_tree().root) else null
	if hud and hud.has_method("show_dialogue"):
		hud.show_dialogue("[%s]:\n\"%s\"" % [npc_name, text_to_show])
	_play_sfx("warning_tick")

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)
