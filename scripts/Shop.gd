extends CanvasLayer

# Gear shop modal. Pauses-with-the-tree; shown/hidden by Main.

signal closed

const CATS := [
	{"id": "rod", "title": "Rod"},
	{"id": "reel", "title": "Reel"},
	{"id": "cooler", "title": "Cooler"},
]

@onready var grid = $Root/Panel/VBox/Grid
@onready var coins_label = $Root/Panel/VBox/HBox/CoinsLabel
@onready var close_btn = $Root/Panel/VBox/HBox/CloseBtn

var _ui := {}

func _ready():
	visible = false
	close_btn.pressed.connect(_on_close)
	for c in CATS:
		var t: String = c["title"]
		var id: String = c["id"]
		_ui[id] = {
			"name": grid.get_node("Info%s/NameLabel" % t),
			"info": grid.get_node("Info%s/InfoLabel" % t),
			"icon": grid.get_node("Icon%s" % t),
			"buy": grid.get_node("Buy%s" % t),
		}
		_ui[id]["buy"].pressed.connect(_on_buy.bind(id))
	refresh()

func open():
	visible = true
	refresh()

func close():
	visible = false
	closed.emit()

func _on_buy(id: String):
	if GameData.buy(id):
		AudioManager.play_coin()
		refresh()

func _on_close():
	AudioManager.play_ui_click()
	close()

func refresh():
	coins_label.text = "COINS %d" % GameData.coins
	for c in CATS:
		var id: String = c["id"]
		var title: String = c["title"]
		var ui: Dictionary = _ui[id]
		var lvl := GameData.get_upgrade_level(id)
		var cur := GameData.current_tier(id)
		var nxt := GameData.next_tier(id)
		ui["name"].text = "%s LV%d/%d" % [title.to_upper(), lvl, int(GameData.get_category(id).get("max_level", 3))]
		if cur.has("icon") and ResourceLoader.exists(cur["icon"]):
			ui["icon"].texture = load(cur["icon"])
		if nxt.is_empty():
			ui["info"].text = "%s\nMAX LEVEL" % _stat_summary(cur)
			ui["buy"].text = "MAX"
			ui["buy"].disabled = true
		else:
			ui["info"].text = "%s > %s\nCOST %d" % [_stat_summary(cur), _stat_summary(nxt), int(nxt.get("cost", 0))]
			ui["buy"].text = "BUY"
			ui["buy"].disabled = not GameData.can_buy(id)

func _stat_summary(t: Dictionary) -> String:
	if t.has("safe_zone_width"):
		return "ZONE %d" % int(t["safe_zone_width"])
	if t.has("speed_mult"):
		return "SPD x%.1f" % float(t["speed_mult"])
	if t.has("max_storage"):
		return "HOLD %d" % int(t["max_storage"])
	return "?"
