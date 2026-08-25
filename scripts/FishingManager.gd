extends Node

# Core fishing state machine + tap/hold tension minigame + juice FX.

enum State { IDLE, CASTING, HOOKED, REELING, CAUGHT }

signal state_changed(s)
signal fish_caught(data)
signal fish_lost()
signal bite()

const FloatingTextScene := preload("res://scenes/FloatingText.tscn")
const SplashScene := preload("res://scenes/SplashParticles.tscn")

var state: int = State.IDLE

# wired by Main
var player: Node2D
var line: Node2D
var hook: Area2D
var spawner: Node
var fx_parent: Node = null     # where floating text / splashes are added
var camera: Camera2D = null    # screen shake target
var _cast_splashed := false    # one splash per cast, at the water line

# geometry
var rod_tip := Vector2.ZERO
var target_y := 150.0
var cast_speed := 130.0

# captured fish
var hooked_fish: Node = null
var hooked_data: Dictionary = {}

# tension minigame
var tension := 50.0
var progress := 0.0
var safe_low := 35.0
var safe_high := 70.0
const SNAP := 100.0
var reel_held := false
var phase := 0.0
var caught_timer := 0.0
var hooked_timer := 0.0

func setup(p: Node2D, l: Node2D, h: Area2D, sp: Node):
    player = p
    line = l
    hook = h
    spawner = sp
    hook.area_entered.connect(_on_hook_area_entered)

func _unhandled_input(event):
    if event.is_action_pressed("cast"):
        if state == State.IDLE:
            cast()
        elif state == State.HOOKED:
            _start_fight()
    elif event.is_action("reel"):
        reel_held = event.pressed
        if state == State.HOOKED and event.pressed:
            _start_fight()

func set_reel(v: bool):
    reel_held = v
    # keep the ratchet in sync when the button state flips mid-fight
    AudioManager.set_reel_loop(v and state == State.REELING)

func _spawn_text(txt: String, world_pos: Vector2, color := Color(1, 0.97, 0.6)):
    if fx_parent == null:
        return
    var t = FloatingTextScene.instantiate()
    fx_parent.add_child(t)
    t.global_position = world_pos + Vector2(-30, -24)
    t.set_text(txt, color)

func _splash(world_pos: Vector2, scale_factor := 1.0, big := false):
    if fx_parent == null:
        return
    var p = SplashScene.instantiate()
    fx_parent.add_child(p)
    p.global_position = world_pos
    p.burst(scale_factor, big)

func _shake(intensity: float, duration: float):
    if camera != null:
        camera.shake(intensity, duration)

func cast():
    if state != State.IDLE:
        return
    rod_tip = player.get_rod_tip()
    cast_speed = 130.0 * GameData.reel_speed_mult()  # reel upgrades sink faster
    _cast_splashed = false
    # aim near a live fish so a bite is reachable
    var fish = spawner.get_fish()
    if fish.size() > 0:
        var f = fish[randi() % fish.size()]
        target_y = clampf(f.global_position.y, 90.0, 172.0)
    else:
        target_y = randf_range(95.0, 172.0)
    line.rod_tip = rod_tip
    line.hook_pos = rod_tip
    line.active = true
    line.show_hook = true
    line.redraw()
    hook.global_position = rod_tip
    hook.monitoring = true
    set_state(State.CASTING)

func _start_fight():
    # Rod upgrade widens the green zone; centered on the bar.
    var w := GameData.safe_zone_width()
    safe_low = clampf(50.0 - w / 2.0, 0.0, 100.0)
    safe_high = clampf(50.0 + w / 2.0, 0.0, 100.0)
    tension = 50.0
    progress = 0.0
    phase = 0.0
    set_state(State.REELING)

func _on_hook_area_entered(body):
    if state == State.CASTING and body.is_in_group("fish"):
        _bite(body)

func _bite(f: Node):
    hooked_fish = f
    if f.has_method("get_data"):
        hooked_data = f.get_data().duplicate()
    else:
        hooked_data = {"id": f.fish_id, "coin_value": 5}
    if is_instance_valid(f):
        f.queue_free()
    hook.monitoring = false
    hooked_timer = 0.0
    # juice: bite feedback - heavier for rare/boss fish
    var is_boss := int(hooked_data.get("rarity", 1)) >= 5
    _splash(hook.global_position, 1.2)
    _shake(5.0 if is_boss else 2.5, 0.45 if is_boss else 0.22)
    AudioManager.play_bite()
    set_state(State.HOOKED)
    bite.emit()

