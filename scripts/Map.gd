extends CanvasLayer

# World Map modal: travel between stages unlocked by Rod upgrades.
# Runs while the tree is paused (process_mode = ALWAYS).

signal closed

const STAGES = [
	{"stage": 1, "name": "Oak Creek",       "bg": "res://assets/background1.png", "req": 1},
	{"stage": 2, "name": "Sunset Lake",     "bg": "res://assets/background2.png", "req": 2},
	{"stage": 3, "name": "Twilight Rapids", "bg": "res://assets/background3.png", "req": 3},
]
@onready var stage_btns = [
	$Root/Panel/VBox/Stages/StageBtn1,
	$Root/Panel/VBox/Stages/StageBtn2,
	$Root/Panel/VBox/Stages/StageBtn3,
]
@onready var close_btn = $Root/Panel/VBox/HBox/CloseBtn

func _ready():
	visible = false
	close_btn.pressed.connect(_on_close)
	for i in stage_btns.size():
		stage_btns[i].pressed.connect(_on_stage_pressed.bind(i + 1))

func _on_close():
	AudioManager.play_ui_click()
	close()

func open():
	visible = true
	refresh()

func close():
	visible = false
	closed.emit()

func _on_stage_pressed(stage: int):
	AudioManager.play_ui_click()
	if GameData.current_stage == stage:
		close()          # already here; treat as dismiss
		return
	GameData.current_stage = stage
	var main = get_parent()   # Main owns load_stage()
	if main != null and main.has_method("load_stage"):
		main.load_stage(stage)
	close()

func refresh():
	var rod_lvl := GameData.get_upgrade_level("rod")
	for i in stage_btns.size():
		var s: Dictionary = STAGES[i]
		var btn: Button = stage_btns[i]
		var unlocked: bool = rod_lvl >= int(s["req"])
		btn.disabled = not unlocked
		if unlocked:
			var here: String = "  [HERE]" if GameData.current_stage == s["stage"] else ""
			btn.text = "%s%s" % [s["name"], here]
		else:
			btn.text = "%s - Requires Lv.%d Rod" % [s["name"], int(s["req"])]
