extends "res://addons/gut/test.gd"

func test_godot_project_initialized():
	assert_true(true, "Project is initialized and tests are running.")

func test_main_scene_instantiates_first_area_ruins():
	var main_scene = load("res://Main.tscn").instantiate()
	add_child_autoqfree(main_scene)

	var ruins_child = main_scene.get_node_or_null("FirstAreaRuinsDungeon")
	assert_not_null(ruins_child, "Main scene must instantiate FirstAreaRuinsDungeon as first play area")

	var player_node = main_scene.get_node_or_null("Player")
	assert_not_null(player_node, "Main scene must spawn player node")
