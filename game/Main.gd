extends Node2D

var world_gen: Node
var player: CharacterBody2D
var timer_label: Label
var room_label: Label
var health_label: Label
var map_overlay: Control
var map_button: Button

var checkpoint_nodes: Dictionary = {}
var current_room_index: int = 0

func _ready():
    RenderingServer.set_default_clear_color(Color(0.08, 0.12, 0.15))

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
    var total_rooms = world_gen.rooms.size()
    var tex_gen = load("res://assets/TextureGenerator.gd")

    for room_id in world_gen.rooms:
        var room_data = world_gen.rooms[room_id]
        var room_pos = Vector2(room_index * room_size.x, 0)

        # Build 2D tilemap landscape for this room
        _build_room_tilemap(biomes_node, room_data, room_pos, room_index, total_rooms, tex_gen)

        # Checkpoint Safe Location Marker
        if room_data.is_checkpoint:
            _spawn_checkpoint(biomes_node, room_id, room_pos + Vector2(160, 90), tex_gen)

        # Item Prop
        if room_data.item_contained != "":
            _spawn_item_prop(biomes_node, room_data.item_contained, room_pos + Vector2(160, 140))

        # Obstacle Prop
        if room_data.obstacle != 0:
            _spawn_obstacle_prop(biomes_node, room_data.obstacle, room_pos + Vector2(240, 130))

        # Add an interactive enemy target in non-checkpoint rooms
        if room_index > 0 and not room_data.is_checkpoint:
            _spawn_enemy_target(biomes_node, room_pos + Vector2(240, 55))

        # Add slashable grass patch in village/room
        _spawn_slashable_grass_patch(biomes_node, room_pos + Vector2(100, 70))

        room_index += 1

func _build_room_tilemap(parent: Node, room_data, room_pos: Vector2, room_index: int, total_rooms: int, tex_gen):
    var biome = room_data.biome
    var ground_tex = tex_gen.create_biome_ground_texture(biome)
    var path_tex = tex_gen.create_biome_path_texture(biome)
    var wall_tex = tex_gen.create_biome_wall_texture(biome)
    var decor_tex = tex_gen.create_biome_decor_texture(biome)

    var room_node = Node2D.new()
    room_node.name = "Room_" + room_data.id
    room_node.position = room_pos
    parent.add_child(room_node)

    # 20 columns x 11 rows of 16x16 tiles = 320x176
    for row in range(11):
        for col in range(20):
            var tile_pos = Vector2(col * 16, row * 16 + 4)
            var is_wall = false
            var is_path = false
            var is_decor = false

            if row == 0 or row == 10:
                is_wall = true
            elif col == 0 and room_index > 0:
                if not (row == 5 or row == 6):
                    is_wall = true
            elif col == 19 and room_index < total_rooms - 1:
                if not (row == 5 or row == 6):
                    is_wall = true
            elif col == 0 or col == 19:
                is_wall = true

            if not is_wall and (row == 5 or row == 6):
                is_path = true
            elif not is_wall and ((col * 5 + row * 11) % 13 == 0):
                is_decor = true

            var sprite = Sprite2D.new()
            sprite.centered = false
            sprite.position = tile_pos

            if is_wall:
                sprite.texture = wall_tex
                var static_body = StaticBody2D.new()
                static_body.position = tile_pos + Vector2(8, 8)
                var col_shape = CollisionShape2D.new()
                var rect = RectangleShape2D.new()
                rect.size = Vector2(16, 16)
                col_shape.shape = rect
                static_body.add_child(col_shape)
                room_node.add_child(static_body)
            elif is_path:
                sprite.texture = path_tex
            elif is_decor:
                sprite.texture = decor_tex
            else:
                sprite.texture = ground_tex

            room_node.add_child(sprite)

func _spawn_checkpoint(parent: Node, room_id: String, pos: Vector2, tex_gen):
    var cp_area = Area2D.new()
    cp_area.name = "Checkpoint_" + room_id
    cp_area.position = pos

    var cp_shape = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(32, 32)
    cp_shape.shape = shape
    cp_area.add_child(cp_shape)

    var cp_sprite = Sprite2D.new()
    if is_instance_valid(tex_gen) and tex_gen.has_method("create_checkpoint_texture"):
        cp_sprite.texture = tex_gen.create_checkpoint_texture()
    cp_area.add_child(cp_sprite)

    cp_area.connect("body_entered", Callable(self, "_on_checkpoint_entered").bind(room_id, cp_area.global_position))
    parent.add_child(cp_area)
    checkpoint_nodes[room_id] = cp_area

