extends Control
## Title screen. Buttons are created in code to keep the scene minimal.

signal new_game_requested

var buttons := {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.055, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var title := Label.new()
	title.text = "ZOTIK\nDie Splitter der Welten"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)
	_add_button(box, "new_game", "Neues Spiel", _on_new_game)
	for slot in range(1, SaveSystem.SLOT_COUNT + 1):
		var info := SaveSystem.slot_info(slot)
		if info.status in [SaveSystem.Status.OK, SaveSystem.Status.RECOVERED_FROM_BACKUP]:
			var text := "Laden: Slot %d – %s (%s)" % [slot, Content.get_entry("areas", info.area).get("name", info.area), _time(info.play_time)]
			if info.status == SaveSystem.Status.RECOVERED_FROM_BACKUP:
				text += " – Sicherung"
			_add_button(box, "load_%d" % slot, text, _on_load.bind(slot))
	_add_button(box, "quit", "Beenden", App.quit_game)
	buttons["new_game"].grab_focus.call_deferred()


func _add_button(box: Control, id: String, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 44)
	b.pressed.connect(cb)
	box.add_child(b)
	buttons[id] = b


func _time(t: float) -> String:
	return "%d:%02d" % [int(t) / 3600, (int(t) / 60) % 60]


func _on_load(slot: int) -> void:
	var status := App.continue_game(slot)
	if status == SaveSystem.Status.RECOVERED_FROM_BACKUP:
		EventBus.notify.emit("Spielstand beschädigt – Sicherung geladen.")


func _on_new_game() -> void:
	new_game_requested.emit()
	App.start_new_game()
