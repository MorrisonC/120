extends Node2D

const TILE_SIZE = 16
const ROOM_WIDTH_TILES = 20
const ROOM_HEIGHT_TILES = 15

const ROOM_WIDTH = ROOM_WIDTH_TILES * TILE_SIZE
const ROOM_HEIGHT = ROOM_HEIGHT_TILES * TILE_SIZE

const ROOM_SPACING_X = ROOM_WIDTH + 5 * TILE_SIZE
const ROOM_SPACING_Y = ROOM_HEIGHT + 5 * TILE_SIZE

@export var floor_tilemap: TileMapLayer
@export var wall_tilemap: TileMapLayer

var enemy_scene = preload("res://Enemy.tscn")

func _ready():
    if not has_node("FloorLayer"):
        floor_tilemap = TileMapLayer.new()
        floor_tilemap.name = "FloorLayer"
        add_child(floor_tilemap)
    else:
        floor_tilemap = $FloorLayer

    if not has_node("WallLayer"):
        wall_tilemap = TileMapLayer.new()
        wall_tilemap.name = "WallLayer"
        add_child(wall_tilemap)
    else:
        wall_tilemap = $WallLayer

    var pwd = get_node_or_null("/root/ProceduralWorldGenerator")
    if pwd:
        if pwd.generate_valid_world():
            build_world_visuals(pwd)

func build_world_visuals(generator: Node):
    var rooms = generator.rooms
    var positions = assign_positions(rooms, generator.start_node_id)

    for room_id in rooms:
        var room = rooms[room_id]
        var center_pos = positions[room_id]

        var start_x = int((center_pos.x - ROOM_WIDTH/2) / TILE_SIZE)
        var start_y = int((center_pos.y - ROOM_HEIGHT/2) / TILE_SIZE)

        var floor_atlas_coords = get_floor_tile_for_biome(room.biome, room.terrain)
        var wall_atlas_coords = get_wall_tile_for_biome(room.biome)

        for x in range(start_x, start_x + ROOM_WIDTH_TILES):
            for y in range(start_y, start_y + ROOM_HEIGHT_TILES):
                var is_edge = (x == start_x or x == start_x + ROOM_WIDTH_TILES - 1 or y == start_y or y == start_y + ROOM_HEIGHT_TILES - 1)

                floor_tilemap.set_cell(Vector2i(x, y), 0, floor_atlas_coords)

                if is_edge:
                    wall_tilemap.set_cell(Vector2i(x, y), 0, wall_atlas_coords)

        for edge_id in room.edges:
            if edge_id in positions:
                var neighbor_pos = positions[edge_id]

                # Only draw corridor if neighbor is physically to the right or bottom
                # (to avoid drawing twice since it's an undirected graph)
                var dx = neighbor_pos.x - center_pos.x
                var dy = neighbor_pos.y - center_pos.y

                if dx > 0.1 and abs(dx) > abs(dy):
                    # Horizontal corridor to the right
                    var door_y = start_y + ROOM_HEIGHT_TILES / 2
                    var door_x_start = start_x + ROOM_WIDTH_TILES - 1
                    var door_x_end = door_x_start + 6 # bridge the 5 tile gap

                    for cx in range(door_x_start, door_x_end + 1):
                        # Floor
                        floor_tilemap.set_cell(Vector2i(cx, door_y), 0, floor_atlas_coords)
                        floor_tilemap.set_cell(Vector2i(cx, door_y - 1), 0, floor_atlas_coords)
                        # Remove walls
                        wall_tilemap.set_cell(Vector2i(cx, door_y), -1, Vector2i(-1, -1))
                        wall_tilemap.set_cell(Vector2i(cx, door_y - 1), -1, Vector2i(-1, -1))
                        # Add side walls to corridor
                        wall_tilemap.set_cell(Vector2i(cx, door_y + 1), 0, wall_atlas_coords)
                        wall_tilemap.set_cell(Vector2i(cx, door_y - 2), 0, wall_atlas_coords)

                elif dy > 0.1 and abs(dy) > abs(dx):
                    # Vertical corridor to the bottom
                    var door_x = start_x + ROOM_WIDTH_TILES / 2
                    var door_y_start = start_y + ROOM_HEIGHT_TILES - 1
                    var door_y_end = door_y_start + 6 # bridge the 5 tile gap

                    for cy in range(door_y_start, door_y_end + 1):
                        # Floor
                        floor_tilemap.set_cell(Vector2i(door_x, cy), 0, floor_atlas_coords)
                        floor_tilemap.set_cell(Vector2i(door_x - 1, cy), 0, floor_atlas_coords)
                        # Remove walls
                        wall_tilemap.set_cell(Vector2i(door_x, cy), -1, Vector2i(-1, -1))
                        wall_tilemap.set_cell(Vector2i(door_x - 1, cy), -1, Vector2i(-1, -1))
                        # Add side walls to corridor
                        wall_tilemap.set_cell(Vector2i(door_x + 1, cy), 0, wall_atlas_coords)
                        wall_tilemap.set_cell(Vector2i(door_x - 2, cy), 0, wall_atlas_coords)

        # Spawn enemies
        if room_id != generator.start_node_id:
            # Spawn at least one chaser per biome
            var chaser = enemy_scene.instantiate()
            chaser.behavior = 2 # Behavior.CHASER
            chaser.global_position = center_pos + Vector2(20, 20)
            add_child(chaser)

            # Spawn a random hazard/stationary
            if randf() > 0.5:
                var patrol = enemy_scene.instantiate()
                patrol.behavior = 1 # Behavior.PATROL
                patrol.global_position = center_pos - Vector2(20, 20)
                add_child(patrol)

        # If it's the start node, set GameState respawn here
        if room_id == generator.start_node_id:
            if GameState.active_spawn_point == Vector2.ZERO:
                GameState.set_active_spawn_point(center_pos, room_id)
                var p = get_node_or_null("Player")
                if p: p.global_position = center_pos

