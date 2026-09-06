extends Node3D

var anim_player: AnimationPlayer = null

func _ready() -> void:
	anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player:
		for anim_name in anim_player.get_animation_list():
			var anim = anim_player.get_animation(anim_name)
			if anim:
				var lower = String(anim_name).to_lower()
				if "idle" in lower or "walk" in lower or "gallop" in lower:
					anim.loop_mode = Animation.LOOP_LINEAR

		if anim_player.has_animation("AnimalArmature|Idle"):
			anim_player.play("AnimalArmature|Idle")
		elif anim_player.has_animation("AnimalArmature|Idle_2"):
			anim_player.play("AnimalArmature|Idle_2")

func play_anim(anim_type: String, custom_blend: float = 0.15) -> void:
	if not anim_player:
		return
	var matches = []
	var lower_type = anim_type.to_lower()
	for anim_name in anim_player.get_animation_list():
		if lower_type in String(anim_name).to_lower():
			matches.append(String(anim_name))
	if matches.size() > 0 and anim_player.current_animation != matches[0]:
		anim_player.play(matches[0], custom_blend)
