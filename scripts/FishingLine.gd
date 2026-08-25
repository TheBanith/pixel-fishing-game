extends Node2D

# Draws the fishing line from the rod tip to the descending hook.

var rod_tip := Vector2.ZERO
var hook_pos := Vector2.ZERO
var active := false
var show_hook := false

func _draw():
    if not active:
        return
    var lp = rod_tip - global_position
    var hp = hook_pos - global_position
    draw_line(lp, hp, Color(0.95, 0.95, 0.95, 0.85), 1.0)
    if show_hook:
        draw_circle(hp, 3.0, Color(0.95, 0.85, 0.2, 1.0))
        draw_circle(hp, 1.0, Color(0.25, 0.12, 0.0, 1.0))

func redraw():
    queue_redraw()
