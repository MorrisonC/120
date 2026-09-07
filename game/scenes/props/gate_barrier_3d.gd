extends StaticBody3D
class_name GateBarrier3D

@export var required_flag: String = "has_machete"
@export var unlock_flag: String = "brambles_cleared"
@export var prompt_message: String = "Thick brambles block the way. Needs Machete."

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var prompt_label_3d: Label3D = $Label3D

func _ready() -> void:
	if QuestManager.has_signal("world_state_changed"):
		QuestManager.world_state_changed.connect(_on_world_state_changed)
	_update_barrier_state()

func _update_barrier_state() -> void:
	if QuestManager.is_flag_set(unlock_flag):
		# Barrier permanently open
		if collision_shape:
			collision_shape.disabled = true
		visible = false
	else:
		if collision_shape:
			collision_shape.disabled = false
		visible = true
		if prompt_label_3d:
			prompt_label_3d.text = prompt_message

func interact() -> void:
	if QuestManager.is_flag_set(required_flag):
		QuestManager.set_flag(unlock_flag, true)
	else:
		# Shake feedback indicating locked state
		var tween = create_tween()
		tween.tween_property(self, "position:x", position.x + 0.2, 0.05)
		tween.tween_property(self, "position:x", position.x - 0.2, 0.05)
		tween.tween_property(self, "position:x", position.x, 0.05)

func _on_world_state_changed(flag: String, _value: bool) -> void:
	if flag == unlock_flag or flag == required_flag:
		_update_barrier_state()
