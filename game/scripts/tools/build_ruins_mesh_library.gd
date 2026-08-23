@tool
extends SceneTree

# Tool script to generate and export res://resources/mesh_libraries/ruins_mesh_library.meshlib

const Catalog = preload("res://scripts/procgen/ruins/RuinsTileCatalog.gd")

func _init() -> void:
	print("[BuildRuinsMeshLibrary] Generating Ruins MeshLibrary...")
	var mesh_lib := generate_mesh_library()
	var save_path := "res://resources/mesh_libraries/ruins_mesh_library.meshlib"
	var err := ResourceSaver.save(mesh_lib, save_path)
	if err == OK:
		print("[BuildRuinsMeshLibrary] Successfully saved MeshLibrary to: ", save_path)
	else:
		print("[BuildRuinsMeshLibrary] Failed to save MeshLibrary, error code: ", err)
	quit()

static func generate_mesh_library() -> MeshLibrary:
	var mesh_lib := MeshLibrary.new()

	# Standard materials
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color("#5C6270") # Slate stone
	stone_mat.roughness = 0.8

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color("#4A505D") # Dark wall stone
	wall_mat.roughness = 0.85

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#8D5B34") # Wooden chest / doors
	wood_mat.roughness = 0.6

	var metal_mat := StandardMaterial3D.new()
	metal_mat.albedo_color = Color("#FFA726") # Brazier flame / accent
	metal_mat.emission_enabled = true
	metal_mat.emission = Color("#FFA726")
	metal_mat.emission_energy_multiplier = 1.5

	# 0: Floor Tile (1x1 unit, flat)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(1.0, 0.2, 1.0)
	floor_mesh.material = stone_mat
	_add_item_to_lib(mesh_lib, Catalog.TILE_FLOOR, "Floor", floor_mesh, BoxShape3D.new(), Vector3(1.0, 0.2, 1.0), Vector3(0, -0.1, 0))

	# 1: Wall Straight (1x2x0.2)
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(1.0, 2.0, 0.2)
	wall_mesh.material = wall_mat
	_add_item_to_lib(mesh_lib, Catalog.TILE_WALL_STRAIGHT, "WallStraight", wall_mesh, BoxShape3D.new(), Vector3(1.0, 2.0, 0.2), Vector3(0, 1.0, -0.4))

	# 2: Wall Corner In
	var corner_mesh := BoxMesh.new()
	corner_mesh.size = Vector3(0.6, 2.0, 0.6)
	corner_mesh.material = wall_mat
	_add_item_to_lib(mesh_lib, Catalog.TILE_WALL_CORNER_IN, "WallCornerIn", corner_mesh, BoxShape3D.new(), Vector3(0.6, 2.0, 0.6), Vector3(-0.2, 1.0, -0.2))

	# 3: Wall Corner Out
	var corner_out_mesh := BoxMesh.new()
	corner_out_mesh.size = Vector3(1.0, 2.0, 1.0)
	corner_out_mesh.material = wall_mat
	_add_item_to_lib(mesh_lib, Catalog.TILE_WALL_CORNER_OUT, "WallCornerOut", corner_out_mesh, BoxShape3D.new(), Vector3(1.0, 2.0, 1.0), Vector3(0, 1.0, 0))

	# 4: Wall Curve
	var curve_mesh := PrismMesh.new()
	curve_mesh.size = Vector3(1.0, 2.0, 1.0)
	curve_mesh.material = wall_mat
	_add_item_to_lib(mesh_lib, Catalog.TILE_WALL_CURVE, "WallCurve", curve_mesh, BoxShape3D.new(), Vector3(1.0, 2.0, 1.0), Vector3(0, 1.0, 0))

	# 5: Doorway
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(1.0, 2.0, 0.2)
	door_mesh.material = wood_mat
	_add_item_to_lib(mesh_lib, Catalog.TILE_DOORWAY, "Doorway", door_mesh, BoxShape3D.new(), Vector3(1.0, 2.0, 0.2), Vector3(0, 1.0, 0))

	# 6: Pillar / Column
	var pillar_mesh := CylinderMesh.new()
	pillar_mesh.top_radius = 0.2
	pillar_mesh.bottom_radius = 0.25
	pillar_mesh.height = 2.0
	pillar_mesh.material = stone_mat
	var pillar_shape := CylinderShape3D.new()
	pillar_shape.radius = 0.25
	pillar_shape.height = 2.0
	_add_custom_item_to_lib(mesh_lib, Catalog.TILE_PILLAR, "Pillar", pillar_mesh, pillar_shape, Vector3(0, 1.0, 0))

	# 7: Arch
	var arch_mesh := BoxMesh.new()
	arch_mesh.size = Vector3(1.0, 0.4, 0.4)
	arch_mesh.material = stone_mat
	_add_item_to_lib(mesh_lib, Catalog.TILE_ARCH, "Arch", arch_mesh, BoxShape3D.new(), Vector3(1.0, 0.4, 0.4), Vector3(0, 1.8, 0))

	# 8: Stairs
	var stairs_mesh := PrismMesh.new()
	stairs_mesh.size = Vector3(1.0, 1.0, 1.0)
	stairs_mesh.material = stone_mat
	_add_item_to_lib(mesh_lib, Catalog.TILE_STAIRS, "Stairs", stairs_mesh, BoxShape3D.new(), Vector3(1.0, 1.0, 1.0), Vector3(0, 0.5, 0))

	# 9: Prop Chest
	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.5, 0.4, 0.4)
	chest_mesh.material = wood_mat
	_add_item_to_lib(mesh_lib, Catalog.TILE_PROP_CHEST, "PropChest", chest_mesh, BoxShape3D.new(), Vector3(0.5, 0.4, 0.4), Vector3(0, 0.2, 0))

	# 10: Prop Brazier
	var brazier_mesh := CylinderMesh.new()
	brazier_mesh.top_radius = 0.3
	brazier_mesh.bottom_radius = 0.2
	brazier_mesh.height = 0.8
	brazier_mesh.material = metal_mat
	var brazier_shape := CylinderShape3D.new()
	brazier_shape.radius = 0.3
	brazier_shape.height = 0.8
	_add_custom_item_to_lib(mesh_lib, Catalog.TILE_PROP_BRAZIER, "PropBrazier", brazier_mesh, brazier_shape, Vector3(0, 0.4, 0))

	# 11: Prop Rubble
	var rubble_mesh := BoxMesh.new()
	rubble_mesh.size = Vector3(0.6, 0.2, 0.6)
	rubble_mesh.material = stone_mat
	_add_item_to_lib(mesh_lib, Catalog.TILE_PROP_RUBBLE, "PropRubble", rubble_mesh, BoxShape3D.new(), Vector3(0.6, 0.2, 0.6), Vector3(0, 0.1, 0))

	return mesh_lib

static func _add_item_to_lib(lib: MeshLibrary, id: int, item_name: String, mesh: Mesh, box_shape: BoxShape3D, box_size: Vector3, offset: Vector3) -> void:
	box_shape.size = box_size
	_add_custom_item_to_lib(lib, id, item_name, mesh, box_shape, offset)

static func _add_custom_item_to_lib(lib: MeshLibrary, id: int, item_name: String, mesh: Mesh, shape: Shape3D, offset: Vector3) -> void:
	lib.create_item(id)
	lib.set_item_name(id, item_name)
	lib.set_item_mesh(id, mesh)
	var xform := Transform3D(Basis(), offset)
	lib.set_item_shapes(id, [shape, xform])
