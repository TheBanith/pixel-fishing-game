extends Label

# Floating feedback text: drifts upward, fades out over ~1.5 s, then frees itself.

var _lifetime := 1.5
const DURATION := 1.5
var _velocity := Vector2(0, -22)

func _process(delta):
    _lifetime -= delta
    position += _velocity * delta
    modulate.a = clampf(_lifetime / DURATION, 0.0, 1.0)
    if _lifetime <= 0.0:
        queue_free()

func set_text(value: String, color: Color = Color.WHITE):
    text = value
    modulate = Color(color.r, color.g, color.b, 1.0)
