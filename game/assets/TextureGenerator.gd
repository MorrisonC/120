extends RefCounted

static func create_player_texture() -> Texture2D:
	if ResourceLoader.exists("res://assets/sprites/characters/player_idle_front.png"):
		return load("res://assets/sprites/characters/player_idle_front.png")
	return null

static func create_checkpoint_texture() -> Texture2D:
	if ResourceLoader.exists("res://assets/sprites/props/anchor_stone_16.png"):
		return load("res://assets/sprites/props/anchor_stone_16.png")
	return null

static func create_monster_texture() -> Texture2D:
	if ResourceLoader.exists("res://assets/sprites/characters/enemy_patrol_1.png"):
		return load("res://assets/sprites/characters/enemy_patrol_1.png")
	return null
