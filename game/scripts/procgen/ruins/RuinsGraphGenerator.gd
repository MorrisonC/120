extends RefCounted
class_name RuinsGraphGenerator

const Catalog = preload("res://scripts/procgen/ruins/RuinsTileCatalog.gd")

func generate(seed_val: int, grid_width: int = 32, grid_depth: int = 32, min_rooms: int = 4, max_rooms: int = 8) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var grid: Dictionary = {} # Vector2i -> int (Catalog tile type)
	for x in range(grid_width):
		for z in range(grid_depth):
			grid[Vector2i(x, z)] = Catalog.TILE_WALL_STRAIGHT

	# 1. Room Generation
	var target_room_count := rng.randi_range(min_rooms, max_rooms)
	var rooms: Array[Rect2i] = []
	var attempts := 0
	var max_attempts := 200

	while rooms.size() < target_room_count and attempts < max_attempts:
		attempts += 1
		var rw := rng.randi_range(4, 8)
		var rd := rng.randi_range(4, 8)
		var rx := rng.randi_range(2, grid_width - rw - 2)
		var rz := rng.randi_range(2, grid_depth - rd - 2)
		var new_room := Rect2i(rx, rz, rw, rd)

		var overlaps := false
		for existing in rooms:
			var padded := existing.grow(1)
			if padded.intersects(new_room):
				overlaps = true
				break

		if not overlaps:
			rooms.append(new_room)

	if rooms.is_empty():
		rooms.append(Rect2i(2, 2, 6, 6))

	# Carve rooms into grid
	for room in rooms:
		for x in range(room.position.x, room.end.x):
			for z in range(room.position.y, room.end.y):
				grid[Vector2i(x, z)] = Catalog.TILE_FLOOR

	# 2. Corridor Connectivity (Minimum Spanning Tree with cycle re-addition)
	var room_centers: Array[Vector2i] = []
	for room in rooms:
		room_centers.append(room.get_center())

	var edges: Array[Dictionary] = [] # {from_idx: int, to_idx: int, dist: float}
	for i in range(room_centers.size()):
		for j in range(i + 1, room_centers.size()):
			var dist := room_centers[i].distance_to(room_centers[j])
			edges.append({"from_idx": i, "to_idx": j, "dist": dist})

	edges.sort_custom(func(a, b): return a.dist < b.dist)

	# Kruskal's MST
	var parent: Array[int] = []
	for i in range(room_centers.size()):
		parent.append(i)

	var mst_edges: Array[Dictionary] = []
	var remaining_edges: Array[Dictionary] = []

	for edge in edges:
		if _union_sets(edge.from_idx, edge.to_idx, parent):
			mst_edges.append(edge)
		else:
			remaining_edges.append(edge)

	# Re-add ~15% cycles to avoid linear bottlenecks
	var extra_cycles := int(ceil(remaining_edges.size() * 0.15))
	for i in range(min(extra_cycles, remaining_edges.size())):
		mst_edges.append(remaining_edges[i])

	# Carve corridors along connected room centers
	for edge in mst_edges:
		var start := room_centers[edge.from_idx]
		var end := room_centers[edge.to_idx]
		_carve_corridor(grid, start, end, rng)

	# Determine Walkable Tiles
	var walkable_tiles: Array[Vector2i] = []
	for pos in grid.keys():
		if Catalog.is_walkable(grid[pos]):
			walkable_tiles.append(pos)

	# Spawn Room = First Room, Exit Room = Furthest Room from Spawn
	var spawn_room := rooms[0]
	var spawn_center := spawn_room.get_center()
	var spawn_pos := Vector3i(spawn_center.x, 0, spawn_center.y)

	var exit_room := rooms[0]
	var max_dist := -1.0
	for room in rooms:
		var d := spawn_center.distance_to(room.get_center())
		if d > max_dist:
			max_dist = d
			exit_room = room

	var exit_center := exit_room.get_center()
	var exit_pos := Vector3i(exit_center.x, 0, exit_center.y)

	return {
		"grid": grid,
		"rooms": rooms,
		"spawn_pos": spawn_pos,
		"exit_pos": exit_pos,
		"walkable_tiles": walkable_tiles,
		"grid_width": grid_width,
		"grid_depth": grid_depth
	}

func _find_set(v: int, parent: Array[int]) -> int:
	var curr := v
	while curr != parent[curr]:
		curr = parent[curr]
	return curr

func _union_sets(a: int, b: int, parent: Array[int]) -> bool:
	var root_a := _find_set(a, parent)
	var root_b := _find_set(b, parent)
	if root_a != root_b:
		parent[root_b] = root_a
		return true
	return false

func _carve_corridor(grid: Dictionary, start: Vector2i, end: Vector2i, rng: RandomNumberGenerator) -> void:
	var current := start
	var coin_flip := rng.randf() > 0.5

	if coin_flip:
		while current.x != end.x:
			current.x += 1 if end.x > current.x else -1
			_carve_tile(grid, current)
		while current.y != end.y:
			current.y += 1 if end.y > current.y else -1
			_carve_tile(grid, current)
	else:
		while current.y != end.y:
			current.y += 1 if end.y > current.y else -1
			_carve_tile(grid, current)
		while current.x != end.x:
			current.x += 1 if end.x > current.x else -1
			_carve_tile(grid, current)

func _carve_tile(grid: Dictionary, pos: Vector2i) -> void:
	if grid.has(pos):
		grid[pos] = Catalog.TILE_FLOOR

func verify_reachability(walkable_tiles: Array, spawn_pos, exit_pos) -> bool:
	var spawn_2d := Vector2i(spawn_pos.x, spawn_pos.z) if spawn_pos is Vector3i else Vector2i(spawn_pos.x, spawn_pos.y)
	var exit_2d := Vector2i(exit_pos.x, exit_pos.z) if exit_pos is Vector3i else Vector2i(exit_pos.x, exit_pos.y)

	var tile_set := {}
	for t in walkable_tiles:
		var v := Vector2i(t.x, t.z) if t is Vector3i else Vector2i(t.x, t.y)
		tile_set[v] = true

	if not tile_set.has(spawn_2d) or not tile_set.has(exit_2d):
		return false

	var visited := {}
	var queue: Array[Vector2i] = [spawn_2d]
	visited[spawn_2d] = true

	var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

	while not queue.is_empty():
		var curr: Vector2i = queue.pop_front()
		if curr == exit_2d:
			return true

		for i in range(directions.size()):
			var dir: Vector2i = directions[i]
			var neighbor: Vector2i = curr + dir
			if tile_set.has(neighbor) and not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)

	return false
