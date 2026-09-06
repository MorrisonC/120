extends CanvasLayer

class_name HUD

@onready var heart_container: HBoxContainer = find_child("HeartContainer", true, false)
@onready var coin_label: Label = find_child("CoinLabel", true, false)
@onready var timer_label: Label = find_child("TimerLabel", true, false)
@onready var stamina_bar: ProgressBar = find_child("StaminaBar", true, false)
@onready var warning_vignette: ColorRect = find_child("WarningVignette", true, false)
@onready var banner_label: Label = find_child("BannerLabel", true, false)
@onready var banner_panel: Panel = find_child("BannerPanel", true, false)
@onready var items_container: HBoxContainer = find_child("ItemsContainer", true, false)
@onready var home_button: Button = find_child("HomeButton", true, false)
@onready var fast_travel_panel: Panel = find_child("FastTravelModal", true, false)
@onready var fast_travel_list: VBoxContainer = find_child("WaypointList", true, false)
@onready var dialogue_panel: Panel = find_child("DialogueModal", true, false)
@onready var dialogue_text: Label = find_child("DialogueText", true, false)

var touch_controls: TouchControls = null

var _banner_timer: float = 0.0
var _vignette_pulse: float = 0.0
var _home_key_down: bool = false

func _ready() -> void:
	var tm = get_node_or_null("/root/TimeManager")
	if tm != null:
		tm.second_ticked.connect(_on_second_ticked)
		tm.time_warning_entered.connect(_on_time_warning_entered)
		tm.loop_started.connect(_on_loop_started)
	
	var gs = get_node_or_null("/root/GameState")
	if gs != null:
		gs.health_changed.connect(_on_health_changed)
		gs.item_collected.connect(_on_item_collected)
		gs.bookmark_set.connect(_on_bookmark_set)
		gs.hint_triggered.connect(show_dialogue)
		gs.coin_collected.connect(_on_coin_collected)
		_update_hearts(gs.loop_state.current_health, gs.run_state.max_health)
		_update_items()
		_update_coins(gs.run_state.get("coins", 0))

	fast_travel_panel.visible = false
	dialogue_panel.visible = false
	banner_panel.visible = false
	warning_vignette.color.a = 0.0

	if home_button != null:
		home_button.pressed.connect(_on_home_button_pressed)

	# Instantiate TouchControls on web, mobile or touch environments
	_setup_touch_controls()

func _setup_touch_controls() -> void:
	var is_touch_device = OS.has_feature("web") or OS.has_feature("mobile") or DisplayServer.has_feature(DisplayServer.FEATURE_TOUCHSCREEN)
	if is_touch_device:
		var touch_script = load("res://scripts/ui/TouchControls.gd")
		if touch_script:
			touch_controls = touch_script.new()
			touch_controls.name = "TouchControls"
			touch_controls.joystick_moved.connect(_on_joystick_moved)
			add_child(touch_controls)

func _on_joystick_moved(vec: Vector2) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].touch_input_vector = vec

func _process(delta: float) -> void:
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			banner_panel.visible = false

	# Vignette pulsing during warning phase
	var tm = get_node_or_null("/root/TimeManager")
	if tm != null and tm.get_remaining_time() <= 20.0 and tm.is_loop_running():
		_vignette_pulse += delta * 6.0
		var alpha = (sin(_vignette_pulse) * 0.5 + 0.5) * 0.35 + 0.1
		warning_vignette.color = Color(0.8, 0.05, 0.05, alpha)
	else:
		warning_vignette.color.a = 0.0

	# Update stamina bar
	if stamina_bar:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			stamina_bar.value = players[0].current_stamina

	# Fast travel toggle hotkey
	if Input.is_action_just_pressed("fast_travel_menu"):
		if fast_travel_panel and fast_travel_panel.visible:
			close_fast_travel_menu()
		elif fast_travel_panel:
			open_fast_travel_menu()

	# Home respawn hotkey (H)
	if Input.is_physical_key_pressed(KEY_H) and not _home_key_down:
		_home_key_down = true
		_on_home_button_pressed()
	elif not Input.is_physical_key_pressed(KEY_H):
		_home_key_down = false

