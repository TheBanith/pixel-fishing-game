extends Node2D

# Main scene wiring: background, dock, water, player, spawner, line, manager, HUD,
# shop, market, world map. Owns stage loading + juice FX glue.

const STAGE_BGS := [
	"res://assets/background1.png",
	"res://assets/background2.png",
	"res://assets/background3.png",
]

@onready var player = $Player
@onready var spawner = $FishSpawner
@onready var line = $FishingLine
@onready var hud = $HUD
@onready var manager = $FishingManager
@onready var hook = $Hook
@onready var shop = $Shop
@onready var market = $Market
@onready var map = $Map
@onready var background = $Background
@onready var camera = $Camera

func _ready():
	manager.setup(player, line, hook, spawner)
	# juice: FX wiring
	manager.fx_parent = self
	manager.camera = camera
	manager.state_changed.connect(_on_state)
	manager.fish_caught.connect(_on_caught)
	manager.fish_lost.connect(_on_lost)
	hud.shop_requested.connect(_open_shop)
	hud.market_requested.connect(_open_market)
	hud.map_requested.connect(_open_map)
	shop.closed.connect(_close_modals)
	market.closed.connect(_close_modals)
	market.sold.connect(_on_sold)
	map.closed.connect(_close_modals)
	load_stage(GameData.current_stage)   # applies bg + correct fish pool at boot
	get_tree().paused = false
	hud.set_state(manager.State.IDLE)

# Switch environment: swap background texture and repopulate the fish pool.
func load_stage(stage_index: int):
	GameData.current_stage = clampi(stage_index, 1, STAGE_BGS.size())
	var idx := GameData.current_stage - 1
	if ResourceLoader.exists(STAGE_BGS[idx]):
		background.texture = load(STAGE_BGS[idx])
	# clear active fish and repopulate from GameData.get_available_fish()
	spawner.repopulate()

func _open_shop():
	if get_tree().paused:
		return
	get_tree().paused = true
	shop.open()

func _open_market():
	if get_tree().paused:
		return
	get_tree().paused = true
	market.refresh()
	market.open()

func _open_map():
	if get_tree().paused:
		return
	get_tree().paused = true
	map.open()

func _close_modals():
	get_tree().paused = false

func _input(event):
	if event.is_action("reel"):
		manager.set_reel(event.pressed)
	elif event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			if shop.visible:
				shop.close()
			elif market.visible:
				market.close()
			elif map.visible:
				map.close()

func _process(delta):
	if manager.state == manager.State.REELING:
		hud.set_tension(manager.tension, manager.safe_low, manager.safe_high)
		hud.set_progress(manager.progress)

func _spawn_text(txt: String, world_pos: Vector2, color := Color(1, 0.97, 0.6)):
	var t = preload("res://scenes/FloatingText.tscn").instantiate()
	add_child(t)
	t.global_position = world_pos + Vector2(-30, -24)
	t.set_text(txt, color)

func _on_state(s):
	hud.set_state(s)
	if s == manager.State.HOOKED:
		camera.shake(2.5, 0.2)

func _on_caught(d):
	hud._refresh_coins()
	var w: float = d.get("weight", 0.0)
	if d.get("cooler_full", false):
		_spawn_text("COOLER FULL!", player.get_rod_tip(), Color(1, 0.4, 0.3))
		print("Caught %s (%.1f kg) but the cooler is FULL - it got away! Upgrade in SHOP." % [d.get("name", "?"), w])
	else:
		var is_boss := int(d.get("rarity", 1)) >= 5
		_spawn_text("%s!  %.1f kg" % [d.get("name", "FISH").to_upper(), w],
			player.get_rod_tip(), Color(1, 0.87, 0.3) if is_boss else Color(0.6, 1, 0.6))
		if is_boss:
			camera.shake(7.0, 0.5)   # heavy shake for Stage-3 bosses
	print("Caught: %s (%.1f kg)" % [d.get("name", "?"), w])

func _on_sold(payout: int):
	_spawn_text("+%d Coins!" % payout, player.get_rod_tip(), Color(1, 0.95, 0.4))

func _on_lost():
	_spawn_text("IT GOT AWAY...", player.get_rod_tip(), Color(0.8, 0.8, 0.9))
	print("The fish got away!")
