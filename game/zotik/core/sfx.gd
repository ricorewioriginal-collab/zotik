extends Node
## Procedurally generated placeholder sound effects (no audio assets yet).
## Each sound is synthesised once into an AudioStreamWAV and played from a
## small player pool.

const RATE := 22050
const SOUNDS := {
	"swing": {"f0": 520.0, "f1": 180.0, "dur": 0.12, "noise": 0.6, "vol": 0.35},
	"hit": {"f0": 180.0, "f1": 70.0, "dur": 0.14, "noise": 0.5, "vol": 0.6},
	"hurt": {"f0": 260.0, "f1": 120.0, "dur": 0.22, "noise": 0.3, "vol": 0.6},
	"pickup": {"f0": 660.0, "f1": 1320.0, "dur": 0.18, "noise": 0.0, "vol": 0.4},
	"solve": {"f0": 440.0, "f1": 880.0, "dur": 0.5, "noise": 0.0, "vol": 0.45},
	"wrong": {"f0": 200.0, "f1": 150.0, "dur": 0.3, "noise": 0.1, "vol": 0.45},
	"blip": {"f0": 900.0, "f1": 900.0, "dur": 0.04, "noise": 0.0, "vol": 0.2},
	"defeat": {"f0": 300.0, "f1": 60.0, "dur": 0.4, "noise": 0.7, "vol": 0.5},
	"save": {"f0": 520.0, "f1": 780.0, "dur": 0.4, "noise": 0.0, "vol": 0.4},
	"step": {"f0": 120.0, "f1": 70.0, "dur": 0.07, "noise": 0.8, "vol": 0.18},
	"jump": {"f0": 260.0, "f1": 520.0, "dur": 0.14, "noise": 0.1, "vol": 0.3},
	"land": {"f0": 110.0, "f1": 60.0, "dur": 0.1, "noise": 0.6, "vol": 0.3},
	"dodge": {"f0": 900.0, "f1": 250.0, "dur": 0.18, "noise": 0.8, "vol": 0.3},
	"block": {"f0": 1400.0, "f1": 900.0, "dur": 0.1, "noise": 0.35, "vol": 0.45},
	"swing_strong": {"f0": 380.0, "f1": 90.0, "dur": 0.2, "noise": 0.7, "vol": 0.45},
	"windup": {"f0": 200.0, "f1": 420.0, "dur": 0.35, "noise": 0.1, "vol": 0.3},
	"break": {"f0": 700.0, "f1": 200.0, "dur": 0.35, "noise": 0.5, "vol": 0.55},
	"click": {"f0": 1100.0, "f1": 900.0, "dur": 0.04, "noise": 0.0, "vol": 0.22},
	"ui_open": {"f0": 500.0, "f1": 760.0, "dur": 0.08, "noise": 0.0, "vol": 0.25},
	"ui_close": {"f0": 760.0, "f1": 480.0, "dur": 0.08, "noise": 0.0, "vol": 0.25},
	"door": {"f0": 300.0, "f1": 150.0, "dur": 0.3, "noise": 0.5, "vol": 0.35},
	"equip": {"f0": 420.0, "f1": 640.0, "dur": 0.1, "noise": 0.15, "vol": 0.3},
	"lock": {"f0": 800.0, "f1": 1000.0, "dur": 0.05, "noise": 0.0, "vol": 0.2},
	"chest": {"seq": [[330.0, 0.08], [440.0, 0.08], [660.0, 0.18]], "vol": 0.4},
	"quest": {"seq": [[392.0, 0.12], [494.0, 0.12], [587.0, 0.12], [784.0, 0.35]], "vol": 0.4},
	"quest_start": {"seq": [[440.0, 0.1], [587.0, 0.2]], "vol": 0.35},
	"coin": {"seq": [[988.0, 0.05], [1319.0, 0.14]], "vol": 0.3},
	"heal": {"seq": [[523.0, 0.08], [659.0, 0.08], [784.0, 0.2]], "vol": 0.35},
}

## Minimum seconds between two plays of the same sound (many enemies or fast taps must not pile up).
const MIN_GAP := {"step": 0.2, "windup": 0.25, "click": 0.05, "hit": 0.05, "swing": 0.05, "coin": 0.1, "pickup": 0.05}
const DEFAULT_GAP := 0.03

var streams := {}
var players: Array[AudioStreamPlayer] = []
var _next := 0
var _last := {}   # sound -> last play time (seconds)
var _coins := -1


func _ready() -> void:
	for name in SOUNDS:
		streams[name] = _synth(SOUNDS[name])
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	EventBus.item_added.connect(func(_i, _n): play("pickup"))
	EventBus.puzzle_solved.connect(func(_p): play("solve"))
	EventBus.enemy_defeated.connect(func(_e): play("defeat"))
	EventBus.savepoint_used.connect(func(_s): play("save"))
	EventBus.chest_opened.connect(func(_c): play("chest"))
	EventBus.quest_completed.connect(func(_q): play("quest"))
	EventBus.quest_started.connect(func(_q): play("quest_start"))
	EventBus.area_entered.connect(func(_a): play("door"))
	EventBus.equipment_changed.connect(func(): play("equip"))
	EventBus.currency_changed.connect(_on_currency)
	get_tree().node_added.connect(_on_node_added)


## Every button in the game clicks (also dynamically built menus).
func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		(n as BaseButton).pressed.connect(func(): play("click"))


func _on_currency(amount: int) -> void:
	if _coins >= 0 and amount > _coins:
		play("coin")
	_coins = amount


func enabled() -> bool:
	return bool(Settings.get_value("sfx_enabled"))


func play(name: String) -> void:
	if not streams.has(name) or not enabled():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(name, -10.0)) < float(MIN_GAP.get(name, DEFAULT_GAP)):
		return
	_last[name] = now
	var p := players[_next]
	_next = (_next + 1) % players.size()
	p.stream = streams[name]
	p.volume_db = linear_to_db(maxf(0.001, float(Settings.get_value("sfx_volume")) * float(Settings.get_value("master_volume"))))
	p.play()


static func _synth(d: Dictionary) -> AudioStreamWAV:
	if d.has("seq"):
		return _synth_sequence(d)
	var n := int(RATE * float(d.dur))
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d)
	for i in n:
		var t := float(i) / n
		var noise: float = d.noise
		var f: float = lerpf(d.f0, d.f1, t)
		phase += TAU * f / RATE
		var env: float = minf(1.0, t * 40.0) * pow(1.0 - t, 2.0)
		var v: float = (sin(phase) * (1.0 - noise) + rng.randf_range(-1, 1) * noise) * env * float(d.vol)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w


## A short jingle: notes one after another, each plucked.
static func _synth_sequence(d: Dictionary) -> AudioStreamWAV:
	var total := 0
	for note in d.seq:
		total += int(RATE * float(note[1]))
	var data := PackedByteArray()
	data.resize(total * 2)
	var i := 0
	for note in d.seq:
		var count := int(RATE * float(note[1]))
		var phase := 0.0
		for k in count:
			var t := float(k) / count
			phase += TAU * float(note[0]) / RATE
			var env := minf(1.0, t * 30.0) * exp(-3.0 * t)
			var v := (sin(phase) + 0.25 * sin(2.0 * phase)) * env * float(d.vol)
			data.encode_s16((i + k) * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
		i += count
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w
