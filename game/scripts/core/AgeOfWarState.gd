extends Node

signal gold_changed(new_gold: int)
signal xp_changed(new_xp: int)
signal era_changed(is_player: bool, new_era: int)
signal player_base_hp_changed(current: float, max_hp: float)
signal enemy_base_hp_changed(current: float, max_hp: float)
signal special_cooldown_changed(is_player: bool, remaining: float, max_cd: float)
signal game_over(player_won: bool)

# Player State
var player_gold: int = 150
var player_xp: int = 0
var player_era: int = 0 # 0: Stone, 1: Medieval, 2: Renaissance, 3: Modern, 4: Future
var player_base_hp: float = 5000.0
var player_base_max_hp: float = 5000.0
var player_special_cd: float = 0.0

# Enemy State
var enemy_gold: int = 150
var enemy_xp: int = 0
var enemy_era: int = 0
var enemy_base_hp: float = 5000.0
var enemy_base_max_hp: float = 5000.0
var enemy_special_cd: float = 0.0

# Turrets state (3 slots max per base)
var player_turrets: Array = [null, null, null]
var enemy_turrets: Array = [null, null, null]

const SPECIAL_COOLDOWN_MAX: float = 30.0

# Era Data
const ERA_NAMES: Array = ["Stone Age", "Medieval Age", "Renaissance Age", "Modern Age", "Future Age"]
const ERA_EVOLVE_COSTS: Array = [4000, 14000, 45000, 200000, 0]

# Units Database
const ERA_UNITS: Array = [
	# Era 0: Stone Age
	[
		{"id": "clubman", "name": "Clubman", "cost": 15, "hp": 50.0, "damage": 8.0, "range": 1.5, "speed": 3.0, "type": "melee", "model": "res://assets/models/characters/Farmer.glb", "scale": 1.0},
		{"id": "slingshot", "name": "Slingshot", "cost": 25, "hp": 35.0, "damage": 6.0, "range": 8.0, "speed": 2.8, "type": "ranged", "model": "res://assets/models/characters/CowboyHat.glb", "scale": 1.0},
		{"id": "dinorider", "name": "Dino Rider", "cost": 100, "hp": 180.0, "damage": 20.0, "range": 1.8, "speed": 3.5, "type": "heavy", "model": "res://assets/models/enemies/RaptorEnemy.glb", "scale": 1.2}
	],
	# Era 1: Medieval Age
	[
		{"id": "swordsman", "name": "Swordsman", "cost": 50, "hp": 100.0, "damage": 15.0, "range": 1.5, "speed": 3.0, "type": "melee", "model": "res://assets/models/characters/knight.glb", "scale": 1.0},
		{"id": "archer", "name": "Archer", "cost": 75, "hp": 60.0, "damage": 12.0, "range": 10.0, "speed": 2.8, "type": "ranged", "model": "res://assets/models/enemies/skeleton_archer.glb", "scale": 1.0},
		{"id": "knight", "name": "Knight", "cost": 500, "hp": 450.0, "damage": 45.0, "range": 2.0, "speed": 3.8, "type": "heavy", "model": "res://assets/models/characters/KnightCharacter.glb", "scale": 1.3}
	],
	# Era 2: Renaissance Age
	[
		{"id": "duelist", "name": "Duelist", "cost": 200, "hp": 220.0, "damage": 35.0, "range": 1.5, "speed": 3.2, "type": "melee", "model": "res://assets/models/characters/rogue.glb", "scale": 1.0},
		{"id": "musketeer", "name": "Musketeer", "cost": 400, "hp": 140.0, "damage": 30.0, "range": 12.0, "speed": 2.8, "type": "ranged", "model": "res://assets/models/characters/Adventurer.glb", "scale": 1.0},
		{"id": "cannoneer", "name": "Cannoneer", "cost": 1000, "hp": 600.0, "damage": 80.0, "range": 7.0, "speed": 2.2, "type": "heavy", "model": "res://assets/models/enemies/skeleton_warrior.glb", "scale": 1.4}
	],
	# Era 3: Modern Age
	[
		{"id": "melee_infantry", "name": "Commando", "cost": 1500, "hp": 500.0, "damage": 70.0, "range": 1.8, "speed": 3.5, "type": "melee", "model": "res://assets/models/enemies/Wasp.glb", "scale": 1.2},
		{"id": "infantry", "name": "Infantry", "cost": 2000, "hp": 350.0, "damage": 60.0, "range": 12.0, "speed": 3.0, "type": "ranged", "model": "res://assets/models/enemies/Frog.glb", "scale": 1.1},
		{"id": "tank", "name": "Battle Tank", "cost": 7000, "hp": 2000.0, "damage": 180.0, "range": 10.0, "speed": 2.0, "type": "heavy", "model": "res://assets/models/enemies/Snake.glb", "scale": 1.5}
	],
	# Era 4: Future Age
	[
		{"id": "blade_unit", "name": "Blade Drone", "cost": 5000, "hp": 1200.0, "damage": 150.0, "range": 2.0, "speed": 4.0, "type": "melee", "model": "res://assets/models/enemies/Spider.glb", "scale": 1.3},
		{"id": "blaster", "name": "Plasma Blaster", "cost": 6000, "hp": 800.0, "damage": 120.0, "range": 14.0, "speed": 3.2, "type": "ranged", "model": "res://assets/models/enemies/Rat.glb", "scale": 1.2},
		{"id": "war_machine", "name": "War Machine", "cost": 20000, "hp": 5000.0, "damage": 400.0, "range": 12.0, "speed": 2.5, "type": "heavy", "model": "res://assets/models/enemies/Slime.glb", "scale": 1.6},
		{"id": "super_soldier", "name": "Super Titan", "cost": 100000, "hp": 20000.0, "damage": 1500.0, "range": 3.0, "speed": 4.5, "type": "boss", "model": "res://assets/models/characters/KnightCharacter.glb", "scale": 2.0}
	]
]

