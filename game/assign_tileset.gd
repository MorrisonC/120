extends SceneTree

func _init():
    var main_scene = load("res://Main.tscn")
    var state = main_scene.get_state()

    var new_scene = PackedScene.new()
    var root = main_scene.instantiate()

    var tileset = load("res://GeneratedTileSet.tres")

    var floor_layer = root.get_node("FloorLayer")
    floor_layer.tile_set = tileset

    var wall_layer = root.get_node("WallLayer")
    wall_layer.tile_set = tileset

    new_scene.pack(root)
    ResourceSaver.save(new_scene, "res://Main.tscn")
    print("Tileset Assigned to Main.tscn!")
    quit()
