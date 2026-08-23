extends RefCounted
class_name RuinsTileCatalog

# Tile Type Constants
const TILE_EMPTY: int = -1
const TILE_FLOOR: int = 0
const TILE_WALL_STRAIGHT: int = 1
const TILE_WALL_CORNER_IN: int = 2
const TILE_WALL_CORNER_OUT: int = 3
const TILE_WALL_CURVE: int = 4
const TILE_DOORWAY: int = 5
const TILE_PILLAR: int = 6
const TILE_ARCH: int = 7
const TILE_STAIRS: int = 8
const TILE_PROP_CHEST: int = 9
const TILE_PROP_BRAZIER: int = 10
const TILE_PROP_RUBBLE: int = 11

# Neighbor Bitmask Flags
const N: int = 1
const E: int = 2
const S: int = 4
const W: int = 8

# Quaternius GridMap orientation lookup mapping
# Godot 4 GridMap cell orientation indices:
# 0 = 0 deg Y, 22 = 90 deg Y, 10 = 180 deg Y, 16 = 270 deg Y
static func resolve_wall_placement(neighbor_mask: int) -> Dictionary:
	match neighbor_mask:
		N:
			return {"item": TILE_WALL_STRAIGHT, "orientation": 0}
		E:
			return {"item": TILE_WALL_STRAIGHT, "orientation": 22}
		S:
			return {"item": TILE_WALL_STRAIGHT, "orientation": 10}
		W:
			return {"item": TILE_WALL_STRAIGHT, "orientation": 16}
		N | E:
			return {"item": TILE_WALL_CORNER_IN, "orientation": 0}
		E | S:
			return {"item": TILE_WALL_CORNER_IN, "orientation": 22}
		S | W:
			return {"item": TILE_WALL_CORNER_IN, "orientation": 10}
		W | N:
			return {"item": TILE_WALL_CORNER_IN, "orientation": 16}
		N | S:
			return {"item": TILE_WALL_STRAIGHT, "orientation": 0}
		E | W:
			return {"item": TILE_WALL_STRAIGHT, "orientation": 22}
		N | E | S:
			return {"item": TILE_WALL_CORNER_OUT, "orientation": 0}
		E | S | W:
			return {"item": TILE_WALL_CORNER_OUT, "orientation": 22}
		S | W | N:
			return {"item": TILE_WALL_CORNER_OUT, "orientation": 10}
		W | N | E:
			return {"item": TILE_WALL_CORNER_OUT, "orientation": 16}
		_:
			return {"item": TILE_PILLAR, "orientation": 0}

static func is_walkable(tile_type: int) -> bool:
	match tile_type:
		TILE_FLOOR, TILE_DOORWAY, TILE_ARCH, TILE_STAIRS:
			return true
		_:
			return false

static func is_wall(tile_type: int) -> bool:
	match tile_type:
		TILE_WALL_STRAIGHT, TILE_WALL_CORNER_IN, TILE_WALL_CORNER_OUT, TILE_WALL_CURVE, TILE_PILLAR:
			return true
		_:
			return false

static func get_tile_name(tile_type: int) -> String:
	match tile_type:
		TILE_FLOOR: return "Floor"
		TILE_WALL_STRAIGHT: return "WallStraight"
		TILE_WALL_CORNER_IN: return "WallCornerIn"
		TILE_WALL_CORNER_OUT: return "WallCornerOut"
		TILE_WALL_CURVE: return "WallCurve"
		TILE_DOORWAY: return "Doorway"
		TILE_PILLAR: return "Pillar"
		TILE_ARCH: return "Arch"
		TILE_STAIRS: return "Stairs"
		TILE_PROP_CHEST: return "PropChest"
		TILE_PROP_BRAZIER: return "PropBrazier"
		TILE_PROP_RUBBLE: return "PropRubble"
		_: return "Empty"
