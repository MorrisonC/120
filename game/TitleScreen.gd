extends CanvasLayer

func _ready():
    print("TitleScreen _ready!")
    var color_rect = get_node_or_null("ColorRect")
    if color_rect:
        color_rect.color = Color(0.0, 1.0, 0.0, 1.0) # GREEN for testing
    var label = get_node_or_null("VBoxContainer/Label")
    if label:
        label.text = "READY TO START"

func _process(delta):
    var color_rect = get_node_or_null("ColorRect")
    if color_rect:
        color_rect.color = Color(0.0, 1.0, 0.0, 1.0) # GREEN for testing

    if OS.has_feature("web"):
        # Make sure we declare ready to JS in a way that handles initial lag
        JavaScriptBridge.eval("window.godotEngineReady = true;")

func _input(event):
    if event is InputEventKey or event is InputEventMouseButton:
        if event.is_pressed():
            print("TitleScreen received input, changing scene!")
            get_tree().change_scene_to_file("res://Main.tscn")
