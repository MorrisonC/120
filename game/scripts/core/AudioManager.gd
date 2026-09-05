extends Node

# Autoload: AudioManager

static var instance = null

var _sfx_players: Array[AudioStreamPlayer] = []
var _max_players: int = 8

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(_max_players):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

static func play_sfx(sound_name: String) -> void:
	if instance != null:
		instance._play_sfx_internal(sound_name)

func _play_sfx_internal(sound_name: String) -> void:
	var player = _get_available_player()
	if not player:
		return
	
	var stream = _generate_tone_stream(sound_name)
	if stream:
		player.stream = stream
		player.play()

func _get_available_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]

func _generate_tone_stream(type: String) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.2
	var freq = 440.0
	
	match type:
		"sword_swing":
			duration = 0.12
			freq = 320.0
		"hit":
			duration = 0.18
			freq = 180.0
		"item_pickup":
			duration = 0.25
			freq = 660.0
		"bookmark":
			duration = 0.4
			freq = 520.0
		"waypoint":
			duration = 0.5
			freq = 780.0
		"teleport":
			duration = 0.6
			freq = 400.0
		"warning_tick":
			duration = 0.08
			freq = 880.0
		"loop_expired":
			duration = 0.5
			freq = 110.0
		"shortcut":
			duration = 0.35
			freq = 490.0

	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / sample_rate
		var envelope = 1.0 - (float(i) / sample_count)
		var current_freq = freq
		if type == "sword_swing":
			current_freq = freq * (1.0 - t * 2.0)
		elif type == "item_pickup" or type == "bookmark" or type == "waypoint":
			current_freq = freq * (1.0 + t * 2.0)
		elif type == "teleport":
			current_freq = freq * (0.8 + sin(t * 30.0) * 0.4)
		
		var val = sin(2.0 * PI * current_freq * t) * envelope * 0.5
		var sample16 = int(clamp(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav
