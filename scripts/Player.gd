extends Node2D

# The angler. Tracks the rod-tip world position the line casts from.

@export var rod_tip_offset := Vector2(44, -56)

func get_rod_tip() -> Vector2:
    return global_position + rod_tip_offset
