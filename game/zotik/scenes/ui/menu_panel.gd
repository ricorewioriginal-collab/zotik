class_name MenuPanel
extends PanelContainer
## Base for modal list menus (inventory, shop). Rebuilds rows on refresh().

signal closed

var title_label: Label
var info_label: Label
var list: VBoxContainer
var close_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(820, 540)
	offset_left = -410
	offset_right = 410
	offset_top = -270
	offset_bottom = 270
	add_theme_stylebox_override("panel", UiStyle.frame(UiStyle.GOLD, Color(0.03, 0.06, 0.13, 0.94), 14, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	title_label = UiStyle.title("", 28)
	box.add_child(title_label)
	var rule := ColorRect.new()
	rule.color = UiStyle.GOLD_DARK
	rule.custom_minimum_size = Vector2(0, 2)
	box.add_child(rule)
	info_label = Label.new()
	info_label.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(info_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(780, 400)
	box.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var close := Button.new()
	close.text = "Schließen"
	style_button(close, true)
	close.pressed.connect(close_menu)
	box.add_child(close)
	close_button = close
	hide()


func open() -> void:
	show()
	refresh()


func close_menu() -> void:
	if visible:
		hide()
		closed.emit()


func refresh() -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	if Gamepad.active:
		_focus_first.call_deferred()


## Controller navigation needs a focused control: the first usable button, else "Schließen".
func _focus_first() -> void:
	if not visible or not is_inside_tree():
		return
	for b in list.find_children("*", "Button", true, false):
		if not (b as Button).disabled:
			(b as Button).grab_focus()
			return
	if close_button:
		close_button.grab_focus()


## A list row: dark rounded plate with the text on the left and gold buttons
## on the right.
func add_row(text: String, actions: Array) -> HBoxContainer:
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", _row_box(UiStyle.NAVY_LIGHT, UiStyle.GOLD_DARK))
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	plate.add_child(row)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.custom_minimum_size.x = 380
	row.add_child(l)
	for a in actions:
		var b := Button.new()
		b.text = a[0]
		b.disabled = a.size() > 2 and a[2] == false
		b.pressed.connect(a[1])
		style_button(b)
		row.add_child(b)
	list.add_child(plate)
	return row


## A heading line between groups of rows.
func add_heading(text: String) -> void:
	var l := UiStyle.title(text, 18, UiStyle.CRYSTAL)
	l.custom_minimum_size.y = 30
	list.add_child(l)


## Plain explanatory text (no buttons).
func add_note(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	l.add_theme_font_size_override("font_size", 15)
	list.add_child(l)


static func _row_box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := UiStyle.frame(border, bg, 10, 1)
	sb.content_margin_left = 14
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


## Gold-rimmed rounded button; `primary` fills it gold.
static func style_button(b: Button, primary: bool = false) -> void:
	b.custom_minimum_size = Vector2(150 if primary else 124, 44)
	b.focus_mode = Control.FOCUS_NONE
	var fill := UiStyle.GOLD_DARK if primary else Color(0.05, 0.1, 0.2, 0.95)
	b.add_theme_stylebox_override("normal", _btn_box(fill, UiStyle.GOLD))
	b.add_theme_stylebox_override("hover", _btn_box(fill.lightened(0.25), UiStyle.CRYSTAL))
	b.add_theme_stylebox_override("pressed", _btn_box(fill.lightened(0.45), UiStyle.CRYSTAL))
	b.add_theme_stylebox_override("disabled", _btn_box(Color(0.06, 0.08, 0.12, 0.7), Color(0.3, 0.3, 0.34)))
	b.add_theme_color_override("font_color", UiStyle.TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.52, 0.58))


static func _btn_box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := UiStyle.frame(border, bg, 12, 2)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		close_menu()
