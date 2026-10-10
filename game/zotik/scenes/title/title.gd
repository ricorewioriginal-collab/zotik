extends Control
## Title screen. Buttons are created in code to keep the scene minimal.

signal new_game_requested

var buttons := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Warmup.run.call_deferred(self)
	Music.set_mood("title")
	var bg_color := ColorRect.new()
	bg_color.color = Color(0.02, 0.03, 0.07)
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	# owner's party poster (concept art, interim key art) with a dark fade
	var art := TextureRect.new()
	art.texture = load("res://assets/ui/title_bg.jpg")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(art)
	var fade := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.02, 0.03, 0.07, 0.0))
	grad.set_color(1, Color(0.02, 0.03, 0.07, 0.92))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0.35)
	gt.fill_to = Vector2(0, 1)
	fade.texture = gt
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(fade)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	box.offset_left = -200
	box.offset_right = 200
	box.offset_top = -250
	box.offset_bottom = -40
	box.alignment = BoxContainer.ALIGNMENT_END
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(box)
	var version := Label.new()
	version.text = "v" + App.VERSION
	version.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	version.add_theme_font_size_override("font_size", 14)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -90
	version.offset_top = -34
	add_child(version)
	_add_button(box, "new_game", "Neues Spiel", _on_new_game)
	for slot in [SaveSystem.AUTO_SLOT, 1, 2, 3]:
		var info := SaveSystem.slot_info(slot)
		if info.status in [SaveSystem.Status.OK, SaveSystem.Status.RECOVERED_FROM_BACKUP]:
			var slot_name := "Autospeicherung" if slot == SaveSystem.AUTO_SLOT else "Slot %d" % slot
			var text := "Laden: %s – %s (%s)" % [slot_name, Content.get_entry("areas", info.area).get("name", info.area), _time(info.play_time)]
			if info.status == SaveSystem.Status.RECOVERED_FROM_BACKUP:
				text += " – Sicherung"
			_add_button(box, "load_%d" % slot, text, _on_load.bind(slot))
	_add_button(box, "transfer", "Spielstand übertragen (Export / Import)", _open_transfer)
	_add_button(box, "music", _music_text(), _toggle_music)
	_add_button(box, "quit", "Beenden", App.quit_game)
	buttons["new_game"].grab_focus.call_deferred()


func _open_transfer() -> void:
	var tm := TransferMenu.new()
	add_child(tm)
	# a new save appears in the load list: rebuild the title
	tm.imported.connect(func(): App.goto_scene.call_deferred(App.SCENE_TITLE))
	tm.closed.connect(tm.queue_free)
	tm.open()


func _add_button(box: Control, id: String, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(400, 48)
	b.add_theme_font_override("font", UiStyle.title_font())
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	box.add_child(b)
	buttons[id] = b


func _music_text() -> String:
	return "Musik: %s" % ("an" if Settings.get_value("music_enabled") else "aus")


func _toggle_music() -> void:
	Settings.set_value("music_enabled", not Settings.get_value("music_enabled"))
	Settings.save_settings()
	Music.apply_settings()
	buttons["music"].text = _music_text()


func _time(t: float) -> String:
	return "%d:%02d" % [int(t) / 3600, (int(t) / 60) % 60]


func _on_load(slot: int) -> void:
	var status := App.continue_game(slot)
	if status == SaveSystem.Status.RECOVERED_FROM_BACKUP:
		EventBus.notify.emit("Spielstand beschädigt – Sicherung geladen.")


func _on_new_game() -> void:
	new_game_requested.emit()
	App.start_new_game()
