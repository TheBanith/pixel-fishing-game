extends Camera2D

# Screen shake: random per-frame offset decaying back to rest.

var _intensity := 0.0
var _duration := 0.0

func shake(intensity: float, duration: float):
    _intensity = maxf(_intensity, intensity)
    _duration = maxf(_duration, duration)

func _process(delta):
    if _duration > 0.0:
        _duration -= delta
        offset = Vector2(
            randf_range(-_intensity, _intensity),
            randf_range(-_intensity, _intensity))
        # decay so late frames are gentler
        _intensity = maxf(_intensity - delta * 6.0, 1.0)
    else:
        offset = Vector2.ZERO