func _spawn_item_prop(parent: Node, item_name: String, pos: Vector2):
    var item_node = Node2D.new()
    item_node.name = "Item_" + item_name
    item_node.position = pos

    var sprite = Sprite2D.new()
    if ResourceLoader.exists("res://assets/sprites/props/anchor_stone_16.png"):
        sprite.texture = load("res://assets/sprites/props/anchor_stone_16.png")
    item_node.add_child(sprite)

    var label = Label.new()
    label.text = item_name
    label.position = Vector2(-20, -22)
    label.add_theme_font_size_override("font_size", 10)
    label.add_theme_color_override("font_color", Color.YELLOW)
    item_node.add_child(label)

    parent.add_child(item_node)

func _spawn_obstacle_prop(parent: Node, obs_type: int, pos: Vector2):
    var obs_node = Node2D.new()
    obs_node.name = "ObstacleProp"
    obs_node.position = pos

    var sprite = Sprite2D.new()
    var path = ""
    match obs_type:
        1: path = "res://assets/sprites/props/swamp_obstacle.png"
        2: path = "res://assets/sprites/props/swamp_obstacle.png"
        3: path = "res://assets/sprites/props/desert_hazard_quicksand.png"
        4: path = "res://assets/sprites/props/desert_hazard_cactus.png"
    if path != "" and ResourceLoader.exists(path):
        sprite.texture = load(path)
    obs_node.add_child(sprite)

    var obs_label = Label.new()
    obs_label.text = _get_obstacle_name(obs_type)
    obs_label.position = Vector2(-30, -20)
    obs_label.add_theme_font_size_override("font_size", 9)
    obs_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
    obs_node.add_child(obs_label)

    parent.add_child(obs_node)

func _spawn_slashable_grass_patch(parent: Node, base_pos: Vector2):
    var grass_script = load("res://SlashableGrass.gd")
    if not is_instance_valid(grass_script):
        return

    for x in range(3):
        for y in range(2):
            var grass = grass_script.new()
            grass.position = base_pos + Vector2(x * 16, y * 16)
            parent.add_child(grass)

func _spawn_enemy_target(parent: Node, pos: Vector2):
    var enemy = Area2D.new()
    enemy.name = "EnemyTarget"
    enemy.position = pos

    var shape = CollisionShape2D.new()
    var rect = RectangleShape2D.new()
    rect.size = Vector2(16, 16)
    shape.shape = rect
    enemy.add_child(shape)

    var sprite = Sprite2D.new()
    sprite.name = "Sprite2D"
    if ResourceLoader.exists("res://assets/sprites/characters/enemy_patrol_1.png"):
        sprite.texture = load("res://assets/sprites/characters/enemy_patrol_1.png")
    else:
        var tex_gen = load("res://assets/TextureGenerator.gd")
        if is_instance_valid(tex_gen) and tex_gen.has_method("create_monster_texture"):
            sprite.texture = tex_gen.create_monster_texture()
    enemy.add_child(sprite)

    var hp_bar = ColorRect.new()
    hp_bar.name = "HPBar"
    hp_bar.size = Vector2(16, 3)
    hp_bar.position = Vector2(-8, -12)
    hp_bar.color = Color.RED
    enemy.add_child(hp_bar)

    enemy.set_meta("health", 2)

    enemy.connect("area_entered", Callable(self, "_on_enemy_hit").bind(enemy))
    enemy.connect("body_entered", Callable(self, "_on_enemy_contact_player"))
    parent.add_child(enemy)

func _on_enemy_contact_player(body: Node2D):
    if body is CharacterBody2D and body.has_method("take_damage"):
        body.take_damage(1)

func _on_enemy_hit(area: Area2D, enemy_node: Node2D):
    if area.name == "AttackHitbox":
        var hp = enemy_node.get_meta("health") - 1
        enemy_node.set_meta("health", hp)

        var hp_bar = enemy_node.get_node_or_null("HPBar")
        if is_instance_valid(hp_bar):
            hp_bar.size.x = max(0, hp * 8)

        var juice = get_node_or_null("/root/VisualJuiceManager")
        if is_instance_valid(juice):
            juice.spawn_particles(enemy_node.global_position, Color.MAGENTA, 12)
            juice.trigger_screen_shake(0.2, 3.0)

        if hp <= 0:
            enemy_node.queue_free()

