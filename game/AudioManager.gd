extends Node

var audio_player: AudioStreamPlayer

var sounds = {
    "item_pickup": preload("res://assets/kenney_rpg_audio/Audio/coin.ogg"),
    "death": preload("res://assets/kenney_rpg_audio/Audio/explosion.ogg"),
    "loop_reset": preload("res://assets/kenney_rpg_audio/Audio/magic1.ogg")
}

func _ready():
    audio_player = AudioStreamPlayer.new()
    add_child(audio_player)

    var tm = get_node_or_null("/root/TimeManager")
    if tm:
        tm.connect("loop_expired", Callable(self, "_on_loop_expired"))

func play_sound(sound_name: String):
    if DisplayServer.get_name() == "headless": return
    if sounds.has(sound_name):
        audio_player.stream = sounds[sound_name]
        audio_player.play()

func _on_loop_expired():
    play_sound("loop_reset")
