class_name MusicSynth
extends RefCounted
## Procedural background music (no audio assets): a slow pad, a plucked bass, a seeded arpeggio and,
## for tense moods, a kick and hi-hat. Rendered sample by sample at a low rate so it costs next to
## nothing and never hitches on load; `Music` streams it into an AudioStreamGenerator.
## Placeholder music, not a final score.

const RATE := 11025
const TABLE := 2048
const MINOR := [0, 2, 3, 5, 7, 8, 10]
const MAJOR := [0, 2, 4, 5, 7, 9, 11]
const DORIAN := [0, 2, 3, 5, 7, 9, 10]
const LYDIAN := [0, 2, 4, 6, 7, 9, 11]
const PHRYGIAN := [0, 1, 3, 5, 7, 8, 10]

## root: MIDI note; prog: chord roots as scale degrees (one chord per bar); arp: share of arpeggio
## steps that sound (0..1); drive: kick + hi-hat; pad: pad loudness
const MOODS := {
	"title": {"root": 57, "scale": DORIAN, "bpm": 76, "prog": [0, 5, 3, 4], "arp": 0.6, "drive": false, "pad": 1.0, "seed": 1},
	"WORLD_LUNARIS": {"root": 57, "scale": LYDIAN, "bpm": 72, "prog": [0, 5, 3, 4], "arp": 0.55, "drive": false, "pad": 1.0, "seed": 2},
	"WORLD_ELARIS": {"root": 55, "scale": MAJOR, "bpm": 84, "prog": [0, 3, 4, 3], "arp": 0.7, "drive": false, "pad": 0.9, "seed": 3},
	"WORLD_VALDORIA": {"root": 52, "scale": DORIAN, "bpm": 96, "prog": [0, 3, 6, 4], "arp": 0.75, "drive": false, "pad": 0.9, "seed": 4},
	"WORLD_SOLMERA": {"root": 50, "scale": PHRYGIAN, "bpm": 88, "prog": [0, 1, 0, 6], "arp": 0.7, "drive": false, "pad": 0.9, "seed": 5},
	"WORLD_AQUALIS": {"root": 53, "scale": LYDIAN, "bpm": 70, "prog": [0, 4, 5, 3], "arp": 0.5, "drive": false, "pad": 1.1, "seed": 6},
	"WORLD_FROSTHAIN": {"root": 48, "scale": MINOR, "bpm": 64, "prog": [0, 5, 2, 6], "arp": 0.4, "drive": false, "pad": 1.2, "seed": 7},
	"WORLD_IGNARA": {"root": 45, "scale": PHRYGIAN, "bpm": 104, "prog": [0, 1, 5, 4], "arp": 0.8, "drive": true, "pad": 0.8, "seed": 8},
	"WORLD_NOCTARIS": {"root": 47, "scale": MINOR, "bpm": 60, "prog": [0, 3, 5, 4], "arp": 0.35, "drive": false, "pad": 1.2, "seed": 9},
	"WORLD_ASTRALIS": {"root": 52, "scale": LYDIAN, "bpm": 76, "prog": [0, 2, 4, 5], "arp": 0.6, "drive": false, "pad": 1.0, "seed": 10},
	"WORLD_ELYNDRA": {"root": 55, "scale": MAJOR, "bpm": 68, "prog": [0, 4, 5, 3], "arp": 0.55, "drive": false, "pad": 1.1, "seed": 11},
	"WORLD_WELTENRISS": {"root": 43, "scale": MINOR, "bpm": 92, "prog": [0, 5, 6, 4], "arp": 0.65, "drive": true, "pad": 0.9, "seed": 12},
	"boss": {"root": 45, "scale": MINOR, "bpm": 132, "prog": [0, 0, 5, 4], "arp": 0.9, "drive": true, "pad": 0.7, "seed": 13},
}

static var _sine: PackedFloat32Array

var mood := "title"
var _m: Dictionary
var _n := 0                  # samples rendered since the mood started
var _pattern: Array = []     # per bar: eight arpeggio steps (chord tone index, or -1 = rest)
var _noise := 12345
var _bar := -1
var _step := -1
var _chord: Array = []
var _pad_f: Array = []
var _bass_f := 0.0
var _arp_f := 0.0


func _init(mood_id: String = "title") -> void:
	if _sine.is_empty():
		_sine.resize(TABLE)
		for i in TABLE:
			_sine[i] = sin(TAU * i / TABLE)
	set_mood(mood_id)


static func has_mood(id: String) -> bool:
	return MOODS.has(id)


func set_mood(id: String) -> void:
	mood = id if MOODS.has(id) else "title"
	_m = MOODS[mood]
	_n = 0
	_bar = -1
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_m.seed) * 7919
	_pattern.clear()
	for bar in 4:
		var steps := []
		for s in 8:
			steps.append(rng.randi_range(0, 5) if rng.randf() < float(_m.arp) else -1)
		_pattern.append(steps)


