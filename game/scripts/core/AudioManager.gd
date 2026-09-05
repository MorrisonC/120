extends Node

# Autoload: AudioManager

static var instance = null

var _sfx_players: Array[AudioStreamPlayer] = []
var _max_players: int = 12

var _sfx_streams: Dictionary = {}
var _ambient_player: AudioStreamPlayer = null
var _ambient_streams: Dictionary = {}
var _current_ambient_zone: String = ""

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# SFX Player pool
	for i in range(_max_players):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)
		
	# Dedicated looping ambient player
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	_ambient_player.volume_db = -12.0
	add_child(_ambient_player)
	
	_load_streams()
	
	# Connect to zone changes if GameState is present
	var gs = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("zone_changed"):
			gs.zone_changed.connect(_on_zone_changed)
		var current_zone = gs.loop_state.get("current_zone", "OverworldVillage")
		play_ambient_for_zone(current_zone)

func _load_streams() -> void:
	# Combat & Impact
	_register_stream("sword_swing", "res://assets/audio/rpg/knife_slice.ogg")
	_register_stream("hit", "res://assets/audio/impact/impact_punch_medium_000.ogg")
	_register_stream("hit_metal", "res://assets/audio/impact/impact_metal_medium_000.ogg")
	_register_stream("pot_break", "res://assets/audio/impact/impact_glass_medium_000.ogg")
	
	# UI & World Interaction
	_register_stream("item_pickup", "res://assets/audio/ui/rollover2.wav")
	_register_stream("coin_pickup", "res://assets/audio/rpg/handle_coins.ogg")
	_register_stream("chest_open", "res://assets/audio/rpg/creak_1.ogg")
	_register_stream("bookmark", "res://assets/audio/ui/switch10.wav")
	_register_stream("waypoint", "res://assets/audio/ui/switch20.wav")
	_register_stream("teleport", "res://assets/audio/ui/switch33.wav")
	_register_stream("button_click", "res://assets/audio/ui/click1.wav")
	
	# Surface Footsteps
	_register_stream("footstep_grass", "res://assets/audio/impact/footstep_grass_000.ogg")
	_register_stream("footstep_stone", "res://assets/audio/impact/footstep_concrete_000.ogg")
	_register_stream("footstep_wood", "res://assets/audio/impact/footstep_wood_000.ogg")
	_register_stream("footstep_carpet", "res://assets/audio/impact/footstep_carpet_000.ogg")
	
	# Ambient Tracks
	_register_ambient("OverworldVillage", "res://assets/audio/ambient/village_ambient.wav")
	_register_ambient("AshenRuins", "res://assets/audio/ambient/dungeon_ambient.wav")

func _register_stream(sound_name: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			_sfx_streams[sound_name] = res

func _register_ambient(zone_id: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			_ambient_streams[zone_id] = res

static func play_sfx(sound_name: String) -> void:
	if instance != null:
		instance._play_sfx_internal(sound_name)

static func play_ambient(zone_id: String) -> void:
	if instance != null:
		instance.play_ambient_for_zone(zone_id)

func play_ambient_for_zone(zone_id: String) -> void:
	if _current_ambient_zone == zone_id and _ambient_player.playing:
		return
	_current_ambient_zone = zone_id
	if _ambient_streams.has(zone_id):
		var stream = _ambient_streams[zone_id]
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_ambient_player.stream = stream
		_ambient_player.play()

func _on_zone_changed(new_zone: String) -> void:
	play_ambient_for_zone(new_zone)

func _play_sfx_internal(sound_name: String) -> void:
	var player = _get_available_player()
	if not player:
		return
	
	var stream: AudioStream = null
	if _sfx_streams.has(sound_name):
		stream = _sfx_streams[sound_name]
	else:
		stream = _generate_tone_stream(sound_name)
		
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
