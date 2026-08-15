extends Node

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    if OS.has_feature("web"):
        JavaScriptBridge.eval("window.godotEngineReady = true;")
        print("Godot engine reported ready to JS via bridge.")

func _process(delta):
    if OS.has_feature("web"):
        var has_bridge = JavaScriptBridge.eval("typeof window.testBridgeCommand !== 'undefined'")
        if has_bridge:
            var js_command = JavaScriptBridge.eval("window.testBridgeCommand")
            if typeof(js_command) == TYPE_STRING and js_command != "":
                JavaScriptBridge.eval("window.testBridgeCommand = ''")
                # Defer the command so that it executes outside the JS callback
                call_deferred("_execute_command", js_command)

func _execute_command(cmd: String):
    print("Executing bridge command: ", cmd)
    var parts = cmd.split(":")
    var action = parts[0]

    if action == "start":
        get_tree().change_scene_to_file("res://Main.tscn")

    elif action == "teleport":
        var room_id = parts[1]
        var pwd = get_node_or_null("/root/ProceduralWorldGenerator")
        var player = get_node_or_null("/root/Main/Player")
        var wb = get_node_or_null("/root/Main")
        if pwd and player and wb:
            var pos = wb.assign_positions(pwd.rooms, pwd.start_node_id)
            if pos.has(room_id):
                player.global_position = pos[room_id]

    elif action == "give_item":
        var item = parts[1]
        var gs = get_node_or_null("/root/GameState")
        if gs:
            gs.add_key_item(item)

    elif action == "time_warn":
        var tm = get_node_or_null("/root/TimeManager")
        if tm:
            tm.remaining_time = tm.WARNING_TIME - 1.0

    elif action == "time_kill":
        var tm = get_node_or_null("/root/TimeManager")
        if tm:
            tm.remaining_time = 0.0

    elif action == "touch_enemy":
        var player = get_node_or_null("/root/Main/Player")
        if player and player.has_method("die"):
            player.die("Touched Enemy")

    elif action == "seed":
        var seed_val = parts[1].to_int()
        seed(seed_val)
        var pwd = get_node_or_null("/root/ProceduralWorldGenerator")
        if pwd:
            pwd.generate_valid_world()
            var wb = get_node_or_null("/root/Main")
            if wb:
                # Need to clear old tiles and rebuild
                wb.get_node("FloorLayer").clear()
                wb.get_node("WallLayer").clear()
                for c in wb.get_children():
                    if c.is_in_group("enemies"): c.queue_free()
                wb.build_world_visuals(pwd)

    elif action == "dismiss_summary":
        var sum = get_node_or_null("/root/Main/SummaryScreen")
        if sum:
            sum.hide()
            get_tree().paused = false