func _on_checkpoint_entered(body: Node2D, room_id: String, cp_pos: Vector2):
    if body is CharacterBody2D:
        var game_state = get_node_or_null("/root/GameState")
        if is_instance_valid(game_state):
            game_state.set_active_spawn_point(cp_pos, room_id)
            if is_instance_valid(room_label):
                var room_data = world_gen.rooms.get(room_id)
                var biome_name = _get_biome_name(room_data.biome) if room_data else "Village"
                room_label.text = "BIOME: " + biome_name

func _get_biome_name(biome: int) -> String:
    match biome:
        0: return "Village"
        1: return "Desert"
        2: return "Swamp"
        3: return "Caves"
        4: return "Sea"
        5: return "Factory"
        _: return "Unknown"

func _get_biome_color(biome: int) -> Color:
    match biome:
        0: return Color(0.2, 0.5, 0.2)
        1: return Color(0.7, 0.6, 0.3)
        2: return Color(0.3, 0.4, 0.2)
        3: return Color(0.3, 0.3, 0.4)
        4: return Color(0.1, 0.3, 0.6)
        5: return Color(0.4, 0.4, 0.4)
        _: return Color(0.2, 0.2, 0.2)

func _get_obstacle_name(obs: int) -> String:
    match obs:
        1: return "Vines"
        2: return "Dirt Mound"
        3: return "Darkness"
        4: return "Deep Water"
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
    var room_camera = Camera2D.new()
    room_camera.set_script(load("res://RoomCamera2D.gd"))
    player.add_child(room_camera)

    player.position = Vector2(160, 90)
    player.connect("health_changed", Callable(self, "_on_player_health_changed"))
    add_child(player)

    if room_camera.has_signal("room_changed"):
        room_camera.connect("room_changed", Callable(self, "_on_room_changed"))

func _create_ui():
    var ui_layer = CanvasLayer.new()
    ui_layer.name = "HUD"

    # Top HUD Bar Panel
    var hud_bg = ColorRect.new()
    hud_bg.size = Vector2(320, 18)
    hud_bg.color = Color(0.05, 0.08, 0.12, 0.85)
    ui_layer.add_child(hud_bg)

    timer_label = Label.new()
    timer_label.text = "TIME: 120s"
    timer_label.position = Vector2(6, 1)
    timer_label.add_theme_font_size_override("font_size", 11)
    timer_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
    ui_layer.add_child(timer_label)

    health_label = Label.new()
    health_label.text = "HP: 3/3"
    health_label.position = Vector2(95, 1)
    health_label.add_theme_font_size_override("font_size", 11)
    health_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
    ui_layer.add_child(health_label)

    var tex_gen = load("res://assets/TextureGenerator.gd")
    if is_instance_valid(tex_gen) and tex_gen.has_method("create_heart_texture"):
        var heart_icon = TextureRect.new()
        heart_icon.name = "HeartsUI"
        heart_icon.texture = tex_gen.create_heart_texture()
        heart_icon.position = Vector2(150, 1)
        ui_layer.add_child(heart_icon)

    room_label = Label.new()
    room_label.text = "BIOME: Village"
    room_label.position = Vector2(195, 1)
    room_label.add_theme_font_size_override("font_size", 11)
    room_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
    ui_layer.add_child(room_label)

    # MAP Button on HUD
    map_button = Button.new()
    map_button.text = "MAP [M]"
    map_button.position = Vector2(265, 1)
    map_button.size = Vector2(50, 16)
    map_button.add_theme_font_size_override("font_size", 9)
    map_button.connect("pressed", Callable(self, "toggle_map"))
    ui_layer.add_child(map_button)

    # Touch Controls Overlay
    var touch_controls = load("res://TouchControls.gd").new()
    touch_controls.name = "TouchControls"
    touch_controls.size = Vector2(320, 180)
    touch_controls.connect("joystick_moved", Callable(self, "_on_touch_joystick_moved"))
    touch_controls.connect("attack_pressed", Callable(self, "_on_touch_attack_pressed"))
    ui_layer.add_child(touch_controls)

    # Map Popup Overlay
    _create_map_overlay(ui_layer)

    add_child(ui_layer)

