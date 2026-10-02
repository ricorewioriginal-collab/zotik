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
}

var streams := {}
var players: Array[AudioStreamPlayer] = []
var _next := 0


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


func play(name: String) -> void:
	if not streams.has(name):
		return
	var p := players[_next]
	_next = (_next + 1) % players.size()
	p.stream = streams[name]
	p.volume_db = linear_to_db(maxf(0.001, float(Settings.get_value("sfx_volume")) * float(Settings.get_value("master_volume"))))
	p.play()


static func _synth(d: Dictionary) -> AudioStreamWAV:
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
