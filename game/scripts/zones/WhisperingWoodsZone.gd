extends Node3D

class_name WhisperingWoodsZone

@export var enemies_node_path: NodePath = "WolfDenEnemies"
var _defeated_count: int = 0
var _total_enemies: int = 3

func _ready() -> void:
	var enemies_parent = get_node_or_null(enemies_node_path)
	if enemies_parent:
		_total_enemies = enemies_parent.get_child_count()
		for enemy in enemies_parent.get_children():
			if enemy.has_signal("enemy_defeated"):
				enemy.enemy_defeated.connect(_on_wolf_enemy_defeated)

func _on_wolf_enemy_defeated() -> void:
	_defeated_count += 1
	if _defeated_count >= _total_enemies:
		var gs = get_node_or_null("/root/GameState")
		if gs != null and gs.has_method("advance_quest"):
			gs.advance_quest("hunter_wolves", 1)
		var hud = get_tree().root.find_child("HUD", true, false) if (get_tree() and get_tree().root) else null
		if hud and hud.has_method("show_banner"):
			hud.show_banner("Quest Complete: Feral Den Cleared!")
