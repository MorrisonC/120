@tool
extends McpTestSuite

func suite_name() -> String:
	return "first_boss"

func test_burrow_state_disables_hurtbox() -> void:
	var boss_scene = preload("res://scenes/enemies/Boss.tscn")
	var boss = track(boss_scene.instantiate()) as BossController
	boss._ready()

	boss.change_state(BossController.State.BURROW)
	assert_false(boss.hurt_box.monitoring, "Hurtbox must not be monitoring during burrow (invulnerable)")
	assert_false(boss.hit_box.monitoring, "Hitbox must not be monitoring during underground travel")

func test_enrage_threshold_at_half_health() -> void:
	var boss_scene = preload("res://scenes/enemies/Boss.tscn")
	var boss = track(boss_scene.instantiate()) as BossController
	boss._ready()

	assert_false(boss.is_enraged, "Boss must start non-enraged")

	# Apply damage to reach 50% max health
	var half_hp = int(boss.max_health * 0.5)
	boss.take_damage(boss.max_health - half_hp)

	assert_true(boss.is_enraged, "Boss must become enraged when health drops to <= 50%")

func test_spit_projectile_trajectory_and_spawning() -> void:
	var proj_scene = preload("res://scenes/enemies/SpitProjectile.tscn")
	var proj = track(proj_scene.instantiate())
	proj._ready()

	assert_true(proj.is_in_group("boss_projectiles"), "SpitProjectile must be in group 'boss_projectiles'")

	proj.set_velocity(Vector3(10.0, 15.0, 0.0), 22.0)
	assert_eq(proj.velocity.y, 15.0, "Initial Y velocity must match set velocity")

	proj._physics_process(0.1)
	assert_gt(15.0, proj.velocity.y, "Gravity must reduce Y velocity over physics frame")

func test_loop_expired_resets_boss_state() -> void:
	var boss_scene = preload("res://scenes/enemies/Boss.tscn")
	var boss = track(boss_scene.instantiate()) as BossController
	boss._ready()

	boss.take_damage(5)
	assert_ne(boss.current_health, boss.max_health, "Boss health should decrease after damage")

	boss._on_loop_expired()
	assert_eq(boss.current_health, boss.max_health, "Boss health must reset to full on 120s loop expiration")
	assert_eq(boss.current_state, BossController.State.IDLE, "Boss state must reset to IDLE on loop expiration")
