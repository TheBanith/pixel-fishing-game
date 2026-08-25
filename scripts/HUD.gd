extends CanvasLayer

# Retro pixel-bordered HUD: COINS, CAST/REEL/SHOP buttons, tension bar + status.

signal shop_requested
signal market_requested
signal map_requested

@onready var coin_label = $Control/CoinsLabel
@onready var state_label = $Control/StateLabel
@onready var cast_btn = $Control/ButtonBar/CastBtn
@onready var reel_btn = $Control/ButtonBar/ReelBtn
@onready var shop_btn = $Control/ButtonBar/ShopBtn
@onready var market_btn = $Control/ButtonBar/MarketBtn
@onready var map_btn = $Control/ButtonBar/MapBtn
@onready var tension_bar = $Control/TensionBar
@onready var progress_bar = $Control/ProgressBar

func _ready():
    cast_btn.pressed.connect(func(): _act("cast"))
    reel_btn.pressed.connect(func(): _act("reel"))
    # touch/mouse: hold reel to keep tension up
    reel_btn.button_down.connect(func(): _hold_reel(true))
    reel_btn.button_up.connect(func(): _hold_reel(false))
    shop_btn.pressed.connect(_on_shop_pressed)
    market_btn.pressed.connect(_on_market_pressed)
    map_btn.pressed.connect(_on_map_pressed)
    # real-time counter updates from anywhere (incl. inside modals)
    GameData.coins_changed.connect(func(_v): _refresh_coins())
    GameData.cooler_changed.connect(_refresh_coins)
    _refresh_coins()

func _act(action: String):
    AudioManager.play_ui_click()
    var ev = InputEventAction.new()
    ev.action = action
    ev.pressed = true
    Input.parse_input_event(ev)

func _on_shop_pressed():
    AudioManager.play_ui_click()
    shop_requested.emit()

func _on_market_pressed():
    AudioManager.play_ui_click()
    market_requested.emit()

func _on_map_pressed():
    AudioManager.play_ui_click()
    map_requested.emit()

func _hold_reel(v: bool):
    var ev = InputEventAction.new()
    ev.action = "reel"
    ev.pressed = v
    Input.parse_input_event(ev)

func _refresh_coins():
    coin_label.text = "COINS %d  BOX %d/%d" % [GameData.coins, GameData.cooler.size(), GameData.max_storage()]

func set_state(s: int):
    var names = {0:"IDLE",1:"CASTING",2:"HOOKED!",3:"REELING",4:"CAUGHT!"}
    state_label.text = names.get(s, str(s))
    tension_bar.visible = (s == 3)
    progress_bar.visible = (s == 3)

func set_tension(t: float, lo: float, hi: float):
    # x position of marker on the bar, plus green safe zone highlight
    var frac = clampf(t / 100.0, 0.0, 1.0)
    tension_bar.position.x = 88.0 + 60.0 * frac
    var gfrac = (hi - lo) / 100.0
    # draw green zone via a child ColorRect size
    var gz = tension_bar.get_parent().get_node_or_null("GreenZone")
    if gz:
        gz.size.x = 60.0 * gfrac
        gz.position.x = 88.0 + 60.0 * (lo / 100.0)

func set_progress(p: float):
    progress_bar.size.x = 60.0 * clampf(p / 100.0, 0.0, 1.0)
