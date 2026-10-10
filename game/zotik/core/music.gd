extends Node
## Background music player. Each mood is a short seamless loop (MusicSynth, four bars) that is
## calculated in small slices spread over several frames (about 3 ms per frame) and then played as a
## normal looping stream: no real-time synthesis while playing, so it cannot stutter or steal frame
## time. Moods crossfade; the boss mood is prepared in the background so a boss fight starts at once.
## Switch it off in the pause menu or on the title screen (setting "music_enabled"); nothing is
## calculated while it is off.

const SLICE_USEC := 3000
const SLICE_SAMPLES := 512
const FADE_SECONDS := 1.0
const KEEP := 4    # moods kept in memory

var target_mood := "title"
var streams := {}            # mood -> AudioStreamWAV (finished loops)
var _order: Array = []       # finished moods, oldest first
var _players: Array[AudioStreamPlayer] = []
var _gain := [0.0, 0.0]      # per player, 0..1
var _current := -1           # index of the player carrying the audible mood
var _playing_mood := ""
var _build_mood := ""
var _synth: MusicSynth
var _bytes := PackedByteArray()
var _total := 0
var _boss_timer := 0.0
var _boss_mood := false


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	for i in 2:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	EventBus.area_entered.connect(func(a): set_mood(mood_for_area(a)))
	apply_settings()


## Mood id for an area: the music of its world.
static func mood_for_area(area_id: String) -> String:
	var world: String = Content.world_of(area_id)
	return world if MusicSynth.has_mood(world) else "title"


func set_mood(id: String) -> void:
	if MusicSynth.has_mood(id):
		target_mood = id


func enabled() -> bool:
	return bool(Settings.get_value("music_enabled"))


func _volume() -> float:
	return float(Settings.get_value("music_volume")) * float(Settings.get_value("master_volume"))


## Call after the settings changed (toggle or volume).
func apply_settings() -> void:
	if _players.is_empty():
		return
	if enabled() and _volume() > 0.0:
		set_process(true)
		_apply_volume()
	else:
		for p in _players:
			p.stop()
		_current = -1
		_playing_mood = ""
		_gain = [0.0, 0.0]
		_cancel_build()
		set_process(false)


func _apply_volume() -> void:
	for i in 2:
		_players[i].volume_db = linear_to_db(maxf(0.0001, _gain[i] * _volume()))


func _process(delta: float) -> void:
	_boss_timer -= delta
	if _boss_timer <= 0.0:
		_boss_timer = 0.5
		_boss_mood = _boss_fight()
	var want := "boss" if _boss_mood and streams.has("boss") else target_mood
	_build_step(want)
	if streams.has(want) and want != _playing_mood:
		_start(want)
	# crossfade: the audible player rises, the other falls
	for i in 2:
		var up := i == _current
		_gain[i] = clampf(_gain[i] + (1.0 if up else -1.0) * delta / FADE_SECONDS, 0.0, 1.0)
		if not up and _gain[i] <= 0.0 and _players[i].playing:
			_players[i].stop()
	_apply_volume()


func _start(mood: String) -> void:
	var next := 1 - maxi(_current, 0) if _current >= 0 else 0
	_players[next].stream = streams[mood]
	_players[next].volume_db = -80.0
	_players[next].play()
	_current = next
	_playing_mood = mood


## Advances the loop that is being calculated; picks the next one when idle: the wanted mood first,
## then the boss mood so it is ready when a fight begins.
func _build_step(want: String) -> void:
	if _build_mood == "":
		var next := ""
		if not streams.has(want):
			next = want
		elif not streams.has("boss"):
			next = "boss"
		if next == "":
			return
		_build_mood = next
		_synth = MusicSynth.new(next)
		_total = _synth.loop_samples()
		_bytes = PackedByteArray()
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < SLICE_USEC and _bytes.size() < _total * 2:
		var n := mini(SLICE_SAMPLES, _total - _bytes.size() / 2)
		_bytes.append_array(_synth.render_bytes(n, _total))
	if _bytes.size() >= _total * 2:
		_finish(_build_mood, _bytes)
		_cancel_build()


func _finish(mood: String, data: PackedByteArray) -> void:
	streams[mood] = MusicSynth.make_stream(data)
	_order.erase(mood)
	_order.append(mood)
	while _order.size() > KEEP:
		var old: String = _order.pop_front()
		if old != _playing_mood and old != target_mood and old != "boss":
			streams.erase(old)
		else:
			_order.append(old)
			break


func _cancel_build() -> void:
	_build_mood = ""
	_synth = null
	_bytes = PackedByteArray()


func _boss_fight() -> bool:
	for n in get_tree().get_nodes_in_group("enemy"):
		if n is Boss and n.engaged():
			return true
	return false