func _process(delta):
    match state:
        State.CASTING: _update_casting(delta)
        State.HOOKED: _update_hooked(delta)
        State.REELING: _update_reeling(delta)
        State.CAUGHT: _update_caught(delta)
    if line.active:
        line.hook_pos = hook.global_position
        line.rod_tip = player.get_rod_tip()
        line.redraw()

func _update_casting(delta):
    if not _missing:
        hook.global_position.y += cast_speed * delta
        # juice: splash once as the hook crosses the water line
        if not _cast_splashed and hook.global_position.y >= 64.0:
            _cast_splashed = true
            _splash(hook.global_position, 1.0)
            AudioManager.play_splash()
        _try_bite_nearby()
        if hook.global_position.y >= target_y:
            hook.global_position.y = target_y
            _missing = true
            _miss_timer = 0.0
    else:
        _miss_timer += delta
        var tip = player.get_rod_tip()
        hook.global_position.y = lerp(target_y, tip.y, clampf(_miss_timer * 3.0, 0.0, 1.0))
        if _miss_timer >= 0.4:
            _reset_line()
            set_state(State.IDLE)

# Bite the nearest fish within catch radius as the hook sinks through the water.
func _try_bite_nearby():
    if spawner == null or not spawner.has_method("get_fish"):
        return
    var best: Node = null
    var best_d := 18.0
    for f in spawner.get_fish():
        if not (f is Node2D):
            continue
        var d = hook.global_position.distance_to(f.global_position)
        if d < best_d:
            best_d = d
            best = f
    if best != null:
        _bite(best)

var _missing := false
var _miss_timer := 0.0

func _update_hooked(delta):
    hooked_timer += delta
    if hooked_timer > 1.4:
        _escape()

func _update_reeling(delta):
    phase += delta
    var gear = GameData.GEAR.get(GameData.gear_tier, GameData.GEAR[1]).reel_speed
    var rate = (55.0 * GameData.reel_speed_mult() if reel_held else -40.0)
    var struggle = sin(phase * 6.0) * 12.0
    tension += (rate + struggle) * delta
    tension = clampf(tension, 0.0, SNAP)
    var in_green = tension > safe_low and tension < safe_high
    if in_green:
        progress += 18.0 * gear * delta
    else:
        progress -= 8.0 * delta
    progress = clampf(progress, 0.0, 100.0)
    # raise hook as we win
    hook.global_position.y = lerp(target_y, rod_tip.y, progress / 100.0)
    if tension <= 0.0 or tension >= SNAP:
        _splash(hook.global_position, 0.8)
        _escape()
        return
    if progress >= 100.0:
        # juice: big pull-out splash at the surface + catch jingle
        var is_boss := int(hooked_data.get("rarity", 1)) >= 5
        _splash(Vector2(hook.global_position.x, 64.0), 2.2, is_boss)
        AudioManager.play_splash()
        AudioManager.play_catch()
        set_state(State.CAUGHT)
        caught_timer = 0.0

func _update_caught(delta):
    caught_timer += delta
    if caught_timer > 1.0:
        # Build a rich cooler entry; payout happens at the Fish Market.
        var entry := {}
        if not hooked_data.is_empty():
            var bw := float(hooked_data.get("base_weight", 1.0))
            var w := maxf(snappedf(bw * randf_range(0.6, 1.8), 0.1), 0.1)
            entry = {
                "id": hooked_data.get("id", "fish"),
                "name": hooked_data.get("name", hooked_data.get("id", "Fish")),
                "sprite_path": hooked_data.get("sprite_path", ""),
                "rarity": int(hooked_data.get("rarity", 1)),
                "base_coins": int(hooked_data.get("coin_value", 5)),
                "base_weight": bw,
                "weight": w,
            }
        var stored: bool = (not entry.is_empty()) and GameData.add_to_cooler(entry)
        hooked_data["stored"] = stored
        hooked_data["cooler_full"] = (not entry.is_empty()) and not stored
        hooked_data["weight"] = entry.get("weight", 0.0)
        fish_caught.emit(hooked_data)
        if spawner != null and spawner.has_method("spawn_one"):
            spawner.spawn_one()
        _reset_line()
        set_state(State.IDLE)

func _escape():
    fish_lost.emit()
    if is_instance_valid(hooked_fish) and hooked_fish.is_inside_tree():
        hooked_fish.queue_free()
    _reset_line()
    set_state(State.IDLE)

func _reset_line():
    line.active = false
    line.show_hook = false
    line.redraw()
    hook.monitoring = false

func set_state(s):
    state = s
    # keep the reel ratchet in sync with fight state regardless of input path
    AudioManager.set_reel_loop(s == State.REELING and reel_held)
    state_changed.emit(s)
