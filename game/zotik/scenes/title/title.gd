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
	_add_button(box, "quit", "Beenden", App.quit_game)
	buttons["new_game"].grab_focus.call_deferred()


func _add_button(box: Control, id: String, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 44)
	b.pressed.connect(cb)
	box.add_child(b)
	buttons[id] = b


func _on_new_game() -> void:
	new_game_requested.emit()
	App.goto_scene(App.SCENE_GAME_ROOT)
