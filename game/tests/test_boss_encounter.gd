@tool
extends McpTestSuite

func suite_name() -> String:
	return "boss_encounter"

func test_ashen_boss_vulnerable_only_during_telegraph_window() -> void:
	var boss = preload("res://scripts/combat/BossEncounter3D.gd").new()
	assert_false(boss.is_targetable, "Boss must start invulnerable/spectral outside attack window")
	
	# Attack when outside telegraph window should be deflected
	var hp_before = boss.current_health
	boss.take_damage(1)
	assert_eq(boss.current_health, hp_before, "Boss must not take damage when not telegraphing")
	
	# Trigger telegraph attack window
	boss._start_telegraph()
	assert_true(boss.is_targetable, "Boss must become targetable during telegraphed attack window")
	assert_true(boss.is_vulnerable, "Boss must become vulnerable during telegraph")
	
	# Attack inside telegraph window must deal damage
	boss.take_damage(2)
	assert_eq(boss.current_health, hp_before - 2, "Boss must take damage during telegraphed attack window")
	
	# Executing attack closes the vulnerability window
	boss._execute_attack()
	assert_false(boss.is_targetable, "Boss must return to invulnerable state after attack executes")
	boss.free()

func test_ashen_boss_timer_never_paused_during_encounter() -> void:
	var tm = preload("res://scripts/core/TimeManager.gd").new()
	tm.start_loop()
	assert_true(tm.is_loop_running(), "Loop must be running")
	
	# During boss fight, time must continue ticking with no exemption
	tm.deduct_time(2.0)
	assert_eq(tm.get_remaining_time(), 118.0, "TimeManager must continue counting down during boss fight")
	assert_true(tm.is_loop_running(), "Loop must never be paused during boss encounter (GDD §7)")
	tm.free()

func test_boss_loop_state_resets_on_loop_expiration_while_run_state_persists() -> void:
	var gs = preload("res://scripts/core/GameState.gd").new()
	var boss = preload("res://scripts/combat/BossEncounter3D.gd").new()
	
	# Simulate player unlocking a persistent shortcut and damaging boss
	gs.open_shortcut("shortcut_gate_ruins")
	boss.current_health = 2
	boss.is_targetable = true
	
	# Simulate loop reset / death
	boss._on_loop_expired()
	gs.reset_loop_state()
	
	# Boss resets to full health and untargetable
	assert_eq(boss.current_health, boss.max_health, "Boss health must reset to full on loop expiration")
	assert_false(boss.is_targetable, "Boss must reset to default untargetable state")
	
	# Persistent run_state shortcut remains unlocked
	assert_true(gs.is_shortcut_open("shortcut_gate_ruins"), "Pre-boss persistent shortcut must survive loop reset")
	boss.free()
	gs.free()
