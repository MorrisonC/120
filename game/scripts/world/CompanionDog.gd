extends Node3D

func _ready() -> void:
	var anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player:
		if anim_player.has_animation("AnimalArmature|Idle"):
			anim_player.play("AnimalArmature|Idle")
		elif anim_player.has_animation("AnimalArmature|Idle_2"):
			anim_player.play("AnimalArmature|Idle_2")