## The next `count` stereo frames (mono signal in both channels), peak below 1.0.
## Chord and note frequencies are worked out once per bar / step, not per sample.
func render(count: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(count)
	var scale: Array = _m.scale
	var prog: Array = _m.prog
	var bpm := float(_m.bpm)
	var beats_per_sample := bpm / 60.0 / RATE
	var sec_per_beat := 60.0 / bpm
	var drive: bool = _m.drive
	var pad_gain := 0.1 * float(_m.pad)
	var sine := _sine
	for i in count:
		var beat := _n * beats_per_sample
		var bar := int(beat / 4.0)
		var in_bar := beat - bar * 4.0
		if bar != _bar:
			_bar = bar
			var deg: int = prog[bar % prog.size()]
			_chord = [_note(scale, deg), _note(scale, deg + 2), _note(scale, deg + 4)]
			_pad_f = [_freq(_chord[0] + 12), _freq(_chord[1] + 12), _freq(_chord[2] + 12)]
			_bass_f = _freq(_chord[0] - 12)
			_step = -1
		var t := float(_n) / RATE
		var v := 0.0
		# pad: three soft tones swelling over the bar
		var swell := minf(1.0, minf(in_bar / 0.8, (4.0 - in_bar) / 0.8)) * pad_gain
		for pf in _pad_f:
			var ph: float = pf * t
			v += sine[int((ph - floorf(ph)) * TABLE) & (TABLE - 1)] * swell
		# bass: one pluck per beat
		var in_beat := in_bar - floorf(in_bar)
		var bp: float = _bass_f * t
		v += sine[int((bp - floorf(bp)) * TABLE) & (TABLE - 1)] * 0.2 * exp(-3.0 * in_beat) * minf(1.0, in_beat * 80.0)
		# arpeggio: eighth notes
		var step := int(in_bar * 2.0)
		if step != _step:
			_step = step
			var idx: int = _pattern[bar % 4][step]
			_arp_f = 0.0 if idx < 0 else _freq(_chord[idx % 3] + 12 * (1 + idx / 3))
		if _arp_f > 0.0:
			var since := (in_bar * 2.0 - step) * 0.5 * sec_per_beat
			var ap: float = _arp_f * t
			var a1 := sine[int((ap - floorf(ap)) * TABLE) & (TABLE - 1)]
			var ap2 := 2.0 * ap
			var a2 := sine[int((ap2 - floorf(ap2)) * TABLE) & (TABLE - 1)]
			v += (a1 + 0.3 * a2) * 0.07 * exp(-9.0 * since) * minf(1.0, since * 300.0)
		if drive:
			var kick_t := in_beat * sec_per_beat
			if kick_t < 0.35:
				v += _osc(45.0 * kick_t + 6.0 * (1.0 - exp(-20.0 * kick_t))) * 0.3 * exp(-9.0 * kick_t)
			if in_beat >= 0.5:
				var hat_t := (in_beat - 0.5) * sec_per_beat
				if hat_t < 0.1:
					_noise = (_noise * 1103515245 + 12345) & 0x7fffffff
					v += (float(_noise) / 1073741823.5 - 1.0) * 0.05 * exp(-40.0 * hat_t)
		v = clampf(v, -0.95, 0.95)
		out[i] = Vector2(v, v)
		_n += 1
	return out


func _osc(phase: float) -> float:
	return _sine[int((phase - floorf(phase)) * TABLE) & (TABLE - 1)]


static func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## MIDI note of a scale degree (degrees beyond the scale continue in the next octave).
func _note(scale: Array, degree: int) -> int:
	return int(_m.root) + int(scale[degree % scale.size()]) + 12 * (degree / scale.size())


## Length of one loop of a mood in samples: four bars of four beats.
func loop_samples() -> int:
	return int(round(16.0 * 60.0 / float(_m.bpm) * RATE))


## Mono 16-bit bytes for `count` samples of the mood from the current position (for looped streams);
## the last 30 ms of a loop are faded so the wrap-around does not click.
func render_bytes(count: int, loop_total: int) -> PackedByteArray:
	var frames := render(count)
	var out := PackedByteArray()
	out.resize(count * 2)
	var fade := int(0.03 * RATE)
	var first := _n - count
	for i in count:
		var v := frames[i].x
		var left := loop_total - (first + i)
		if left < fade:
			v *= maxf(0.0, float(left) / fade)
		out.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return out


static func make_stream(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = data.size() / 2
	return w


## The whole loop at once (tests, tools); the game builds it in small steps instead.
static func build_loop(id: String) -> AudioStreamWAV:
	var s := MusicSynth.new(id)
	return make_stream(s.render_bytes(s.loop_samples(), s.loop_samples()))
