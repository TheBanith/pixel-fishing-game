extends Area2D

# A single swimming fish. Moves horizontally and bounces at its bounds.

var fish_id := ""
var data: Dictionary = {}
var speed := 40.0
var dir := 1
var bounds_left := 20.0
var bounds_right := 300.0

@onready var sprite = $Sprite2D

func setup(d: Dictionary, left: float, right: float, dmin: float, dmax: float):
    data = d
    fish_id = d["id"]
    if d.has("sprite_path") and ResourceLoader.exists(d["sprite_path"]):
        sprite.texture = load(d["sprite_path"])
    speed = float(d["speed"])
    add_to_group("fish")
    bounds_left = left
    bounds_right = right
    position.y = randf_range(dmin, dmax)
    position.x = randf_range(left, right)
    dir = -1 if randf() < 0.5 else 1
    _flip()

func get_data() -> Dictionary:
    return data

func _flip():
    sprite.flip_h = dir < 0

func _physics_process(delta):
    position.x += speed * dir * delta
    if position.x <= bounds_left:
        position.x = bounds_left
        dir = 1
        _flip()
    elif position.x >= bounds_right:
        position.x = bounds_right
        dir = -1
        _flip()
