extends GutTest

const MANIFEST_PATH := "res://assets/asset_manifest.json"

# Key scene paths to audit for assigned sprites
const SCENES_TO_AUDIT := {
	"Player": "res://scenes/characters/player.tscn",
	"Enemy": "res://scenes/characters/enemy_patrol.tscn",
	"NPC_Wanderer": "res://scenes/characters/npc_wanderer.tscn",
	"NPC_Shopkeeper": "res://scenes/characters/npc_shopkeeper.tscn",
	"Door": "res://scenes/props/door.tscn",
	"AnchorStone": "res://scenes/props/anchor_stone.tscn",
	"RespawnBed": "res://scenes/props/respawn_bed.tscn",
	"HUD": "res://scenes/ui/hud.tscn"
}

func test_all_manifest_assets_exist_on_disk() -> void:
	assert_true(FileAccess.file_exists(MANIFEST_PATH), "Asset manifest must exist at " + MANIFEST_PATH)

	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	var json_str := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_err := json.parse(json_str)
	assert_eq(parse_err, OK, "Manifest JSON must parse successfully")

	var data: Dictionary = json.data
	var categories: Dictionary = data.get("categories", {})

	for category_name in categories:
		var items: Array = categories[category_name]
		for item in items:
			var rel_path: String = "res://" + item["relative_path"]
			assert_true(ResourceLoader.exists(rel_path), "Asset file missing from disk: %s" % rel_path)
			var texture = load(rel_path)
			assert_not_null(texture, "Asset failed to load as valid Texture2D: %s" % rel_path)
			if texture is Texture2D:
				assert_gt(texture.get_width(), 0, "Texture width must be greater than 0: %s" % rel_path)
				assert_gt(texture.get_height(), 0, "Texture height must be greater than 0: %s" % rel_path)

func test_scenes_do_not_use_placeholder_color_rects_and_have_textures() -> void:
	for scene_name in SCENES_TO_AUDIT:
		var scene_path: String = SCENES_TO_AUDIT[scene_name]
		assert_true(ResourceLoader.exists(scene_path), "Scene file should exist on disk: %s" % scene_path)
		if not ResourceLoader.exists(scene_path):
			continue

		var packed_scene: PackedScene = load(scene_path)
		assert_not_null(packed_scene, "Scene should load: %s" % scene_path)
		var instance = packed_scene.instantiate()
		add_child_autoqfree(instance)

		# Ensure no placeholder ColorRect is acting as the primary character visual
		var color_rect = instance.find_child("ColorRect", true, false)
		assert_null(color_rect, "Scene '%s' is still using a placeholder ColorRect" % scene_name)

		# Verify that Sprite2D or AnimatedSprite2D exists and is populated
		var sprite = instance.find_child("*Sprite*", true, false)
		var texture_rect = instance.find_child("*TextureRect*", true, false)

		var has_visual := false
		if sprite is Sprite2D:
			assert_not_null(sprite.texture, "Sprite2D in '%s' has null texture" % scene_name)
			has_visual = true
		elif sprite is AnimatedSprite2D:
			assert_not_null(sprite.sprite_frames, "AnimatedSprite2D in '%s' has null sprite_frames" % scene_name)
			assert_gt(sprite.sprite_frames.get_animation_names().size(), 0, "AnimatedSprite2D in '%s' has no animations" % scene_name)
			has_visual = true
		elif texture_rect is TextureRect:
			assert_not_null(texture_rect.texture, "TextureRect in '%s' has null texture" % scene_name)
			has_visual = true

		assert_true(has_visual, "Scene '%s' does not have a configured Sprite2D, AnimatedSprite2D, or TextureRect" % scene_name)
