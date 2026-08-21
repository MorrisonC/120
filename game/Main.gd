extends Node2D

var world_gen: Node
var player: CharacterBody2D
var timer_label: Label
var room_label: Label

func _ready():
    # 1. Instantiate and generate world
    world_gen = load("res://ProceduralWorldGenerator.gd").new()
    add_child(world_gen)
    world_gen.generate_valid_world()

    # 2. Build visual representation for generated rooms
    _build_world_visuals()

    # 3. Spawn Player
    _spawn_player()

    # 4. Attach UI
    _create_ui()

    # 5. Start Time Loop
    var time_mgr = get_node_or_null("/root/TimeManager")
    if is_instance_valid(time_mgr):
        time_mgr.connect("second_ticked", Callable(self, "_on_second_ticked"))
        time_mgr.start_loop()

func _build_world_visuals():
    if not is_instance_valid(world_gen) or world_gen.rooms.is_empty():
        return

    var biomes_node = Node2D.new()
    biomes_node.name = "WorldBiomes"
    add_child(biomes_node)

    var room_size = Vector2(320, 180)
    var room_index = 0

    for room_id in world_gen.rooms:
        var room_data = world_gen.rooms[room_id]
        var room_pos = Vector2(room_index * room_size.x, 0)

        # Room Ground
        var bg = ColorRect.new()
        bg.size = room_size
        bg.position = room_pos
        bg.color = _get_biome_color(room_data.biome)
        biomes_node.add_child(bg)

        # Room Label/Obstacle info
        var label = Label.new()
        label.text = room_id.capitalize() + "\n" + _get_obstacle_name(room_data.obstacle)
        label.position = room_pos + Vector2(20, 20)
        label.add_theme_color_override("font_color", Color.WHITE)
        biomes_node.add_child(label)

        if room_data.item_contained != "":
            var item_label = Label.new()
            item_label.text = "[ " + room_data.item_contained + " ]"
            item_label.position = room_pos + Vector2(120, 90)
            item_label.add_theme_color_override("font_color", Color.YELLOW)
            biomes_node.add_child(item_label)

        room_index += 1

func _get_biome_color(biome: int) -> Color:
    match biome:
        0: return Color(0.2, 0.5, 0.2) # Village (green)
        1: return Color(0.7, 0.6, 0.3) # Desert (sand)
        2: return Color(0.3, 0.4, 0.2) # Swamp (mud)
        3: return Color(0.3, 0.3, 0.4) # Caves (dark blue/gray)
        4: return Color(0.1, 0.3, 0.6) # Sea (water blue)
        5: return Color(0.4, 0.4, 0.4) # Factory (steel gray)
        _: return Color(0.2, 0.2, 0.2)

func _get_obstacle_name(obs: int) -> String:
    match obs:
        1: return "Obstacle: Vines"
        2: return "Obstacle: Dirt Mound"
        3: return "Obstacle: Darkness"
        4: return "Obstacle: Deep Water"
        _: return ""

func _spawn_player():
    player = CharacterBody2D.new()
    player.name = "Player"
    player.set_script(load("res://PlayerController.gd"))

    # Player Visual Sprite
    var sprite = ColorRect.new()
    sprite.size = Vector2(16, 16)
    sprite.position = Vector2(-8, -8)
    sprite.color = Color(0.9, 0.2, 0.2) # Bright Red Player
    player.add_child(sprite)

    # Collision Shape
    var col = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(16, 16)
    col.shape = shape
    player.add_child(col)

    # Attach Camera
    var camera = Camera2D.new()
    camera.set_script(load("res://RoomCamera2D.gd"))
    player.add_child(camera)

    player.position = Vector2(160, 90)
    add_child(player)

func _create_ui():
    var ui_layer = CanvasLayer.new()
    ui_layer.name = "HUD"

    timer_label = Label.new()
    timer_label.text = "TIME: 120s"
    timer_label.position = Vector2(10, 10)
    timer_label.add_theme_color_override("font_color", Color.YELLOW)
    ui_layer.add_child(timer_label)

    room_label = Label.new()
    room_label.text = "BIOME: Village"
    room_label.position = Vector2(200, 10)
    room_label.add_theme_color_override("font_color", Color.WHITE)
    ui_layer.add_child(room_label)

    add_child(ui_layer)

func _on_second_ticked(remaining_time: float):
    if is_instance_valid(timer_label):
        timer_label.text = "TIME: " + str(int(remaining_time)) + "s"
