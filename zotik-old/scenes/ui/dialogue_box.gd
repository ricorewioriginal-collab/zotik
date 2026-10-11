class_name DialogueBox
extends Control
## Bottom dialogue panel. Advances with interact/attack/ui_accept or click.

var speaker_label: Label
var text_label: Label
var panel: PanelContainer
var _arrow: Control
var plate: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 120
	panel.offset_right = -120
	panel.offset_top = -200
	panel.offset_bottom = -24
	panel.add_theme_stylebox_override("panel", UiStyle.frame(UiStyle.GOLD, Color(0.03, 0.06, 0.13, 0.92), 14, 2))
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	plate = PanelContainer.new()
	plate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var plate_sb := UiStyle.frame(UiStyle.CRYSTAL, Color(0.08, 0.16, 0.32, 0.95), 8, 1)
	plate_sb.set_content_margin_all(4)
	plate_sb.content_margin_left = 14
	plate_sb.content_margin_right = 14
	plate.add_theme_stylebox_override("panel", plate_sb)
	box.add_child(plate)
	speaker_label = UiStyle.title("", 20)
	plate.add_child(speaker_label)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.custom_minimum_size = Vector2(0, 90)
	text_label.add_theme_font_size_override("font_size", 21)
	box.add_child(text_label)
	var arrow := Control.new()
	arrow.custom_minimum_size = Vector2(0, 14)
	arrow.draw.connect(func():
		var x := arrow.size.x - 20.0
		var bob := sin(Time.get_ticks_msec() / 200.0) * 2.0
		arrow.draw_colored_polygon(PackedVector2Array([Vector2(x - 8, bob), Vector2(x + 8, bob), Vector2(x, 10 + bob)]), UiStyle.GOLD))
	arrow.set_process(true)
	box.add_child(arrow)
	_arrow = arrow
	panel.hide()
	Dialogue.line_shown.connect(_on_line)
	Dialogue.finished.connect(func(_id): panel.visible = Dialogue.is_active())


func _process(_delta: float) -> void:
	if panel.visible and _arrow:
		_arrow.queue_redraw()


func _on_line(speaker: String, text: String) -> void:
	panel.show()
	plate.visible = speaker != ""  # the narrator has no name plate
	speaker_label.text = speaker
	text_label.text = text


func _unhandled_input(event: InputEvent) -> void:
	if not Dialogue.is_active():
		return
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		Dialogue.advance()
