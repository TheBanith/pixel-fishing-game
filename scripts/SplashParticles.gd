extends CPUParticles2D

# One-shot splash: frees itself after finishing.

func _ready():
    finished.connect(queue_free)

func burst(scale_factor := 1.0, big := false):
    amount = int(24 * scale_factor) if not big else int(40 * scale_factor)
    initial_velocity_max *= scale_factor
    initial_velocity_min *= scale_factor
    scale_amount_max *= scale_factor
    emitting = true
