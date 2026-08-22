extends Node2D

var world_gen: Node
var player: CharacterBody2D
var timer_label: Label
var room_label: Label
var health_label: Label

var checkpoint_nodes: Dictionary = {}

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

    # 5. Connect GameState / Time Loop
    var time_mgr = get_node_or_null("/root/TimeManager")
    if is_instance_valid(time_mgr):
        time_mgr.connect("second_ticked", Callable(self, "_on_second_ticked"))
        time_mgr.connect("loop_expired", Callable(self, "_on_loop_expired"))
        time_mgr.start_loop()

    # Set initial active spawn point at village spawn
    var game_state = get_node_or_null("/root/GameState")
    if is_instance_valid(game_state):
        game_state.set_active_spawn_point(Vector2(160, 90), "village_0")

func _build_world_visuals():
    if not is_instance_valid(world_gen) or world_gen.rooms.is_empty():
        return

    var biomes_node = Node2D.new()
    biomes_node.name = "WorldBiomes"
    add_child(biomes_node)

    var room_size = Vector2(320, 180)
    var room_index = 0
    var tex_gen = load("res://assets/TextureGenerator.gd")

    for room_id in world_gen.rooms:
        var room_data = world_gen.rooms[room_id]
        var room_pos = Vector2(room_index * room_size.x, 0)

        # Room Ground
        var bg = ColorRect.new()
        bg.size = room_size
        bg.position = room_pos
        bg.color = _get_biome_color(room_data.biome)
        biomes_node.add_child(bg)

        # Decorative grid lines (GBC aesthetic)
        var border = ReferenceRect.new()
        border.size = room_size
        border.position = room_pos
        border.editor_only = false
        border.border_color = Color(1.0, 1.0, 1.0, 0.15)
        border.border_width = 2.0
        biomes_node.add_child(border)

        # Room Label/Obstacle info
        var label = Label.new()
        label.text = room_id.capitalize() + "\n" + _get_obstacle_name(room_data.obstacle)
        label.position = room_pos + Vector2(10, 10)
        label.add_theme_color_override("font_color", Color.WHITE)
        biomes_node.add_child(label)

        # Checkpoint Safe Location Marker
        if room_data.is_checkpoint:
            var cp_area = Area2D.new()
            cp_area.name = "Checkpoint_" + room_id
            cp_area.position = room_pos + Vector2(160, 90)

            var cp_shape = CollisionShape2D.new()
            var shape = RectangleShape2D.new()
            shape.size = Vector2(32, 32)
            cp_shape.shape = shape
            cp_area.add_child(cp_shape)

            if is_instance_valid(tex_gen) and tex_gen.has_method("create_checkpoint_texture"):
                var cp_sprite = Sprite2D.new()
                cp_sprite.texture = tex_gen.create_checkpoint_texture()
                cp_area.add_child(cp_sprite)

            var cp_label = Label.new()
            cp_label.text = "SAFE"
            cp_label.position = Vector2(-16, -28)
            cp_label.add_theme_color_override("font_color", Color.GREEN_YELLOW)
            cp_area.add_child(cp_label)

            cp_area.connect("body_entered", Callable(self, "_on_checkpoint_entered").bind(room_id, cp_area.global_position))
            biomes_node.add_child(cp_area)
            checkpoint_nodes[room_id] = cp_area

        if room_data.item_contained != "":
            var item_label = Label.new()
            item_label.text = "[ " + room_data.item_contained + " ]"
            item_label.position = room_pos + Vector2(120, 130)
            item_label.add_theme_color_override("font_color", Color.YELLOW)
            biomes_node.add_child(item_label)

        # Add an interactive enemy target in non-checkpoint rooms
        if room_index > 0 and not room_data.is_checkpoint:
            _spawn_enemy_target(biomes_node, room_pos + Vector2(220, 90))

        room_index += 1

func _spawn_enemy_target(parent: Node, pos: Vector2):
    var enemy = Area2D.new()
    enemy.name = "EnemyTarget"
    enemy.position = pos

    var shape = CollisionShape2D.new()
    var rect = RectangleShape2D.new()
    rect.size = Vector2(16, 16)
    shape.shape = rect
    enemy.add_child(shape)

    var tex_gen = load("res://assets/TextureGenerator.gd")
    if is_instance_valid(tex_gen) and tex_gen.has_method("create_monster_texture"):
        var sprite = Sprite2D.new()
        sprite.texture = tex_gen.create_monster_texture()
        enemy.add_child(sprite)
    else:
        var visual = ColorRect.new()
        visual.size = Vector2(16, 16)
        visual.position = Vector2(-8, -8)
        visual.color = Color(0.8, 0.2, 0.8)
        enemy.add_child(visual)

    enemy.connect("area_entered", Callable(self, "_on_enemy_hit").bind(enemy))
    enemy.connect("body_entered", Callable(self, "_on_enemy_contact_player"))
    parent.add_child(enemy)

func _on_enemy_contact_player(body: Node2D):
    if body is CharacterBody2D and body.has_method("take_damage"):
        body.take_damage(1)

func _on_enemy_hit(area: Area2D, enemy_node: Node2D):
    if area.name == "AttackHitbox":
        var juice = get_node_or_null("/root/VisualJuiceManager")
        if is_instance_valid(juice):
            juice.spawn_particles(enemy_node.global_position, Color.MAGENTA, 12)
            juice.trigger_screen_shake(0.2, 3.0)
        enemy_node.queue_free()

func _on_checkpoint_entered(body: Node2D, room_id: String, cp_pos: Vector2):
    if body is CharacterBody2D:
        var game_state = get_node_or_null("/root/GameState")
        if is_instance_valid(game_state):
            game_state.set_active_spawn_point(cp_pos, room_id)
            if is_instance_valid(room_label):
                room_label.text = "SAFE: " + room_id.capitalize()

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
    player.connect("health_changed", Callable(self, "_on_player_health_changed"))
    add_child(player)

func _create_ui():
    var ui_layer = CanvasLayer.new()
    ui_layer.name = "HUD"

    timer_label = Label.new()
    timer_label.text = "TIME: 120s"
    timer_label.position = Vector2(10, 10)
    timer_label.add_theme_color_override("font_color", Color.YELLOW)
    ui_layer.add_child(timer_label)

    health_label = Label.new()
    health_label.text = "HP: ♥ ♥ ♥"
    health_label.position = Vector2(100, 10)
    health_label.add_theme_color_override("font_color", Color.RED)
    ui_layer.add_child(health_label)

    room_label = Label.new()
    room_label.text = "BIOME: Village"
    room_label.position = Vector2(200, 10)
    room_label.add_theme_color_override("font_color", Color.WHITE)
    ui_layer.add_child(room_label)

    add_child(ui_layer)

func _on_second_ticked(remaining_time: float):
    if is_instance_valid(timer_label):
        timer_label.text = "TIME: " + str(int(remaining_time)) + "s"

func _on_player_health_changed(hp: int, max_hp: int):
    if is_instance_valid(health_label):
        var hearts = ""
        for i in range(hp):
            hearts += "♥ "
        health_label.text = "HP: " + hearts.strip_edges()

func _on_loop_expired():
    # Respawn player at current active spawn point
    var game_state = get_node_or_null("/root/GameState")
    var spawn_pos = Vector2(160, 90)
    if is_instance_valid(game_state) and game_state.active_spawn_point != Vector2.ZERO:
        spawn_pos = game_state.active_spawn_point

    if is_instance_valid(player):
        player.global_position = spawn_pos
        player.current_health = player.max_health
        _on_player_health_changed(player.current_health, player.max_health)
