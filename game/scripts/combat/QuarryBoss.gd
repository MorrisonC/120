extends BossEncounter3D

class_name QuarryBoss

signal boulder_redirected

@export var is_armored: bool = true
var boulder_timer: float = 4.0

func _ready() -> void:
	boss_id = "boss_old_quarry"
	max_health = 6
	current_health = 6
	move_speed = 2.4
	attack_reach = 2.8
	attack_damage = 2
	is_armored = true
	super._ready()

func take_damage(amount: int, _knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if is_armored:
		_play_sfx("hit_metal") # Armored clank
		return
	super.take_damage(amount)

func take_hit(damage: int, source_pos: Vector3) -> void:
	if is_armored:
		_play_sfx("hit_metal")
		return
	super.take_hit(damage, source_pos)

func hit_by_boulder(is_grapple_redirected: bool) -> bool:
	if not is_grapple_redirected:
		_play_sfx("hit_metal")
		return false
	
	# Grapple redirect bypasses armor and crushes boss
	is_armored = false
	_play_sfx("impact")
	current_health = max(0, current_health - 2)
	boulder_redirected.emit()
	
	if current_health <= 0:
		_on_defeated()
	else:
		# Stunned briefly, then armor resets
		_start_armor_recovery()
	return true

func _start_armor_recovery() -> void:
	if get_tree():
		await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self) and current_health > 0:
		is_armored = true

func _on_defeated() -> void:
	super._on_defeated()
	if get_tree() and get_tree().root:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("show_banner"):
			hud.show_banner("Quarry Golem Shattered! Excavations Reopened.")
