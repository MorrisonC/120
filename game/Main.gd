extends Node2D

func _ready():
    # Make sure time manager starts running on main scene launch
    var time_mgr = get_node_or_null("/root/TimeManager")
    if is_instance_valid(time_mgr):
        time_mgr.start_loop()
