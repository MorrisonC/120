extends Node

# Autoload: WorldGraph

static var instance = null

func _ready() -> void:
	instance = self

# Hub-and-spoke adjacency graph of zones, houses, waypoints, and shortcuts.
# Backs the fast-travel menu, minimap, and design-time / GUT solvability verification (GDD §5.2 & §12).

var zones: Dictionary = {
	"OverworldVillage": {
		"display_name": "Overworld Village",
		"theme": "hub",
		"required_item": "",
		"houses": ["house_village_1"],
		"waypoints": ["waypoint_village"],
		"critical_path_seconds": 25.0,
		"return_seconds_initial": 25.0,
		"return_seconds_shortcut": 10.0,
		"nearest_house": "house_village_1"
	},
	"WhisperingWoods": {
		"display_name": "Whispering Woods",
		"theme": "forest",
		"required_item": "Sword",
		"houses": ["house_woods_1"],
		"waypoints": ["waypoint_woods"],
		"critical_path_seconds": 45.0,
		"return_seconds_initial": 40.0,
		"return_seconds_shortcut": 15.0,
		"nearest_house": "house_woods_1"
	},
	"AshenRuins": {
		"display_name": "Ashen Ruins",
		"theme": "dungeon",
		"required_item": "Lantern",
		"houses": ["house_ruins_1"],
		"waypoints": ["waypoint_ruins"],
		"critical_path_seconds": 55.0,
		"return_seconds_initial": 50.0,
		"return_seconds_shortcut": 20.0,
		"nearest_house": "house_ruins_1"
	},
	"SunkenMarsh": {
		"display_name": "Sunken Marsh",
		"theme": "swamp",
		"required_item": "Fins",
		"houses": ["house_marsh_1"],
		"waypoints": ["waypoint_marsh"],
		"critical_path_seconds": 60.0,
		"return_seconds_initial": 55.0,
		"return_seconds_shortcut": 22.0,
		"nearest_house": "house_marsh_1"
	},
	"OldQuarry": {
		"display_name": "Old Quarry",
		"theme": "cliff",
		"required_item": "Grapple",
		"houses": ["house_quarry_1"],
		"waypoints": ["waypoint_quarry"],
		"critical_path_seconds": 65.0,
		"return_seconds_initial": 60.0,
		"return_seconds_shortcut": 25.0,
		"nearest_house": "house_quarry_1"
	},
	"Frostpeak": {
		"display_name": "Frostpeak",
		"theme": "mountain",
		"required_item": "WarmCloak",
		"houses": ["house_frost_1"],
		"waypoints": ["waypoint_frost"],
		"critical_path_seconds": 70.0,
		"return_seconds_initial": 65.0,
		"return_seconds_shortcut": 28.0,
		"nearest_house": "house_frost_1"
	},
	"TheHollow": {
		"display_name": "The Hollow",
		"theme": "final_dungeon",
		"required_item": "MasterKey",
		"houses": ["house_hollow_1"],
		"waypoints": ["waypoint_hollow"],
		"critical_path_seconds": 80.0,
		"return_seconds_initial": 75.0,
		"return_seconds_shortcut": 30.0,
		"nearest_house": "house_hollow_1"
	}
}

var houses: Dictionary = {
	"house_village_1": {
		"zone": "OverworldVillage",
		"position": Vector3(0.0, 1.0, 0.0),
		"display_name": "Starting Cabin"
	},
	"house_ruins_1": {
		"zone": "AshenRuins",
		"position": Vector3(100.0, 1.0, 0.0),
		"display_name": "Crypt Respite"
	},
	"house_woods_1": {
		"zone": "WhisperingWoods",
		"position": Vector3(0.0, 1.0, 100.0),
		"display_name": "Hunter's Shack"
	},
	"house_marsh_1": {
		"zone": "SunkenMarsh",
		"position": Vector3(-100.0, 1.0, 0.0),
		"display_name": "Bog Haven"
	},
	"house_quarry_1": {
		"zone": "OldQuarry",
		"position": Vector3(0.0, 1.0, -100.0),
		"display_name": "Miner's Rest"
	},
	"house_frost_1": {
		"zone": "Frostpeak",
		"position": Vector3(80.0, 10.0, -80.0),
		"display_name": "Shelter Peak"
	},
	"house_hollow_1": {
		"zone": "TheHollow",
		"position": Vector3(0.0, -20.0, 0.0),
		"display_name": "Sanctum Door"
	}
}

var waypoints: Dictionary = {
	"waypoint_village": {
		"zone": "OverworldVillage",
		"position": Vector3(8.0, 1.0, 6.0),
		"display_name": "Village Waypoint Shrine"
	},
	"waypoint_ruins": {
		"zone": "AshenRuins",
		"position": Vector3(112.0, 1.0, 12.0),
		"display_name": "Ashen Waypoint Shrine"
	},
	"waypoint_woods": {
		"zone": "WhisperingWoods",
		"position": Vector3(10.0, 1.0, 115.0),
		"display_name": "Grove Waypoint Shrine"
	},
	"waypoint_marsh": {
		"zone": "SunkenMarsh",
		"position": Vector3(-95.0, 1.0, 10.0),
		"display_name": "Marsh Waypoint Shrine"
	},
	"waypoint_quarry": {
		"zone": "OldQuarry",
		"position": Vector3(15.0, 1.0, -90.0),
		"display_name": "Quarry Waypoint Shrine"
	},
	"waypoint_frost": {
		"zone": "Frostpeak",
		"position": Vector3(90.0, 10.0, -70.0),
		"display_name": "Peak Waypoint Shrine"
	},
	"waypoint_hollow": {
		"zone": "TheHollow",
		"position": Vector3(5.0, -20.0, 10.0),
		"display_name": "Sanctum Waypoint Shrine"
	}
}

func get_waypoint_positions(only_activated: bool = true) -> Dictionary:
	var result: Dictionary = {}
	var game_state = get_node_or_null("/root/GameState") if is_inside_tree() else null
	for wp_id in waypoints.keys():
		var id_sname: StringName = StringName(wp_id)
		if only_activated:
			if is_instance_valid(game_state) and not game_state.is_waypoint_activated(id_sname):
				continue
		result[wp_id] = waypoints[wp_id]
	return result

func is_zone_solvable_from_nearest_house(zone_id: String, max_loop_time: float = 100.0) -> bool:
	if not zones.has(zone_id):
		return false
	var z = zones[zone_id]
	return z["critical_path_seconds"] <= max_loop_time

func has_faster_backtrack_route(zone_id: String) -> bool:
	if not zones.has(zone_id):
		return false
	var z = zones[zone_id]
	return z["return_seconds_shortcut"] < z["return_seconds_initial"]

func validate_all_zones(max_loop_time: float = 100.0) -> Dictionary:
	var report = {
		"all_solvable": true,
		"all_backtrackable": true,
		"failed_zones": []
	}
	for zid in zones.keys():
		var solvable = is_zone_solvable_from_nearest_house(zid, max_loop_time)
		var backtrack = has_faster_backtrack_route(zid)
		if not solvable or not backtrack:
			report.all_solvable = report.all_solvable and solvable
			report.all_backtrackable = report.all_backtrackable and backtrack
			report.failed_zones.append({
				"zone": zid,
				"solvable": solvable,
				"backtrackable": backtrack
			})
	return report
