extends CanvasLayer

# Fish Market modal: inspect + sell cooler contents. Runs while tree is paused.

signal closed
signal sold(payout)   # emitted for each sale; Main pops "+N Coins!" text

const RARITY_COLORS = {
	1: Color(0.75, 0.78, 0.75),
	2: Color(0.45, 0.85, 0.45),
	3: Color(0.4, 0.8, 1.0),
	4: Color(1.0, 0.65, 0.25),
	5: Color(1.0, 0.87, 0.3),
}

@onready var header_info = $Root/Panel/VBox/HeaderInfo
@onready var scroll = $Root/Panel/VBox/Scroll
@onready var list = $Root/Panel/VBox/Scroll/List
@onready var sell_all_btn = $Root/Panel/VBox/HBox/SellAllBtn
@onready var close_btn = $Root/Panel/VBox/HBox/CloseBtn

func _ready():
	visible = false
	close_btn.pressed.connect(_on_close)
	sell_all_btn.pressed.connect(_on_sell_all)

func _on_close():
	AudioManager.play_ui_click()
	close()

func open():
	visible = true
	_refresh()

func close():
	visible = false
	closed.emit()

func _on_sell_all():
	AudioManager.play_ui_click()
	var total := GameData.sell_all_fish()  # emits cooler_changed + coins_changed
	if total > 0:
		AudioManager.play_coin()
		sold.emit(total)
	_refresh()

func _on_sell_one(index: int):
	var payout := GameData.sell_fish(index)  # emits cooler_changed + coins_changed
	if payout > 0:
		AudioManager.play_coin()
		sold.emit(payout)
	_refresh()

func _refresh():
	header_info.text = "COOLER: %d/%d    EST. VALUE: %d G" % [
		GameData.cooler.size(), GameData.max_storage(), GameData.cooler_total_value()]
	sell_all_btn.disabled = GameData.cooler.is_empty()
	for c in list.get_children():
		c.queue_free()
	var i := 0
	for e in GameData.cooler:
		list.add_child(_make_row(e, i))
		i += 1

func _make_row(entry: Dictionary, index: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	# species thumbnail
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(18, 18)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var sp: String = entry.get("sprite_path", "")
	if sp != "" and ResourceLoader.exists(sp):
		thumb.texture = load(sp)
	row.add_child(thumb)

	# name (rarity-colored tag) + weight/value line
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rar := int(entry.get("rarity", 1))
	var name_l := Label.new()
	name_l.text = "%s [R%d]" % [str(entry.get("name", "?")), rar]
	name_l.add_theme_font_size_override("font_size", 9)
	name_l.add_theme_color_override("font_color", RARITY_COLORS.get(rar, Color.WHITE))
	col.add_child(name_l)
	var info := Label.new()
	info.text = "%.1f kg  |  %d G" % [float(entry.get("weight", 0.0)), GameData.calculate_fish_value(entry)]
	info.add_theme_font_size_override("font_size", 8)
	info.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	col.add_child(info)
	row.add_child(col)

	# individual sell button
	var b := Button.new()
	b.text = "SELL"
	b.custom_minimum_size = Vector2(40, 16)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 8)
	b.pressed.connect(_on_sell_one.bind(index))
	row.add_child(b)
	return row
