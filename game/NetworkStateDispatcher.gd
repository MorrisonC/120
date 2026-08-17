extends Node

@export var port: int = 8080
var tcp_server: TCPServer = TCPServer.new()
var peers = []

func _ready():
    if name == "NetworkStateDispatcher":
        if tcp_server.listen(port) != OK:
            print("Unable to start WebSocket server on port ", port)
            set_process(false)
            set_physics_process(false)
            return
        print("WebSocket server started on port ", port)
    else:
        var bound = false
        for test_port in range(18080, 18180):
            if tcp_server.listen(test_port) == OK:
                port = test_port
                bound = true
                print("Test WebSocket server started on port ", port)
                break
        if not bound:
            print("Unable to start test WebSocket server")
            set_process(false)
            set_physics_process(false)

func _process(_delta):
    if not tcp_server.is_listening():
        return

    if tcp_server.is_connection_available():
        var tcp_peer: StreamPeerTCP = tcp_server.take_connection()
        var ws_peer: WebSocketPeer = WebSocketPeer.new()
        ws_peer.accept_stream(tcp_peer)
        peers.append(ws_peer)
        print("New connection added")

    for i in range(peers.size() - 1, -1, -1):
        var peer: WebSocketPeer = peers[i]
        peer.poll()
        var state = peer.get_ready_state()

        if state == WebSocketPeer.STATE_OPEN:
            while peer.get_available_packet_count() > 0:
                var packet = peer.get_packet()
                var payload = packet.get_string_from_utf8()
                _handle_packet(peer, payload)
        elif state == WebSocketPeer.STATE_CLOSED:
            print("Connection closed")
            peers.remove_at(i)

func _handle_packet(_peer: WebSocketPeer, payload: String):
    var json = JSON.new()
    var err = json.parse(payload)
    if err == OK:
        var data = json.get_data()
        if typeof(data) == TYPE_DICTIONARY:
            if data.has("type") and data["type"] == "input":
                # Handle inputs here
                pass

func broadcast_state():
    if peers.is_empty():
        return

    var ticks = 0
    var time_rem = 120.0
    var player_pos = {"x": 0, "y": 0}

    var time_manager = get_node_or_null("/root/TimeManager")
    if is_instance_valid(time_manager):
        if "ticks_elapsed" in time_manager:
            ticks = time_manager.ticks_elapsed
        if "remaining_time" in time_manager:
            time_rem = time_manager.remaining_time

    var game_state = get_node_or_null("/root/GameState")
    if is_instance_valid(game_state) and "active_spawn_point" in game_state:
        player_pos = {"x": game_state.active_spawn_point.x, "y": game_state.active_spawn_point.y}

    var state_snapshot = {
        "type": "state",
        "tick": ticks,
        "time_remaining": time_rem,
        "player_pos": player_pos
    }

    var json_str = JSON.stringify(state_snapshot)
    var utf8_buf = json_str.to_utf8_buffer()

    for peer in peers:
        if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
            peer.put_packet(utf8_buf)

func _physics_process(_delta):
    if tcp_server.is_listening():
        broadcast_state()
