extends CanvasLayer

@onready var time_label = $MarginContainer/VBoxContainer/TimeLabel
@onready var inventory_container = $MarginContainer/VBoxContainer/InventoryContainer
@onready var minimap_viewport = $MinimapContainer/SubViewportContainer/SubViewport

# Mapping items to placeholders until we hook up actual Kenney UI icons
var item_icons = {
    "Shears": preload("res://assets/kenney_tiny_dungeon/Tiles/tile_0104.png"),
    "Shovel": preload("res://assets/kenney_tiny_dungeon/Tiles/tile_0105.png"),
    "Bicycle": preload("res://assets/kenney_tiny_dungeon/Tiles/tile_0106.png"),
    "Lantern": preload("res://assets/kenney_tiny_dungeon/Tiles/tile_0107.png"),
    "Flippers": preload("res://assets/kenney_tiny_dungeon/Tiles/tile_0109.png")
}

func _ready():
    var tm = get_node_or_null("/root/TimeManager")
    if tm:
        tm.connect("second_ticked", Callable(self, "_on_second_ticked"))
        tm.connect("time_warning_entered", Callable(self, "_on_time_warning"))

    var gs = get_node_or_null("/root/GameState")
    if gs:
        gs.connect("inventory_changed", Callable(self, "_update_inventory"))

    _update_inventory()

func _on_second_ticked(remaining_time: float):
    time_label.text = "Time: " + str(int(remaining_time)) + "s"

func _on_time_warning():
    time_label.add_theme_color_override("font_color", Color(1, 0, 0))

func _update_inventory():
    if not is_inside_tree() or GameState == null: return

    # Clear existing
    for child in inventory_container.get_children():
        child.queue_free()

    for item in GameState.run_state.unlocked_key_items:
        var icon = TextureRect.new()
        if item_icons.has(item):
            icon.texture = item_icons[item]
        else:
            # Fallback
            icon.texture = item_icons.values()[0]
        inventory_container.add_child(icon)
