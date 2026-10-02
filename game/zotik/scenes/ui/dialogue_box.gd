class_name DialogueBox
extends Control
## Bottom dialogue panel. Advances with interact/attack/ui_accept or click.

var speaker_label: Label
var text_label: Label
var panel: PanelContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	panel.position = Vector2(140, 520)
	panel.size = Vector2(1000, 170)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 22)
	speaker_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	box.add_child(speaker_label)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.custom_minimum_size = Vector2(980, 100)
	text_label.add_theme_font_size_override("font_size", 20)
	box.add_child(text_label)
	panel.hide()
	Dialogue.line_shown.connect(_on_line)
	Dialogue.finished.connect(func(_id): panel.visible = Dialogue.is_active())


func _on_line(speaker: String, text: String) -> void:
	panel.show()
	speaker_label.text = speaker
	text_label.text = text


func _unhandled_input(event: InputEvent) -> void:
	if not Dialogue.is_active():
		return
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		Dialogue.advance()
