extends Node2D

# Keeps a population of fish alive; respawns when one is landed.

@export var max_fish := 6
var bounds_left := 20.0
var bounds_right := 300.0
var swim_top := 70.0
var swim_bottom := 175.0

var fish_scene: PackedScene = preload("res://scenes/Fish.tscn")

func _ready():
    for i in max_fish:
        spawn_one()

# Clear everything and refill from the current stage pool.
# remove_child first so freed nodes don't count against the cap this frame.
func repopulate():
    for f in get_children():
        remove_child(f)
        f.queue_free()
    for i in max_fish:
        spawn_one()

func spawn_one():
    if get_child_count() >= max_fish:
        return
    var data = GameData.pick_fish()
    if data.is_empty():
        return
    var dmin = clampf(float(data.get("spawn_depth_min", swim_top)), swim_top, swim_bottom)
    var dmax = clampf(float(data.get("spawn_depth_max", swim_bottom)), swim_top, swim_bottom)
    var f = fish_scene.instantiate()
    f.setup(data, bounds_left, bounds_right, dmin, dmax)
    add_child(f)

func get_fish() -> Array:
    return get_children()
