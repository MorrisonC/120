extends CanvasLayer

var shake_strength: float = 0.0
var shake_decay: float = 5.0
var rng = RandomNumberGenerator.new()

var color_rect: ColorRect
var vignette: ColorRect

# Particle pool
var particle_pool = []
const POOL_SIZE = 20

func _ready():
    rng.randomize()

    # Transition fade overlay
    color_rect = ColorRect.new()
    color_rect.color = Color(0, 0, 0, 0) # Transparent initially
    color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(color_rect)

    # Vignette for timer pressure (reddish tint on edges)
    vignette = ColorRect.new()
    vignette.color = Color(1, 0, 0, 0)
    vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(vignette)

    # Setup particle pool
    for i in range(POOL_SIZE):
        var p = CPUParticles2D.new()
        p.emitting = false
        p.one_shot = true
        p.amount = 10
        p.lifetime = 0.5
        p.explosiveness = 1.0
        p.spread = 180.0
        p.gravity = Vector2(0, 0)
        p.initial_velocity_min = 20.0
        p.initial_velocity_max = 50.0
        p.color = Color(1, 1, 1, 1)
        add_child(p)
        particle_pool.append(p)

    var time_mgr = get_node_or_null("/root/TimeManager")
    if is_instance_valid(time_mgr):
        time_mgr.connect("second_ticked", Callable(self, "_on_time_ticked"))

func apply_shake(strength: float = 10.0):
    shake_strength = strength

func trigger_screen_shake(duration: float = 0.2, strength: float = 5.0):
    shake_strength = strength

func play_transition(duration: float = 0.3):
    var tween = create_tween()
    tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), duration / 2.0).set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), duration / 2.0).set_trans(Tween.TRANS_CUBIC)

func spawn_particles(pos: Vector2, color: Color = Color.WHITE, _count: int = 10):
    for p in particle_pool:
        if not p.emitting:
            p.global_position = pos
            p.color = color
            p.emitting = true
            return

func _process(delta):
    if shake_strength > 0:
        shake_strength = lerpf(shake_strength, 0.0, shake_decay * delta)
        var offset = Vector2(
            rng.randf_range(-shake_strength, shake_strength),
            rng.randf_range(-shake_strength, shake_strength)
        )

        # Apply offset to camera if it exists
        var camera = get_viewport().get_camera_2d()
        if is_instance_valid(camera):
            camera.offset = offset

func _on_time_ticked(remaining_time: float):
    # Show vignette when time is low (e.g. last 15 seconds)
    if remaining_time <= 15.0 and remaining_time > 0.0:
        var intensity = 1.0 - (remaining_time / 15.0) # 0.0 to 1.0
        vignette.color = Color(1, 0, 0, intensity * 0.5) # Max 50% opacity red tint
    else:
        vignette.color = Color(1, 0, 0, 0)
