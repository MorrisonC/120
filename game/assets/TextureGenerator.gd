extends RefCounted

static func create_player_texture() -> Texture2D:
	if ResourceLoader.exists("res://assets/sprites/characters/player_idle_front.png"):
		return load("res://assets/sprites/characters/player_idle_front.png")
	return null

static func create_checkpoint_texture() -> Texture2D:
	if ResourceLoader.exists("res://assets/sprites/props/anchor_stone_16.png"):
		return load("res://assets/sprites/props/anchor_stone_16.png")
	return create_fallback_tile(Color(0.2, 0.8, 0.3))

static func create_monster_texture() -> Texture2D:
	if ResourceLoader.exists("res://assets/sprites/characters/enemy_patrol_1.png"):
		return load("res://assets/sprites/characters/enemy_patrol_1.png")
	return create_fallback_tile(Color(0.8, 0.2, 0.2))

static func create_heart_texture() -> Texture2D:
	if ResourceLoader.exists("res://assets/ui/hud/hud_heart_full.png"):
		return load("res://assets/ui/hud/hud_heart_full.png")
	return create_fallback_tile(Color(0.9, 0.1, 0.2))

static func create_grass_texture() -> ImageTexture:
	return create_biome_ground_texture(0)

static func create_fallback_tile(base_color: Color) -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var shade = base_color
			if (x + y) % 4 == 0:
				shade = base_color.darkened(0.15)
			img.set_pixel(x, y, shade)
	return ImageTexture.create_from_image(img)

static func create_biome_ground_texture(biome: int) -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var bg: Color
	var detail: Color

	match biome:
		0: # Village
			bg = Color(0.22, 0.52, 0.22)
			detail = Color(0.15, 0.42, 0.15)
		1: # Desert
			bg = Color(0.88, 0.76, 0.42)
			detail = Color(0.80, 0.68, 0.35)
		2: # Swamp
			bg = Color(0.28, 0.38, 0.22)
			detail = Color(0.18, 0.28, 0.14)
		3: # Caves
			bg = Color(0.25, 0.28, 0.35)
			detail = Color(0.18, 0.20, 0.28)
		4: # Sea
			bg = Color(0.15, 0.42, 0.72)
			detail = Color(0.32, 0.62, 0.88)
		5: # Factory
			bg = Color(0.38, 0.42, 0.48)
			detail = Color(0.28, 0.32, 0.38)
		_:
			bg = Color(0.3, 0.3, 0.3)
			detail = Color(0.2, 0.2, 0.2)

	for y in range(16):
		for x in range(16):
			var col = bg
			if (x * 7 + y * 13) % 11 < 3:
				col = detail
			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func create_biome_path_texture(biome: int) -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var bg: Color
	var detail: Color

	match biome:
		0: # Village cobblestone
			bg = Color(0.68, 0.55, 0.38)
			detail = Color(0.55, 0.42, 0.28)
		1: # Sandstone path
			bg = Color(0.72, 0.58, 0.32)
			detail = Color(0.58, 0.44, 0.22)
		2: # Swamp wooden plank
			bg = Color(0.42, 0.35, 0.25)
			detail = Color(0.32, 0.45, 0.22)
		3: # Slate walkway
			bg = Color(0.45, 0.48, 0.55)
			detail = Color(0.35, 0.38, 0.45)
		4: # Wooden dock pier
			bg = Color(0.62, 0.48, 0.32)
			detail = Color(0.48, 0.35, 0.22)
		5: # Metal plate path
			bg = Color(0.55, 0.58, 0.65)
			detail = Color(0.88, 0.75, 0.15)
		_:
			bg = Color(0.5, 0.5, 0.5)
			detail = Color(0.4, 0.4, 0.4)

	for y in range(16):
		for x in range(16):
			var col = bg
			if x == 0 or x == 15 or y == 0 or y == 15 or (x + y) % 5 == 0:
				col = detail
			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func create_biome_wall_texture(biome: int) -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var bg: Color
	var border: Color

	match biome:
		0: # Foliage boundary
			bg = Color(0.12, 0.35, 0.12)
			border = Color(0.08, 0.22, 0.08)
		1: # Rock cliff
			bg = Color(0.55, 0.38, 0.18)
			border = Color(0.38, 0.24, 0.10)
		2: # Swamp stump
			bg = Color(0.18, 0.24, 0.12)
			border = Color(0.10, 0.15, 0.08)
		3: # Cave rock wall
			bg = Color(0.15, 0.16, 0.22)
			border = Color(0.08, 0.08, 0.12)
		4: # Deep sea reef
			bg = Color(0.10, 0.25, 0.45)
			border = Color(0.05, 0.12, 0.28)
		5: # Steel wall
			bg = Color(0.22, 0.25, 0.30)
			border = Color(0.65, 0.68, 0.75)
		_:
			bg = Color(0.2, 0.2, 0.2)
			border = Color(0.1, 0.1, 0.1)

	for y in range(16):
		for x in range(16):
			var col = bg
			if x == 0 or x == 15 or y == 0 or y == 15 or (x % 4 == 0 and y % 4 == 0):
				col = border
			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func create_slashable_grass_texture() -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var base = Color(0.18, 0.58, 0.18)
	var blade = Color(0.28, 0.82, 0.28)
	var tip = Color(0.45, 0.95, 0.35)

	for y in range(16):
		for x in range(16):
			var col = base
			if y < 4:
				col = tip
			elif (x % 3 == 0 and y < 12) or (x % 4 == 1 and y < 14):
				col = blade
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func create_sword_texture() -> ImageTexture:
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var hilt = Color(0.55, 0.35, 0.15)
	var guard = Color(0.85, 0.75, 0.25)
	var blade = Color(0.90, 0.92, 0.98)
	var edge = Color(0.65, 0.85, 1.0, 0.85)

	for y in range(24):
		for x in range(24):
			# Diagonal sword arc blade
			if abs(x - y) <= 2 and x >= 4 and x <= 20:
				img.set_pixel(x, y, blade)
			elif abs(x - y) == 3 and x >= 3 and x <= 21:
				img.set_pixel(x, y, edge)
			elif x >= 2 and x <= 5 and y >= 2 and y <= 5:
				img.set_pixel(x, y, hilt)
			elif abs(x - y) <= 3 and x >= 5 and x <= 7:
				img.set_pixel(x, y, guard)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

static func create_biome_decor_texture(biome: int) -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var bg: Color
	var accent: Color

	match biome:
		0: # Village flowers
			bg = Color(0.22, 0.52, 0.22)
			accent = Color(0.92, 0.82, 0.22)
		1: # Cactus / Desert rock
			bg = Color(0.88, 0.76, 0.42)
			accent = Color(0.28, 0.52, 0.28)
		2: # Lilypad
			bg = Color(0.28, 0.38, 0.22)
			accent = Color(0.18, 0.62, 0.38)
		3: # Crystal
			bg = Color(0.25, 0.28, 0.35)
			accent = Color(0.40, 0.75, 0.95)
		4: # Coral
			bg = Color(0.15, 0.42, 0.72)
			accent = Color(0.92, 0.42, 0.42)
		5: # Metal valve / crate
			bg = Color(0.38, 0.42, 0.48)
			accent = Color(0.75, 0.35, 0.22)
		_:
			bg = Color(0.3, 0.3, 0.3)
			accent = Color(0.7, 0.7, 0.7)

	for y in range(16):
		for x in range(16):
			var col = bg
			# Center 6x6 accent feature
			if x >= 5 and x <= 10 and y >= 5 and y <= 10:
				col = accent
			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)
