extends Node

@onready var sub_viewport = get_node_or_null("/root/Main/HUD/MinimapContainer/SubViewportContainer/SubViewport")
@onready var minimap_camera = get_node_or_null("/root/Main/HUD/MinimapContainer/SubViewportContainer/SubViewport/MinimapCamera")
@onready var player = get_node_or_null("/root/Main/Player")

func _ready():
    # To act as a minimap, the sub_viewport needs to share the 2D world of the main viewport
    if sub_viewport and player:
        sub_viewport.world_2d = player.get_viewport().world_2d

func _process(delta):
    if not minimap_camera:
        minimap_camera = get_node_or_null("/root/Main/HUD/MinimapContainer/SubViewportContainer/SubViewport/MinimapCamera")
    if not player:
        player = get_node_or_null("/root/Main/Player")

    if minimap_camera and player:
        minimap_camera.global_position = player.global_position
