extends Node3D

@onready var flame_light: OmniLight3D = $FlameLight

var _base_energy: float = 2.2
var _time: float = 0.0

func _ready() -> void:
	if flame_light:
		_base_energy = flame_light.light_energy

func _process(delta: float) -> void:
	_time += delta * 12.0
	if flame_light:
		flame_light.light_energy = _base_energy + sin(_time * 1.3) * 0.3 + cos(_time * 2.7) * 0.2
