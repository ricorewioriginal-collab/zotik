extends TestCase
## W10: procedural background music with an off switch.


func test_every_mood_renders_quiet_clean_audio() -> void:
	for id in MusicSynth.MOODS:
		var s := MusicSynth.new(id)
		var peak := 0.0
		var energy := 0.0
		for chunk in 6:
			for f in s.render(11025):
				peak = maxf(peak, absf(f.x))
				energy += f.x * f.x
				check(f.x == f.y and not is_nan(f.x), id + ": mono and finite")
		check(peak <= 0.95 and peak > 0.05, "%s: audible but below clipping (%f)" % [id, peak])
		check(energy > 1.0, id + ": has energy")


func test_moods_differ_and_are_deterministic() -> void:
	var a := MusicSynth.new("WORLD_LUNARIS").render(4000)
	var b := MusicSynth.new("WORLD_LUNARIS").render(4000)
	var c := MusicSynth.new("boss").render(4000)
	check(a == b, "same mood renders the same music")
	check(a != c, "boss music differs from the world music")


func test_every_world_has_music_and_unknown_falls_back() -> void:
	for w in Content.table("worlds"):
		check(MusicSynth.has_mood(w), w + " has a mood")
	eq(Music.mood_for_area("AREA_LUN_VILLAGE"), "WORLD_LUNARIS", "area maps to its world")
	eq(Music.mood_for_area("AREA_NOPE"), "title", "unknown area falls back")


func test_music_can_be_muted_and_the_choice_is_stored() -> void:
	check(Settings.DEFAULTS.has("music_enabled") and Settings.DEFAULTS.music_enabled, "on by default")
	Settings.set_value("music_enabled", false)
	check(not Music.enabled(), "muted")
	Settings.set_value("music_enabled", true)
	check(Music.enabled(), "on again")


func test_sound_effects_cover_the_game_and_can_be_muted() -> void:
	for n in ["step", "jump", "land", "dodge", "block", "swing_strong", "windup", "break", "click", "ui_open", "ui_close", "door", "equip", "chest", "quest", "quest_start", "coin", "heal"]:
		check(Sfx.streams.has(n) and Sfx.streams[n] is AudioStreamWAV and Sfx.streams[n].data.size() > 100, "effect exists: " + n)
	check(Sfx.enabled(), "effects on by default")
	Sfx._last.clear()
	Sfx.play("click")
	var t1: float = Sfx._last.get("click", -1.0)
	check(t1 > 0.0, "a play is recorded")
	Settings.set_value("sfx_enabled", false)
	Sfx._last.clear()
	Sfx.play("click")
	check(not Sfx._last.has("click"), "muted effects do not play")
	Settings.set_value("sfx_enabled", true)


func test_buttons_click_and_rapid_repeats_are_throttled() -> void:
	var b := Button.new()
	tree.root.add_child(b)
	Sfx._last.clear()
	b.pressed.emit()
	check(Sfx._last.has("click"), "button press clicks")
	var first: float = Sfx._last.click
	Sfx.play("click")
	eq(Sfx._last.click, first, "second click inside the gap is dropped")
	b.queue_free()


func test_loops_are_seamless_and_the_right_length() -> void:
	for id in ["title", "WORLD_LUNARIS", "boss"]:
		var syn := MusicSynth.new(id)
		var total := syn.loop_samples()
		var bytes := syn.render_bytes(total, total)
		eq(bytes.size(), total * 2, id + ": exactly four bars of mono 16-bit")
		check(absi(bytes.decode_s16(bytes.size() - 2)) < 400, id + ": loop ends near silence")
		var stream := MusicSynth.make_stream(bytes)
		eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, id + ": loops")
		eq(stream.loop_end, total, id + ": loop covers the whole stream")


func test_build_in_slices_equals_one_go() -> void:
	var a := MusicSynth.new("WORLD_ELARIS")
	var total := a.loop_samples()
	var whole := a.render_bytes(total, total)
	var b := MusicSynth.new("WORLD_ELARIS")
	var sliced := PackedByteArray()
	while sliced.size() < total * 2:
		sliced.append_array(b.render_bytes(mini(512, total - sliced.size() / 2), total))
	check(sliced == whole, "slicing the work changes nothing")


func test_every_mood_has_a_baked_looping_file() -> void:
	for id in MusicSynth.MOODS:
		var path := "res://assets/music/%s.wav" % id
		check(ResourceLoader.exists(path), id + ": baked file exists")
		var st := load(path) as AudioStreamWAV
		check(st != null and st.loop_mode == AudioStreamWAV.LOOP_FORWARD, id + ": loops")
		var syn := MusicSynth.new(id)
		check(absi(st.get_length() * st.mix_rate - syn.loop_samples()) < 8, id + ": the baked loop has the loop length of the synth")