func get_floor_tile_for_biome(biome: int, terrain: int) -> Vector2i:
    match terrain:
        1: return Vector2i(1, 4)
        2: return Vector2i(2, 4)
        3: return Vector2i(3, 4)
        4: return Vector2i(4, 4)
        _:
            match biome:
                0: return Vector2i(1, 1)
                1: return Vector2i(1, 4)
                2: return Vector2i(2, 4)
                3: return Vector2i(3, 1)
                4: return Vector2i(3, 4)
                5: return Vector2i(5, 5)
    return Vector2i(1, 1)

func get_wall_tile_for_biome(biome: int) -> Vector2i:
    match biome:
        0: return Vector2i(4, 0)
        1: return Vector2i(5, 0)
        2: return Vector2i(6, 0)
        3: return Vector2i(7, 0)
        4: return Vector2i(8, 0)
        5: return Vector2i(9, 0)
    return Vector2i(4, 0)

func assign_positions(rooms: Dictionary, start_node: String) -> Dictionary:
    var pos_map = {}
    var visited = {}
    var queue = []

    var grid_pos = {}

    pos_map[start_node] = Vector2.ZERO
    grid_pos[start_node] = Vector2i.ZERO
    visited[start_node] = true
    queue.append(start_node)

    var directions = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
    var used_grid = {Vector2i.ZERO: true}

    while queue.size() > 0:
        var curr = queue.pop_front()
        var current_grid = grid_pos[curr]
        var neighbors = rooms[curr].edges.keys()

        var dir_idx = 0
        for n in neighbors:
            if not n in visited:
                var placed = false
                var attempts = 0
                while not placed and attempts < 10:
                    var test_grid = current_grid + directions[dir_idx % 4] * (1 + attempts / 4)
                    if not used_grid.has(test_grid):
                        grid_pos[n] = test_grid
                        pos_map[n] = Vector2(test_grid.x * ROOM_SPACING_X, test_grid.y * ROOM_SPACING_Y)
                        used_grid[test_grid] = true
                        visited[n] = true
                        queue.append(n)
                        placed = true
                    dir_idx += 1
                    attempts += 1

    return pos_map
