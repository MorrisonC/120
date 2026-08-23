extends Node3D
class_name RuinsNavigationManager

const Catalog = preload("res://scripts/procgen/ruins/RuinsTileCatalog.gd")

var astar := AStar3D.new()
var pos_to_id: Dictionary = {}

func build_navigation_graph(dungeon_data: Dictionary) -> void:
	astar.clear()
	pos_to_id.clear()

	var walkable_tiles: Array = dungeon_data.get("walkable_tiles", [])
	var id_counter := 0

	# Add points
	for tile in walkable_tiles:
		var pos_2d := Vector2i(tile.x, tile.z) if tile is Vector3i else Vector2i(tile.x, tile.y)
		var world_pos := Vector3(pos_2d.x + 0.5, 0.0, pos_2d.y + 0.5)
		astar.add_point(id_counter, world_pos)
		pos_to_id[pos_2d] = id_counter
		id_counter += 1

	# Connect 4-cardinal neighbors
	var directions := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for pos_2d in pos_to_id.keys():
		var id_a: int = pos_to_id[pos_2d]
		for dir in directions:
			var neighbor: Vector2i = pos_2d + dir
			if pos_to_id.has(neighbor):
				var id_b: int = pos_to_id[neighbor]
				if not astar.are_points_connected(id_a, id_b):
					astar.connect_points(id_a, id_b)

func find_path(start_pos: Vector3, target_pos: Vector3) -> PackedVector3Array:
	var start_2d := Vector2i(int(floor(start_pos.x)), int(floor(start_pos.z)))
	var target_2d := Vector2i(int(floor(target_pos.x)), int(floor(target_pos.z)))

	if not pos_to_id.has(start_2d) or not pos_to_id.has(target_2d):
		return PackedVector3Array()

	var start_id: int = pos_to_id[start_2d]
	var target_id: int = pos_to_id[target_2d]

	return astar.get_point_path(start_id, target_id)
