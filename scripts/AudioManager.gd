extends Node

# Global audio singleton: one AudioStreamPlayer per channel.
# Missing WAV files are skipped silently - the game never crashes over audio.

const CHANNELS := {
	"Splash": "res://assets/sfx_splash.wav",
	"Bite": "res://assets/sfx_bite.wav",
	"Reel": "res://assets/sfx_reel.wav",
	"Catch": "res://assets/sfx_catch.wav",
	"Coin": "res://assets/sfx_coin.wav",
	"UI_Click": "res://assets/sfx_ui_click.wav",
}

var _players := {}
var _streams := {}
var _reel_active := false

func _ready():
	# keep sounds working while the tree is paused (menus/modals)
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in CHANNELS:
		var p := AudioStreamPlayer.new()
		p.name = key
		add_child(p)
		_players[key] = p
		var path: String = CHANNELS[key]
		if FileAccess.file_exists(path):
			var s = load(path)
			if s != null:
				_streams[key] = s
	_players["Reel"].finished.connect(_on_reel_finished)

# ---- safe playback -------------------------------------------------------

func _play(key: String):
	if not _streams.has(key):
		return          # file missing or unloadable: silent pass
	var p: AudioStreamPlayer = _players[key]
	p.stream = _streams[key]
	p.play()

func play_splash():
	_play("Splash")

func play_bite():
	_play("Bite")

func play_catch():
	_play("Catch")

func play_coin():
	_play("Coin")

func play_ui_click():
	_play("UI_Click")

# Reel ratchet: loops while the player holds REEL, stops on release.
func set_reel_loop(active: bool):
	_reel_active = active
	if active:
		if not _players["Reel"].playing:
			_play("Reel")
	else:
		_players["Reel"].stop()

func _on_reel_finished():
	if _reel_active and _streams.has("Reel"):
		_players["Reel"].play()

func stop_all():
	for k in _players:
		_players[k].stop()
