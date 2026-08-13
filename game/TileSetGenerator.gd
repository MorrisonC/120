@tool
extends EditorScript

func _run():
    var tileset = TileSet.new()
    tileset.tile_size = Vector2i(16, 16)

    # Add physics layer for walls
    tileset.add_physics_layer(0)

    var texture = load("res://assets/kenney_tiny_dungeon/Tilemap/tilemap_packed.png")
    if not texture:
        print("Could not load texture")
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
                var polygon = PackedVector2Array([
                    Vector2(-8, -8), Vector2(8, -8),
                    Vector2(8, 8), Vector2(-8, 8)
                ])
                source.tile_set_physics_polygon(Vector2i(x,y), 0, 0, polygon)

    tileset.add_source(source, 0)

    ResourceSaver.save(tileset, "res://GeneratedTileSet.tres")
    print("TileSet Generated!")
