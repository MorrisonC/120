extends BossController

class_name MarshBoss

func _ready() -> void:
	boss_id = "boss_sunken_marsh"
	max_health = 12
	super._ready()

func is_surfaced() -> bool:
	return current_state != State.BURROW

func submerge() -> void:
	change_state(State.BURROW)

func resurface() -> void:
	change_state(State.EMERGE)

func _on_defeated() -> void:
	super._on_defeated()
	if get_tree() and get_tree().root:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("show_banner"):
			hud.show_banner("Bog Sovereign Slain! Marsh Waters Calmed.")
