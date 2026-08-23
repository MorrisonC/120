extends Node3D
class_name RuinsPropScatterer

const Catalog = preload("res://scripts/procgen/ruins/RuinsTileCatalog.gd")

func scatter_props(dungeon_data: Dictionary, grid_map: GridMap, seed_val: int) -> Array[Node3D]:
	var spawned_nodes: Array[Node3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var rooms: Array = dungeon_data.get("rooms", [])
	var spawn_pos: Vector3i = dungeon_data.get("spawn_pos", Vector3i.ZERO)
	var exit_pos: Vector3i = dungeon_data.get("exit_pos", Vector3i.ZERO)

	for i in range(rooms.size()):
		var room: Rect2i = rooms[i]

		# 1. Place braziers at room corners
		var corners := [
			Vector2i(room.position.x + 1, room.position.y + 1),
			Vector2i(room.end.x - 2, room.position.y + 1),
			Vector2i(room.position.x + 1, room.end.y - 2),
			Vector2i(room.end.x - 2, room.end.y - 2)
		]

		for corner in corners:
			var cell := Vector3i(corner.x, 0, corner.y)
			if cell != spawn_pos and cell != exit_pos and grid_map != null:
				grid_map.set_cell_item(cell, Catalog.TILE_PROP_BRAZIER, 0)

		# 2. Scatter chests / urns along non-central wall perimeters
		if i > 0 and rng.randf() > 0.3:
			var chest_pos := Vector2i(room.position.x + 1, room.position.y + 2)
			var chest_cell := Vector3i(chest_pos.x, 0, chest_pos.y)
			if chest_cell != spawn_pos and chest_cell != exit_pos and grid_map != null:
				grid_map.set_cell_item(chest_cell, Catalog.TILE_PROP_CHEST, 0)

		# 3. Scatter rubble props
		if rng.randf() > 0.5:
			var rubble_pos := Vector2i(room.end.x - 2, room.position.y + 2)
			var rubble_cell := Vector3i(rubble_pos.x, 0, rubble_pos.y)
			if rubble_cell != spawn_pos and rubble_cell != exit_pos and grid_map != null:
				grid_map.set_cell_item(rubble_cell, Catalog.TILE_PROP_RUBBLE, 0)

	# 4. Place Altar / Puzzle Pedestal at Exit Position
	if grid_map != null and exit_pos != Vector3i.ZERO:
		grid_map.set_cell_item(exit_pos, Catalog.TILE_ARCH, 0)

	return spawned_nodes
