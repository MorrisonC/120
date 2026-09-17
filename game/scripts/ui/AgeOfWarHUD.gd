extends CanvasLayer

@onready var gold_label: Label = $TopBar/HBox/GoldLabel
@onready var xp_label: Label = $TopBar/HBox/XPLabel
@onready var era_label: Label = $TopBar/HBox/EraLabel
@onready var player_hp_bar: ProgressBar = $TopBar/HBox/PlayerHPBar
@onready var enemy_hp_bar: ProgressBar = $TopBar/HBox/EnemyHPBar

@onready var unit_container: HBoxContainer = $BottomControls/VBox/UnitContainer
@onready var turret_container: HBoxContainer = $BottomControls/VBox/TurretContainer
@onready var evolve_button: Button = $SideControls/EvolveButton
@onready var special_button: Button = $SideControls/SpecialButton

func _ready() -> void:
	AgeOfWarState.gold_changed.connect(_on_gold_changed)
	AgeOfWarState.xp_changed.connect(_on_xp_changed)
	AgeOfWarState.era_changed.connect(_on_era_changed)
	AgeOfWarState.player_base_hp_changed.connect(_on_player_hp_changed)
	AgeOfWarState.enemy_base_hp_changed.connect(_on_enemy_hp_changed)
	AgeOfWarState.special_cooldown_changed.connect(_on_special_cd_changed)

	_update_ui_for_current_era()
	_update_top_bar()

	evolve_button.pressed.connect(_on_evolve_pressed)
	special_button.pressed.connect(_on_special_pressed)

func _update_top_bar() -> void:
	gold_label.text = "Gold: " + str(AgeOfWarState.player_gold)
	xp_label.text = "XP: " + str(AgeOfWarState.player_xp)
	era_label.text = AgeOfWarState.ERA_NAMES[AgeOfWarState.player_era]

func _update_ui_for_current_era() -> void:
	_update_top_bar()

	# Clear previous unit buttons
	for child in unit_container.get_children():
		child.queue_free()

	# Populate unit spawn buttons for current era
	var current_units = AgeOfWarState.ERA_UNITS[AgeOfWarState.player_era]
	for u_dict in current_units:
		var btn = Button.new()
		btn.text = u_dict["name"] + "\n(" + str(u_dict["cost"]) + "g)"
		btn.custom_minimum_size = Vector2(110, 50)
		btn.pressed.connect(func(): _on_unit_btn_pressed(u_dict))
		unit_container.add_child(btn)

	# Clear previous turret buttons
	for child in turret_container.get_children():
		child.queue_free()

	# Populate turret buttons for current era
	var current_turrets = AgeOfWarState.ERA_TURRETS[AgeOfWarState.player_era]
	for idx in range(current_turrets.size()):
		var t_dict = current_turrets[idx]
		var btn = Button.new()
		btn.text = "Build: " + t_dict["name"] + "\n(" + str(t_dict["cost"]) + "g)"
		btn.custom_minimum_size = Vector2(140, 50)
		btn.pressed.connect(func(): _on_turret_btn_pressed(idx, t_dict))
		turret_container.add_child(btn)

	# Update Evolve button state
	var req_xp = AgeOfWarState.ERA_EVOLVE_COSTS[AgeOfWarState.player_era]
	if req_xp > 0:
		evolve_button.text = "EVOLVE AGE\n(" + str(req_xp) + " XP)"
		evolve_button.disabled = not AgeOfWarState.can_evolve_player()
	else:
		evolve_button.text = "MAX ERA"
		evolve_button.disabled = true

func _on_unit_btn_pressed(u_dict: Dictionary) -> void:
	var main_node = get_tree().current_scene
	if main_node and main_node.has_method("spawn_player_unit"):
		main_node.spawn_player_unit(u_dict)

func _on_turret_btn_pressed(slot_idx: int, t_dict: Dictionary) -> void:
	var main_node = get_tree().current_scene
	if main_node and main_node.has_method("build_player_turret"):
		main_node.build_player_turret(slot_idx, t_dict)

func _on_evolve_pressed() -> void:
	if AgeOfWarState.evolve_player():
		_update_ui_for_current_era()

func _on_special_pressed() -> void:
	var main_node = get_tree().current_scene
	if main_node and main_node.has_method("trigger_player_special"):
		main_node.trigger_player_special()

func _on_gold_changed(new_gold: int) -> void:
	gold_label.text = "Gold: " + str(new_gold)

func _on_xp_changed(new_xp: int) -> void:
	xp_label.text = "XP: " + str(new_xp)
	evolve_button.disabled = not AgeOfWarState.can_evolve_player()

func _on_era_changed(is_player: bool, _new_era: int) -> void:
	if is_player:
		_update_ui_for_current_era()

func _on_player_hp_changed(current: float, max_hp: float) -> void:
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = current

func _on_enemy_hp_changed(current: float, max_hp: float) -> void:
	enemy_hp_bar.max_value = max_hp
	enemy_hp_bar.value = current

func _on_special_cd_changed(is_player: bool, remaining: float, _max_cd: float) -> void:
	if is_player:
		if remaining > 0.0:
			special_button.text = "SPECIAL\n(" + str(int(ceil(remaining))) + "s)"
			special_button.disabled = true
		else:
			special_button.text = "SPECIAL ATTACK"
			special_button.disabled = false
