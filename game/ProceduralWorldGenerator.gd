extends Node

const BASE_SPEED = 100.0
const BICYCLE_SPEED = 175.0
const FLIPPERS_SPEED = 90.0
const BOAT_SPEED = 200.0
const MUD_SPEED = 50.0
const SAND_SPEED = 80.0

enum Biome {
    VILLAGE,
    DESERT,
    SWAMP,
    CAVES,
    SEA,
    FACTORY
}

enum Terrain { NORMAL, SAND, MUD, WATER, DARK }
enum Obstacle { NONE, VINES, DIRT_MOUND, DARKNESS, DEEP_WATER }

class RoomNode:
    var id: String
    var biome: int
    var terrain: int
    var obstacle: int
    var edges: Dictionary = {}
    var is_checkpoint: bool = false
    var item_contained: String = ""

var rooms: Dictionary = {}
var start_node_id: String = ""
var items_to_place = ["Shears", "Shovel", "Bicycle", "Lantern", "Flippers"]

func generate_valid_world(max_retries: int = 100) -> bool:
    for i in range(max_retries):
        if generate_world():
            if verify_world():
                return true
    return false

func generate_world() -> bool:
    rooms.clear()

    # 1. Macro-Topology: Determine sequence
    # Always: Village -> Desert -> Swamp -> Caves -> Sea -> Factory

    # 2. Micro-Graph: Build rooms per biome
    _build_biome(Biome.VILLAGE, "village", Terrain.NORMAL, [Obstacle.NONE, Obstacle.VINES])
    _build_biome(Biome.DESERT, "desert", Terrain.SAND, [Obstacle.NONE, Obstacle.DIRT_MOUND])
    _build_biome(Biome.SWAMP, "swamp", Terrain.MUD, [Obstacle.NONE, Obstacle.VINES, Obstacle.DIRT_MOUND])
    _build_biome(Biome.CAVES, "caves", Terrain.NORMAL, [Obstacle.DARKNESS, Obstacle.DIRT_MOUND])
    _build_biome(Biome.SEA, "sea", Terrain.WATER, [Obstacle.DEEP_WATER])
    _build_biome(Biome.FACTORY, "factory", Terrain.NORMAL, [Obstacle.NONE])

    # Connect Biomes
    _connect_biomes("village", "desert")
    _connect_biomes("desert", "swamp")
    _connect_biomes("swamp", "caves")
    _connect_biomes("caves", "sea")
    _connect_biomes("sea", "factory")

    start_node_id = "village_0"
    rooms[start_node_id].is_checkpoint = true
    rooms[start_node_id].obstacle = Obstacle.NONE
    rooms[start_node_id].item_contained = ""

    _place_item_algorithmically("Shears", [Biome.VILLAGE])
    _place_item_algorithmically("Bicycle", [Biome.VILLAGE, Biome.DESERT])
    _place_item_algorithmically("Shovel", [Biome.VILLAGE, Biome.SWAMP])
    _place_item_algorithmically("Lantern", [Biome.VILLAGE, Biome.DESERT, Biome.CAVES])
    _place_item_algorithmically("Flippers", [Biome.VILLAGE, Biome.DESERT, Biome.SWAMP, Biome.SEA])

    return true

func add_edge(from_id: String, to_id: String, distance: float):
    rooms[from_id].edges[to_id] = distance
    rooms[to_id].edges[from_id] = distance

func _build_biome(biome: int, prefix: String, base_terrain: int, possible_obstacles: Array):
    # Random 3-5 rooms
    var room_count = randi() % 3 + 3
    for i in range(room_count):
        var room = RoomNode.new()
        room.id = prefix + "_" + str(i)
        room.biome = biome
        room.terrain = base_terrain
        room.obstacle = possible_obstacles[randi() % possible_obstacles.size()]
        if i == 0:
            room.obstacle = Obstacle.NONE # Entrance usually free

        # Ensure at least 1 checkpoint per biome
        room.is_checkpoint = (i == room_count / 2)
        rooms[room.id] = room

    # Linear connection inside biome to guarantee DAG path
    for i in range(room_count - 1):
        add_edge(prefix + "_" + str(i), prefix + "_" + str(i+1), randf_range(50.0, 300.0))

    # Optional extra random edges
    for i in range(room_count):
        if randf() > 0.5 and i < room_count - 2:
            add_edge(prefix + "_" + str(i), prefix + "_" + str(i+2), randf_range(100.0, 400.0))

func _connect_biomes(prefix_a: String, prefix_b: String):
    # Connect last room of A to first room of B
    var last_a = _get_last_room_in_biome(prefix_a)
    add_edge(last_a, prefix_b + "_0", randf_range(100.0, 300.0))

