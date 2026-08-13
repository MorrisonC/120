extends CanvasLayer

@onready var time_label = $MarginContainer/VBoxContainer/TimeLabel
@onready var cause_label = $MarginContainer/VBoxContainer/CauseLabel
@onready var items_label = $MarginContainer/VBoxContainer/ItemsLabel
@onready var biomes_label = $MarginContainer/VBoxContainer/BiomesLabel

func _ready():
    hide()
    var tm = get_node_or_null("/root/TimeManager")
    if tm:
        tm.connect("loop_expired", Callable(self, "_on_loop_expired"))

    var gs = get_node_or_null("/root/GameState")
    if gs and tm:
        # We need a way to detect start loop too, to hide it again
        # In a real game we might have a start screen, but we'll just hide on any input
        set_process_input(true)

func _input(event):
    if visible and (event is InputEventKey or event is InputEventMouseButton):
        if event.is_pressed():
            hide()
            get_tree().paused = false
            var tm = get_node_or_null("/root/TimeManager")
            if tm and not tm.is_running:
                pass

func _on_loop_expired():
    show()
    get_tree().paused = true
    var gs = get_node_or_null("/root/GameState")
    var tm = get_node_or_null("/root/TimeManager")

    if gs and tm:
        time_label.text = "Time Survived: " + str(int(tm.MAX_TIME - tm.remaining_time)) + "s"

        # Deduce cause based on remaining time
        if tm.remaining_time <= 0.0 and tm._warning_emitted:
            cause_label.text = "Cause of Reset: Loop Expired (Timeout)"
        else:
            cause_label.text = "Cause of Reset: Player Death"

        items_label.text = "Items Acquired: " + str(gs.run_state.unlocked_key_items.size()) + " (" + ", ".join(gs.run_state.unlocked_key_items) + ")"
        biomes_label.text = "Checkpoints Reached: " + str(gs.run_state.discovered_spawns.size())
