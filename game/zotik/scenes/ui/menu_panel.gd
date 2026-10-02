class_name MenuPanel
extends PanelContainer
## Base for modal list menus (inventory, shop). Rebuilds rows on refresh().

signal closed

var title_label: Label
var info_label: Label
var list: VBoxContainer


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
	close.pressed.connect(close_menu)
	box.add_child(close)
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


func add_row(text: String, actions: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = 460
	row.add_child(l)
	for a in actions:
		var b := Button.new()
		b.text = a[0]
		b.disabled = a.size() > 2 and a[2] == false
		b.pressed.connect(a[1])
		row.add_child(b)
	list.add_child(row)
	return row


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		close_menu()