# Turrets Database per Era
const ERA_TURRETS: Array = [
	# Era 0
	[
		{"id": "slingshot_t", "name": "Rock Slingshot", "cost": 100, "damage": 10.0, "range": 12.0, "fire_rate": 1.5, "model": "res://assets/models/props/sundial_pillar.glb"},
		{"id": "egg_auto", "name": "Egg Cannon", "cost": 200, "damage": 6.0, "range": 10.0, "fire_rate": 0.5, "model": "res://assets/models/village/Well.glb"},
		{"id": "catapult_p", "name": "Primitive Catapult", "cost": 500, "damage": 40.0, "range": 15.0, "fire_rate": 3.0, "model": "res://assets/models/ruins/ruin_pillar_broken.glb"}
	],
	# Era 1
	[
		{"id": "catapult", "name": "Catapult", "cost": 500, "damage": 35.0, "range": 14.0, "fire_rate": 2.5, "model": "res://assets/models/village/Cart.glb"},
		{"id": "fire_catapult", "name": "Fire Catapult", "cost": 750, "damage": 55.0, "range": 15.0, "fire_rate": 2.5, "model": "res://assets/models/village/Barrel.glb"},
		{"id": "oil_pourer", "name": "Oil Pourer", "cost": 1000, "damage": 90.0, "range": 6.0, "fire_rate": 1.0, "model": "res://assets/models/village/Crate.glb"}
	],
	# Era 2
	[
		{"id": "small_cannon", "name": "Small Cannon", "cost": 1500, "damage": 80.0, "range": 15.0, "fire_rate": 2.0, "model": "res://assets/models/props/sundial_pillar.glb"},
		{"id": "med_cannon", "name": "Medium Cannon", "cost": 3000, "damage": 140.0, "range": 16.0, "fire_rate": 1.8, "model": "res://assets/models/props/sundial_pillar.glb"},
		{"id": "exp_cannon", "name": "Explosive Cannon", "cost": 6000, "damage": 300.0, "range": 18.0, "fire_rate": 3.0, "model": "res://assets/models/props/sundial_pillar.glb"}
	],
	# Era 3
	[
		{"id": "single_turret", "name": "Auto Turret", "cost": 7000, "damage": 200.0, "range": 16.0, "fire_rate": 1.0, "model": "res://assets/models/environment/interactive/waypoint_shrine/pylon.glb"},
		{"id": "rocket_launcher", "name": "Rocket Pod", "cost": 9000, "damage": 400.0, "range": 20.0, "fire_rate": 2.5, "model": "res://assets/models/environment/interactive/waypoint_shrine/terminal.glb"},
		{"id": "double_turret", "name": "Dual Gatling", "cost": 12000, "damage": 350.0, "range": 18.0, "fire_rate": 0.4, "model": "res://assets/models/environment/interactive/waypoint_shrine/structure.glb"}
	],
	# Era 4
	[
		{"id": "titanium_shooter", "name": "Titanium Cannon", "cost": 24000, "damage": 800.0, "range": 20.0, "fire_rate": 1.5, "model": "res://assets/models/environment/interactive/waypoint_shrine/structure.glb"},
		{"id": "laser_cannon", "name": "Laser Beam", "cost": 40000, "damage": 1500.0, "range": 22.0, "fire_rate": 1.0, "model": "res://assets/models/environment/interactive/waypoint_shrine/terminal.glb"},
		{"id": "ion_cannon", "name": "Ion Strike Turret", "cost": 100000, "damage": 4000.0, "range": 30.0, "fire_rate": 4.0, "model": "res://assets/models/environment/interactive/waypoint_shrine/pylon.glb"}
	]
]

