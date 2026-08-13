extends SceneTree

func _init():
    var tileset = TileSet.new()
    tileset.tile_size = Vector2i(16, 16)

    # Add physics layer for walls
    tileset.add_physics_layer(0)

    var texture = load("res://assets/kenney_tiny_dungeon/Tilemap/tilemap_packed.png")
    if not texture:
        print("Could not load texture")
        quit()
        return

    var source = TileSetAtlasSource.new()
    source.texture = texture
    source.texture_region_size = Vector2i(16, 16)

    # We will just brute force create tiles for a wide area of the atlas
    for x in range(12):
        for y in range(12):
            source.create_tile(Vector2i(x, y))
            # Wall tiles in this set are generally in the top row or specific coords, let's assume y=0 are walls
            if y == 0:
                var tile_data = TileData.new()
                # Actually setting physics polygon programmatically in godot 4 is tricky on TileSetAtlasSource directly
                # Let's see if tile_data is accessible
                pass

    tileset.add_source(source, 0)

    # The correct way to set physics in Godot 4:
    for x in range(12):
        for y in range(12):
            if y == 0:
                var td = source.get_tile_data(Vector2i(x, y), 0)
                if td:
                    td.add_collision_polygon(0)
                    var polygon = PackedVector2Array([
                        Vector2(-8, -8), Vector2(8, -8),
                        Vector2(8, 8), Vector2(-8, 8)
                    ])
                    td.set_collision_polygon_points(0, 0, polygon)

    ResourceSaver.save(tileset, "res://GeneratedTileSet.tres")
    print("TileSet Generated!")
    quit()
