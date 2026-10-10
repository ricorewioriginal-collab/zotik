extends Node
## Background music player. The music is baked (assets/music/<mood>.wav, seamless four-bar loops made by
## MusicSynth with tools/bake_music.gd): one looping stream per world, the title and boss fights, played
## through two players that crossfade. Nothing is calculated while playing, so it costs no frame time.
## Switch it off in the pause menu or on the title screen (setting "music_enabled"). Placeholder music.

const DIR := "res://assets/music/%s.wav"
const FADE_SECONDS := 1.0

var target_mood := "title"
var _cache := {}             # mood -> AudioStream (kept for the moods used so far)
var _players: Array[AudioStreamPlayer] = []
var _gain := [0.0, 0.0]      # per player, 0..1
var _current := -1           # index of the audible player
var _playing_mood := ""
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


func stream_for(mood: String) -> AudioStream:
	if not _cache.has(mood):
		var path := DIR % mood
		_cache[mood] = load(path) if ResourceLoader.exists(path) else null
	return _cache[mood]


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
		set_process(false)


func _apply_volume() -> void:
	for i in 2:
		_players[i].volume_db = linear_to_db(maxf(0.0001, _gain[i] * _volume()))


func _process(delta: float) -> void:
	_boss_timer -= delta
	if _boss_timer <= 0.0:
		_boss_timer = 0.5
		_boss_mood = _boss_fight()
	var want := "boss" if _boss_mood else target_mood
	if want != _playing_mood and stream_for(want) != null:
		var next := 0 if _current < 0 else 1 - _current
		_players[next].stream = _cache[want]
		_players[next].volume_db = -80.0
		_players[next].play()
		_current = next
		_playing_mood = want
	for i in 2:
		var up := i == _current
		_gain[i] = clampf(_gain[i] + (1.0 if up else -1.0) * delta / FADE_SECONDS, 0.0, 1.0)
		if not up and _gain[i] <= 0.0 and _players[i].playing:
			_players[i].stop()
	_apply_volume()


func _boss_fight() -> bool:
	for n in get_tree().get_nodes_in_group("enemy"):
		if n is Boss and n.engaged():
			return true
	return false