func _on_second_ticked(remaining: float) -> void:
	if timer_label:
		timer_label.text = "[ %d ]" % ceil(remaining)
		if remaining <= 15.0:
			# Final 15 seconds high-urgency color pulsing
			var flash_col = Color(1.0, 0.15, 0.15) if (int(remaining * 2) % 2 == 0) else Color(1.0, 0.6, 0.1)
			timer_label.add_theme_color_override("font_color", flash_col)
		elif remaining <= 20.0:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.2))
		else:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))

func _on_time_warning_entered() -> void:
	_play_sfx("warning_tick")

func _on_loop_started(_max_time: float) -> void:
	_vignette_pulse = 0.0
	warning_vignette.color.a = 0.0

func _on_health_changed(current: int, max_hp: int) -> void:
	_update_hearts(current, max_hp)

func _update_hearts(current: int, max_hp: int) -> void:
	for c in heart_container.get_children():
		c.queue_free()

	var hp_label = Label.new()
	hp_label.text = "HP "
	hp_label.add_theme_font_size_override("font_size", 20)
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	heart_container.add_child(hp_label)

	for i in range(max_hp):
		var bar = ColorRect.new()
		bar.custom_minimum_size = Vector2(14, 20)
		bar.color = Color(0.95, 0.20, 0.25) if i < current else Color(0.25, 0.25, 0.30, 0.6)
		heart_container.add_child(bar)

	# Pulse animation on heart container
	var tw = create_tween()
	if tw:
		tw.tween_property(heart_container, "scale", Vector2(1.18, 1.18), 0.08)
		tw.tween_property(heart_container, "scale", Vector2(1.0, 1.0), 0.1)

func _on_item_collected(_item_id: String) -> void:
	_update_items()

func _update_items() -> void:
	for c in items_container.get_children():
		c.queue_free()

	var gs = get_node_or_null("/root/GameState")
	if gs != null:
		for item in gs.run_state.unlocked_items:
			var p = PanelContainer.new()
			var l = Label.new()
			l.text = " " + item + " "
			l.add_theme_font_size_override("font_size", 14)
			p.add_child(l)
			items_container.add_child(p)

func _on_bookmark_set(house_id: String, _pos: Vector3) -> void:
	show_banner("Respawn House Bookmarked: " + house_id)

func show_banner(text: String, duration: float = 3.0) -> void:
	banner_label.text = text
	banner_panel.visible = true
	_banner_timer = duration

func show_dialogue(text: String) -> void:
	dialogue_text.text = text
	dialogue_panel.visible = true

func close_dialogue() -> void:
	dialogue_panel.visible = false

func open_fast_travel_menu() -> void:
	# Populate activated waypoints
	for c in fast_travel_list.get_children():
		c.queue_free()

	var wg = get_node_or_null("/root/WorldGraph")
	var wps: Dictionary = {}
	if wg and wg.has_method("get_waypoint_positions"):
		wps = wg.get_waypoint_positions(true)
	if wps.is_empty():
		var none_label = Label.new()
		none_label.text = "No Waypoint Shrines activated yet.\nExplore the world and activate Shrines!"
		fast_travel_list.add_child(none_label)
	else:
		for wpid in wps.keys():
			var wp_data = wps[wpid]
			var btn = Button.new()
			btn.text = "%s (-10s)" % wp_data["display_name"]
			btn.pressed.connect(_on_waypoint_selected.bind(wpid, wp_data["position"]))
			fast_travel_list.add_child(btn)

	fast_travel_panel.visible = true

func close_fast_travel_menu() -> void:
	fast_travel_panel.visible = false

func _on_home_button_pressed() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("respawn_player"):
		gs.respawn_player()
		_play_sfx("teleport")
		var house_id = gs.run_state.get("bookmarked_house_id", "house_village_1")
		show_banner("Respawned to House: " + str(house_id))

func _on_waypoint_selected(wpid: String, pos: Vector3) -> void:
	close_fast_travel_menu()
	# Fast travel deducts loop time and moves player
	var tm = get_node_or_null("/root/TimeManager")
	if tm and tm.has_method("deduct_time"):
		tm.deduct_time(10.0)
	_play_sfx("teleport")
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].global_position = pos + Vector3(0.0, 0.5, 1.0)
	
	show_banner("Fast Traveled to: " + wpid)

func _play_sfx(sound_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sound_name)

func _on_coin_collected(total_coins: int) -> void:
	_update_coins(total_coins)
	_play_sfx("item_pickup")

func _update_coins(amount: int) -> void:
	if coin_label:
		coin_label.text = "  G: %d" % amount