func _get_last_room_in_biome(prefix: String) -> String:
    var max_idx = -1
    for k in rooms.keys():
        if k.begins_with(prefix + "_"):
            var idx = k.split("_")[1].to_int()
            if idx > max_idx:
                max_idx = idx
    return prefix + "_" + str(max_idx)

func _place_item_algorithmically(item_name: String, allowed_biomes: Array):
    # We must only place items in rooms that are accessible without the item itself
    var currently_placed = []
    for k in rooms:
        if rooms[k].item_contained != "":
            currently_placed.append(rooms[k].item_contained)

    var dists = evaluate_solvability(start_node_id, currently_placed)
    var candidates = []

    for k in dists:
        if dists[k] < INF:
            var r = rooms[k]
            if r.biome in allowed_biomes and r.item_contained == "" and r.id != start_node_id:
                # Do not place item behind obstacle requiring it
                var is_blocked_by_itself = false
                if item_name == "Shears" and r.obstacle == Obstacle.VINES: is_blocked_by_itself = true
                if item_name == "Shovel" and r.obstacle == Obstacle.DIRT_MOUND: is_blocked_by_itself = true
                if item_name == "Lantern" and r.obstacle == Obstacle.DARKNESS: is_blocked_by_itself = true
                if item_name == "Flippers" and r.obstacle == Obstacle.DEEP_WATER: is_blocked_by_itself = true

                if not is_blocked_by_itself:
                    candidates.append(r)

    if candidates.size() > 0:
        var r = candidates[randi() % candidates.size()]
        r.item_contained = item_name
        r.obstacle = Obstacle.NONE

func verify_world() -> bool:
    var unlocked_items = []
    var discovered_spawns = [start_node_id]
    var all_visited = {}

    var progress_made = true
    while progress_made:
        progress_made = false

        # Evaluate from all discovered spawns
        for spawn in discovered_spawns:
            var dists = evaluate_solvability(spawn, unlocked_items)

            for r_id in dists:
                if dists[r_id] <= 110.0:
                    all_visited[r_id] = true

                    var r = rooms[r_id]
                    if r.item_contained != "" and not (r.item_contained in unlocked_items):
                        unlocked_items.append(r.item_contained)
                        progress_made = true

                    if r.is_checkpoint and not (r.id in discovered_spawns):
                        discovered_spawns.append(r.id)
                        progress_made = true

    # Check if we can reach factory end
    var factory_last = _get_last_room_in_biome("factory")
    if all_visited.has(factory_last):
        return true

    return false

func evaluate_solvability(start_id: String, active_items: Array) -> Dictionary:
    var dist = {}
    var pq = []

    for r in rooms:
        dist[r] = INF

    dist[start_id] = 0.0
    pq.append({"id": start_id, "cost": 0.0})

    while pq.size() > 0:
        pq.sort_custom(func(a, b): return a.cost < b.cost)
        var current = pq.pop_front()

        var u_id = current.id
        var u_cost = current.cost

        if u_cost > dist[u_id]:
            continue

        var u_room = rooms[u_id]

        for v_id in u_room.edges:
            var v_room = rooms[v_id]
            var distance = u_room.edges[v_id]

            if not can_pass_obstacle(v_room.obstacle, active_items):
                continue

            var speed = get_speed_for_terrain(v_room.terrain, active_items)
            if speed <= 0.0:
                continue

            var time_cost = distance / speed

            if dist[u_id] + time_cost < dist[v_id]:
                dist[v_id] = dist[u_id] + time_cost
                pq.append({"id": v_id, "cost": dist[v_id]})

    return dist

func can_pass_obstacle(obs: int, items: Array) -> bool:
    if obs == Obstacle.NONE:
        return true
    if obs == Obstacle.VINES and "Shears" in items:
        return true
    if obs == Obstacle.DIRT_MOUND and "Shovel" in items:
        return true
    if obs == Obstacle.DARKNESS and "Lantern" in items:
        return true
    if obs == Obstacle.DEEP_WATER and ("Flippers" in items or "Motorboat" in items):
        return true
    return false

func get_speed_for_terrain(terr: int, items: Array) -> float:
    var speed = BASE_SPEED
    if "Bicycle" in items:
        speed = BICYCLE_SPEED

    if terr == Terrain.SAND:
        if "Bicycle" not in items:
            speed = SAND_SPEED
    elif terr == Terrain.MUD:
        speed = MUD_SPEED
    elif terr == Terrain.WATER:
        if "Motorboat" in items:
            speed = BOAT_SPEED
        elif "Flippers" in items:
            speed = FLIPPERS_SPEED
        else:
            speed = 0.0

    return speed
