extends Area2D
class_name SlashableGrass

signal grass_destroyed

var is_cut: bool = false

func _ready() -> void:
    name = "SlashableGrass"
    monitoring = true
    monitorable = true

    var col = CollisionShape2D.new()
    var rect = RectangleShape2D.new()
    rect.size = Vector2(16, 16)
    col.shape = rect
    add_child(col)

    var sprite = Sprite2D.new()
    sprite.name = "Sprite2D"
    var tex_gen = load("res://assets/TextureGenerator.gd")
    if is_instance_valid(tex_gen) and tex_gen.has_method("create_slashable_grass_texture"):
        sprite.texture = tex_gen.create_slashable_grass_texture()
    add_child(sprite)

    connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area: Area2D) -> void:
    if is_cut:
        return
    if area.name == "AttackHitbox":
        cut_grass()

func cut_grass() -> void:
    is_cut = true
    emit_signal("grass_destroyed")

    var juice = get_node_or_null("/root/VisualJuiceManager")
    if is_instance_valid(juice):
        juice.spawn_particles(global_position, Color(0.2, 0.9, 0.3), 10)
        juice.trigger_screen_shake(0.1, 2.0)

    queue_free()
