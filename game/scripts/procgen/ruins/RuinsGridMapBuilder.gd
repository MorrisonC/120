extends Node3D
class_name RuinsGridMapBuilder

@export var grid_map: GridMap

const Catalog = preload("res://scripts/procgen/ruins/RuinsTileCatalog.gd")

const N = 1
const E = 2
const S = 4
const W = 8

func _ready() -> void:
	if not is_instance_valid(grid_map):
		grid_map = GridMap.new()
		add_child(grid_map)
	_ensure_mesh_library()

func _ensure_mesh_library() -> void:
	if is_instance_valid(grid_map) and grid_map.mesh_library == null:
		if ResourceLoader.exists("res://resources/mesh_libraries/ruins_mesh_library.meshlib"):
			grid_map.mesh_library = load("res://resources/mesh_libraries/ruins_mesh_library.meshlib")

func build_grid_map(dungeon_data: Dictionary) -> GridMap:
	if not is_instance_valid(grid_map):
		grid_map = GridMap.new()
		add_child(grid_map)

	_ensure_mesh_library()
	grid_map.clear()

	var grid: Dictionary = dungeon_data.get("grid", {})
	var width: int = dungeon_data.get("grid_width", 32)
	var depth: int = dungeon_data.get("grid_depth", 32)

	# Place floor tiles at y = 0
	for pos in grid.keys():
		var tile_type: int = grid[pos]
		if Catalog.is_walkable(tile_type):
			grid_map.set_cell_item(Vector3i(pos.x, 0, pos.y), Catalog.TILE_FLOOR, 0)

	# Place wall tiles around walkable boundaries
	for x in range(width):
		for z in range(depth):
			var pos := Vector2i(x, z)
			var tile_type: int = grid.get(pos, Catalog.TILE_WALL_STRAIGHT)
			if not Catalog.is_walkable(tile_type):
				var neighbor_mask := _compute_floor_neighbor_mask(grid, pos)
				if neighbor_mask > 0:
					place_wall_cell(Vector3i(x, 0, z), neighbor_mask)

	return grid_map

func _compute_floor_neighbor_mask(grid: Dictionary, pos: Vector2i) -> int:
	var mask := 0
	if Catalog.is_walkable(grid.get(pos + Vector2i(0, -1), Catalog.TILE_EMPTY)):
		mask |= N
	if Catalog.is_walkable(grid.get(pos + Vector2i(1, 0), Catalog.TILE_EMPTY)):
		mask |= E
	if Catalog.is_walkable(grid.get(pos + Vector2i(0, 1), Catalog.TILE_EMPTY)):
		mask |= S
	if Catalog.is_walkable(grid.get(pos + Vector2i(-1, 0), Catalog.TILE_EMPTY)):
		mask |= W
	return mask

func place_wall_cell(grid_pos: Vector3i, neighbor_mask: int) -> void:
	if not is_instance_valid(grid_map):
		return

	var placement := Catalog.resolve_wall_placement(neighbor_mask)
	grid_map.set_cell_item(grid_pos, placement.item, placement.orientation)