var passive_income_timer: float = 0.0

func _process(delta: float) -> void:
	# Passive income generation
	passive_income_timer += delta
	if passive_income_timer >= 1.0:
		passive_income_timer = 0.0
		add_player_gold(5 + player_era * 5)
		enemy_gold += 5 + enemy_era * 5

	# Update Special Cooldowns
	if player_special_cd > 0.0:
		player_special_cd = max(0.0, player_special_cd - delta)
		special_cooldown_changed.emit(true, player_special_cd, SPECIAL_COOLDOWN_MAX)
	if enemy_special_cd > 0.0:
		enemy_special_cd = max(0.0, enemy_special_cd - delta)
		special_cooldown_changed.emit(false, enemy_special_cd, SPECIAL_COOLDOWN_MAX)

func add_player_gold(amount: int) -> void:
	player_gold += amount
	gold_changed.emit(player_gold)

func add_player_xp(amount: int) -> void:
	player_xp += amount
	xp_changed.emit(player_xp)

func can_evolve_player() -> bool:
	if player_era >= 4:
		return false
	return player_xp >= ERA_EVOLVE_COSTS[player_era]

func evolve_player() -> bool:
	if not can_evolve_player():
		return false
	player_era += 1
	# Increase Base Max HP & heal slightly
	player_base_max_hp += 3000.0
	player_base_hp = min(player_base_max_hp, player_base_hp + 2000.0)
	player_base_hp_changed.emit(player_base_hp, player_base_max_hp)
	era_changed.emit(true, player_era)
	return true

func can_evolve_enemy() -> bool:
	if enemy_era >= 4:
		return false
	return enemy_xp >= ERA_EVOLVE_COSTS[enemy_era]

func evolve_enemy() -> bool:
	if not can_evolve_enemy():
		return false
	enemy_era += 1
	enemy_base_max_hp += 3000.0
	enemy_base_hp = min(enemy_base_max_hp, enemy_base_hp + 2000.0)
	enemy_base_hp_changed.emit(enemy_base_hp, enemy_base_max_hp)
	era_changed.emit(false, enemy_era)
	return true

func damage_player_base(amount: float) -> void:
	player_base_hp = max(0.0, player_base_hp - amount)
	player_base_hp_changed.emit(player_base_hp, player_base_max_hp)
	if player_base_hp <= 0.0:
		game_over.emit(false)

func damage_enemy_base(amount: float) -> void:
	enemy_base_hp = max(0.0, enemy_base_hp - amount)
	enemy_base_hp_changed.emit(enemy_base_hp, enemy_base_max_hp)
	if enemy_base_hp <= 0.0:
		game_over.emit(true)

func trigger_special(is_player: bool) -> bool:
	if is_player:
		if player_special_cd > 0.0:
			return false
		player_special_cd = SPECIAL_COOLDOWN_MAX
		special_cooldown_changed.emit(true, player_special_cd, SPECIAL_COOLDOWN_MAX)
		return true
	else:
		if enemy_special_cd > 0.0:
			return false
		enemy_special_cd = SPECIAL_COOLDOWN_MAX
		special_cooldown_changed.emit(false, enemy_special_cd, SPECIAL_COOLDOWN_MAX)
		return true

func reset_game() -> void:
	player_gold = 150
	player_xp = 0
	player_era = 0
	player_base_hp = 5000.0
	player_base_max_hp = 5000.0
	player_special_cd = 0.0

	enemy_gold = 150
	enemy_xp = 0
	enemy_era = 0
	enemy_base_hp = 5000.0
	enemy_base_max_hp = 5000.0
	enemy_special_cd = 0.0

	player_turrets = [null, null, null]
	enemy_turrets = [null, null, null]

	gold_changed.emit(player_gold)
	xp_changed.emit(player_xp)
	player_base_hp_changed.emit(player_base_hp, player_base_max_hp)
	enemy_base_hp_changed.emit(enemy_base_hp, enemy_base_max_hp)
