extends Node

# Autoload singleton: global player state, fish catalog, shop upgrades, stages.

signal coins_changed(v)
signal cooler_changed

var coins := 25                  # starter coins so the shop is usable early
var cooler: Array = []           # caught fish entries, in order
var fish_db: Array = []          # loaded from data/fish_data.json
var shop_db: Dictionary = {}     # id -> category dict from shop_data.json
var upgrade_levels := {"rod": 1, "reel": 1, "cooler": 1}
var current_stage := 1           # switched via the World Map; gated by Rod level

func _ready():
	_load_fish()
	_load_shop()

# ---------------- catalog ----------------

func _load_fish():
	var path = "res://data/fish_data.json"
	if not FileAccess.file_exists(path):
		push_warning("fish_data.json not found at " + path)
		return
	var f = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and parsed.has("fish") and parsed["fish"] is Array:
		fish_db = parsed["fish"]

func _load_shop():
	var path = "res://data/shop_data.json"
	if not FileAccess.file_exists(path):
		push_warning("shop_data.json not found at " + path)
		return
	var parsed = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	if parsed is Dictionary and parsed.has("categories"):
		for c in parsed["categories"]:
			shop_db[c["id"]] = c

# Fish available for spawning in the current stage.
func get_available_fish() -> Array:
	var out: Array = []
	for d in fish_db:
		if int(d.get("stage", 1)) == current_stage:
			out.append(d)
	return out

# Weighted random pick from the CURRENT STAGE pool; rarer fish appear less often.
func pick_fish() -> Dictionary:
	var pool := get_available_fish()
	if pool.is_empty():
		pool = fish_db
	if pool.is_empty():
		return {}
	var weights: Array = []
	var total := 0.0
	for d in pool:
		var w = 1.0 / max(float(d.get("rarity", 1)), 0.001)
		weights.append(w)
		total += w
	var roll := randf() * total
	var acc := 0.0
	for i in pool.size():
		acc += weights[i]
		if roll <= acc:
			return pool[i]
	return pool[pool.size() - 1]

func fish_by_id(id: String) -> Dictionary:
	for d in fish_db:
		if d.get("id") == id:
			return d
	return {}

# ---------------- economy ----------------

func add_coins(n: int):
	coins += n
	coins_changed.emit(coins)

func spend_coins(n: int) -> bool:
	if coins >= n:
		coins -= n
		coins_changed.emit(coins)
		return true
	return false

# ---------------- cooler ----------------

# Cooler entries are Dictionaries:
# {id, name, sprite_path, rarity, base_coins, base_weight, weight}

func max_storage() -> int:
	return int(_stat("cooler", "max_storage", 5))

func is_cooler_full() -> bool:
	return cooler.size() >= max_storage()

func add_to_cooler(entry: Dictionary) -> bool:
	if is_cooler_full():
		return false
	cooler.append(entry)
	return true

# ---------------- fish market ----------------

# round(base_coins * (weight / base_weight))
func calculate_fish_value(fish_entry: Dictionary) -> int:
	var bc := float(fish_entry.get("base_coins", 0))
	var w := float(fish_entry.get("weight", 0.0))
	var bw := float(fish_entry.get("base_weight", 1.0))
	if bw <= 0.0:
		bw = 1.0
	return int(round(bc * (w / bw)))

func sell_fish(index: int) -> int:
	if index < 0 or index >= cooler.size():
		return 0
	var payout := calculate_fish_value(cooler[index])
	cooler.remove_at(index)
	add_coins(payout)   # emits coins_changed
	cooler_changed.emit()
	return payout

func sell_all_fish() -> int:
	if cooler.is_empty():
		return 0
	var total := 0
	for e in cooler:
		total += calculate_fish_value(e)
	cooler.clear()
	add_coins(total)    # emits coins_changed once
	cooler_changed.emit()
	return total

func cooler_total_value() -> int:
	var total := 0
	for e in cooler:
		total += calculate_fish_value(e)
	return total

# ---------------- upgrades ----------------

func get_upgrade_level(id: String) -> int:
	return int(upgrade_levels.get(id, 1))

func get_category(id: String) -> Dictionary:
	return shop_db.get(id, {})

func is_max_level(id: String) -> bool:
	var c = get_category(id)
	return get_upgrade_level(id) >= int(c.get("max_level", 1))

func current_tier(id: String) -> Dictionary:
	var lvls = get_category(id).get("levels", [])
	if lvls.is_empty():
		return {}
	return lvls[clampi(get_upgrade_level(id) - 1, 0, lvls.size() - 1)]

func next_tier(id: String) -> Dictionary:
	var lvls = get_category(id).get("levels", [])
	var i = get_upgrade_level(id)
	if i < lvls.size():
		return lvls[i]
	return {}

func next_cost(id: String) -> int:
	return int(next_tier(id).get("cost", -1))

func can_buy(id: String) -> bool:
	return not is_max_level(id) and coins >= next_cost(id)

func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	if not spend_coins(next_cost(id)):
		return false
	upgrade_levels[id] = get_upgrade_level(id) + 1
	return true

# ---------------- stat lookups ----------------

# tier stat with fallback default
func _stat(id: String, key: String, def):
	var t = current_tier(id)
	if t is Dictionary and t.has(key):
		return t[key]
	return def

# Rod: width of the green safe zone in the tension minigame.
func safe_zone_width() -> float:
	return float(_stat("rod", "safe_zone_width", 35.0))

# Reel: multiplier on sink + retrieve speeds.
func reel_speed_mult() -> float:
	return float(_stat("reel", "speed_mult", 1.0))
