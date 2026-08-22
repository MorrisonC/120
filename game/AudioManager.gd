extends Node
class_name AudioManager

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready():
    bgm_player = AudioStreamPlayer.new()
    bgm_player.name = "BGMPlayer"
    add_child(bgm_player)

    sfx_player = AudioStreamPlayer.new()
    sfx_player.name = "SFXPlayer"
    add_child(sfx_player)

func play_biome_music(_biome_id: int):
    pass

func play_puzzle_sfx(_puzzle_type: String, _success: bool):
    pass
