@tool
extends SceneTree

func _init() -> void:
	print("[ScreenshotTool] Instantiating Main scene...")
	var main_scene = load("res://Main.tscn")
	if main_scene:
		var viewport = get_root()
		var main_inst = main_scene.instantiate()
		viewport.add_child(main_inst)

		print("Children of Main:")
		for child in main_inst.get_children():
			print(" - ", child.name, " (", child.get_class(), ")")
			if child is SubViewportContainer:
				for vp_child in child.get_children():
					print("   -> ", vp_child.name, " (", vp_child.get_class(), ")")
					for d_child in vp_child.get_children():
						print("      --> ", d_child.name, " (", d_child.get_class(), ")")
	quit()
