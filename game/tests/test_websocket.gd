extends "res://addons/gut/test.gd"

var NetworkStateDispatcher = load("res://NetworkStateDispatcher.gd")
var dispatcher = null

func before_each():
    dispatcher = NetworkStateDispatcher.new()
    add_child_autoqfree(dispatcher)
    await get_tree().process_frame

func after_each():
    if is_instance_valid(dispatcher):
        if dispatcher.tcp_server.is_listening():
            dispatcher.tcp_server.stop()
        dispatcher.peers.clear()

func test_server_starts():
    assert_true(dispatcher.tcp_server.is_listening(), "TCP Server should be listening")

func test_broadcast_no_peers():
    dispatcher.broadcast_state()
    assert_true(true, "Broadcast without peers didn't crash")