func _create_map_overlay(parent: CanvasLayer):
    map_overlay = Control.new()
    map_overlay.name = "MapOverlay"
    map_overlay.visible = false
    map_overlay.position = Vector2(40, 25)
    map_overlay.size = Vector2(240, 130)

    var bg = ColorRect.new()
    bg.size = map_overlay.size
    bg.color = Color(0.04, 0.06, 0.1, 0.92)
    map_overlay.add_child(bg)

    var title = Label.new()
    title.text = "WORLD MAP"
    title.position = Vector2(85, 4)
    title.add_theme_font_size_override("font_size", 12)
    title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
    map_overlay.add_child(title)

    parent.add_child(map_overlay)
    _update_map_display()

func toggle_map():
    if is_instance_valid(map_overlay):
        map_overlay.visible = not map_overlay.visible
        if map_overlay.visible:
            _update_map_display()

func _input(event: InputEvent):
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_M:
            toggle_map()

func _on_room_changed(room_coords: Vector2):
    if not is_instance_valid(world_gen) or world_gen.rooms.is_empty():
        return
    current_room_index = int(clamp(room_coords.x, 0, world_gen.rooms.size() - 1))
    var room_keys = world_gen.rooms.keys()
    if current_room_index < room_keys.size():
        var room_id = room_keys[current_room_index]
        var room_data = world_gen.rooms[room_id]
        if is_instance_valid(room_label):
            room_label.text = "BIOME: " + _get_biome_name(room_data.biome)
    _update_map_display()

func _update_map_display():
    if not is_instance_valid(map_overlay) or not is_instance_valid(world_gen):
        return

    # Clear previous room indicators
    for child in map_overlay.get_children():
        if child.name.begins_with("MapRoom_"):
            child.queue_free()

    var room_keys = world_gen.rooms.keys()
    var total_rooms = room_keys.size()
    if total_rooms == 0:
        return

    var card_width = 32
    var card_height = 20
    var start_x = 10
    var start_y = 35

    for i in range(total_rooms):
        var room_id = room_keys[i]
        var room_data = world_gen.rooms[room_id]

        var r_rect = ColorRect.new()
        r_rect.name = "MapRoom_" + str(i)
        r_rect.size = Vector2(card_width, card_height)
        r_rect.position = Vector2(start_x + i * (card_width + 6), start_y + (i % 3) * (card_height + 8))
        r_rect.color = _get_biome_color(room_data.biome)

        if i == current_room_index:
            r_rect.color = r_rect.color.lightened(0.4)
            var current_dot = ColorRect.new()
            current_dot.size = Vector2(6, 6)
            current_dot.position = Vector2(card_width / 2 - 3, card_height / 2 - 3)
            current_dot.color = Color.YELLOW
            r_rect.add_child(current_dot)

        var r_label = Label.new()
        r_label.text = room_data.id
        r_label.position = Vector2(2, 2)
        r_label.add_theme_font_size_override("font_size", 7)
        r_label.add_theme_color_override("font_color", Color.WHITE)
        r_rect.add_child(r_label)

        map_overlay.add_child(r_rect)

func _on_touch_joystick_moved(vector: Vector2) -> void:
    if is_instance_valid(player):
        player.touch_input_vector = vector

func _on_touch_attack_pressed() -> void:
    if is_instance_valid(player) and player.has_method("perform_attack"):
        if not player.is_attacking:
            player.perform_attack()

func _on_second_ticked(remaining_time: float):
    if is_instance_valid(timer_label):
        timer_label.text = "TIME: " + str(int(remaining_time)) + "s"

func _on_player_health_changed(hp: int, max_hp: int):
    if is_instance_valid(health_label):
        health_label.text = "HP: " + str(hp) + "/" + str(max_hp)

func _on_loop_expired():
    var game_state = get_node_or_null("/root/GameState")
    var spawn_pos = Vector2(160, 90)
    if is_instance_valid(game_state) and game_state.active_spawn_point != Vector2.ZERO:
        spawn_pos = game_state.active_spawn_point

    if is_instance_valid(player):
        player.global_position = spawn_pos
        player.current_health = player.max_health
        _on_player_health_changed(player.current_health, player.max_health)
