extends Node
## Background music player: streams MusicSynth into an AudioStreamGenerator, picks the mood from the
## world (or the title / a boss fight) and fades between moods. Switch it off in the pause menu or on
## the title screen (setting "music_enabled"); nothing is synthesised while it is off.

const MAX_FRAMES_PER_TICK := 900
const FADE_SECONDS := 0.9

var synth: MusicSynth
var target_mood := "title"
var gain := 0.0
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _boss_timer := 0.0
var _boss_mood := false


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MusicSynth.RATE
	gen.buffer_length = 0.4
	_player.stream = gen
	add_child(_player)
	synth = MusicSynth.new(target_mood)
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


## Call after the settings changed (toggle or volume).
func apply_settings() -> void:
	if _player == null:
		return
	var vol := float(Settings.get_value("music_volume")) * float(Settings.get_value("master_volume"))
	_player.volume_db = linear_to_db(maxf(0.001, vol))
	if enabled() and vol > 0.0:
		if not _player.playing:
			_player.play()
			_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
		set_process(true)
	else:
		_player.stop()
		_playback = null
		set_process(false)


func _process(delta: float) -> void:
	if _playback == null:
		return
	_boss_timer -= delta
	if _boss_timer <= 0.0:
		_boss_timer = 0.5
		_boss_mood = _boss_fight()
	var want := "boss" if _boss_mood else target_mood
	if want != synth.mood:
		gain = maxf(0.0, gain - delta / FADE_SECONDS)
		if gain <= 0.01:
			synth.set_mood(want)
	else:
		gain = minf(1.0, gain + delta / FADE_SECONDS)
	var frames := mini(_playback.get_frames_available(), MAX_FRAMES_PER_TICK)
	if frames <= 0:
		return
	var buf := synth.render(frames)
	if gain < 0.999:
		for i in frames:
			buf[i] *= gain
	_playback.push_buffer(buf)


func _boss_fight() -> bool:
	for n in get_tree().get_nodes_in_group("enemy"):
		if n is Boss and n.engaged():
			return true
	return false
