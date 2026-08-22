@tool
extends EditorPlugin

class_name GodotMCPBridge

func _enter_tree():
    print("[GodotMCPBridge] Plugin enabled.")

func _exit_tree():
    print("[GodotMCPBridge] Plugin disabled.")

static func get_scene_tree_snapshot(root_node: Node) -> Dictionary:
    if not is_instance_valid(root_node):
        return {}
    var tree_data = {"name": root_node.name, "type": root_node.get_class(), "children": []}
    for child in root_node.get_children():
        tree_data["children"].append(get_scene_tree_snapshot(child))
    return tree_data

static func run_test_scenario(scene_node: Node) -> Dictionary:
    if not is_instance_valid(scene_node):
        return {"status": "failed", "reason": "invalid_scene_node"}
    var player = scene_node.get_node_or_null("Player")
    if is_instance_valid(player):
        return {
            "status": "passed",
            "player_position": player.global_position,
            "player_health": player.current_health if "current_health" in player else 0
        }
    return {"status": "failed", "reason": "player_node_not_found"}
