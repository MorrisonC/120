extends "res://scripts/combat/BossEncounter3D.gd"

class_name MarshBoss

enum BossState {
	SURFACED,
	SUBMERGED,
	ATTACKING
}

var current_boss_state: BossState = BossState.SURFACED
var submerge_timer: float = 6.0
var surface_duration: float = 5.0
var submerge_duration: float = 3.0
var state_timer: float = 5.0

func _ready() -> void:
	boss_id = "boss_sunken_marsh"
	max_health = 8
	current_health = 8
	move_speed = 3.2
	attack_reach = 3.0
	attack_damage = 2
	super._ready()
	resurface()

func _process_ai(delta: float) -> void:
	if current_health <= 0:
		return
		
	state_timer -= delta
	if state_timer <= 0:
		if current_boss_state == BossState.SURFACED:
			submerge()
		elif current_boss_state == BossState.SUBMERGED:
			resurface()
			
	if current_boss_state == BossState.SURFACED:
		super._process_ai(delta)

func submerge() -> void:
	current_boss_state = BossState.SUBMERGED
	is_targetable = false
	is_vulnerable = false
	state_timer = submerge_duration
	_play_sfx("splash")
	# Visually submerge
	var visual = find_child("VisualRoot", true, false)
	if not visual:
		visual = find_child("MeshRoot", true, false)
	if visual:
		visual.position.y = -2.0

func resurface() -> void:
	current_boss_state = BossState.SURFACED
	is_targetable = true
	is_vulnerable = true
	state_timer = surface_duration
	_play_sfx("splash")
	var visual = find_child("VisualRoot", true, false)
	if not visual:
		visual = find_child("MeshRoot", true, false)
	if visual:
		visual.position.y = 0.0

func is_surfaced() -> bool:
	return current_boss_state == BossState.SURFACED

func _on_defeated() -> void:
	super._on_defeated()
	if get_tree() and get_tree().root:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("show_banner"):
			hud.show_banner("Bog Sovereign Slain! Marsh Waters Calmed.")
