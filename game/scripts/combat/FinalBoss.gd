extends "res://scripts/combat/BossEncounter3D.gd"

class_name FinalBoss

enum FinalPhase {
	PHASE_TELEGRAPH,
	PHASE_SUBMERGE,
	PHASE_ARMORED
}

var current_boss_phase: FinalPhase = FinalPhase.PHASE_TELEGRAPH
var is_armored_phase: bool = false

func _ready() -> void:
	super._ready()
	boss_id = "boss_the_hollow"
	max_health = 12
	current_health = 12
	move_speed = 3.5
	attack_reach = 3.5
	attack_damage = 3
	set_phase(FinalPhase.PHASE_TELEGRAPH)

func set_phase(p: FinalPhase) -> void:
	current_boss_phase = p
	match p:
		FinalPhase.PHASE_TELEGRAPH:
			is_armored_phase = false
			is_targetable = true
			is_vulnerable = true
		FinalPhase.PHASE_SUBMERGE:
			is_armored_phase = false
			is_targetable = false
			is_vulnerable = false
		FinalPhase.PHASE_ARMORED:
			is_armored_phase = true
			is_targetable = true
			is_vulnerable = false

func take_damage(amount: int, _knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if current_boss_phase == FinalPhase.PHASE_SUBMERGE:
		_play_sfx("splash")
		return
	if is_armored_phase:
		_play_sfx("hit_metal")
		return
	super.take_damage(amount)
	_check_phase_transitions()

func take_hit(damage: int, source_pos: Vector3) -> void:
	if current_boss_phase == FinalPhase.PHASE_SUBMERGE:
		_play_sfx("splash")
		return
	if is_armored_phase:
		_play_sfx("hit_metal")
		return
	super.take_hit(damage, source_pos)
	_check_phase_transitions()

func _check_phase_transitions() -> void:
	if current_health <= 4 and current_boss_phase != FinalPhase.PHASE_ARMORED:
		set_phase(FinalPhase.PHASE_ARMORED)
	elif current_health <= 8 and current_health > 4 and current_boss_phase != FinalPhase.PHASE_SUBMERGE:
		set_phase(FinalPhase.PHASE_SUBMERGE)

func break_armor() -> void:
	is_armored_phase = false
	is_vulnerable = true
	_play_sfx("impact")

func _on_defeated() -> void:
	super._on_defeated()
	if get_tree() and get_tree().root:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("show_banner"):
			hud.show_banner("The Time-Core Restored! The Cycle is Broken!")
