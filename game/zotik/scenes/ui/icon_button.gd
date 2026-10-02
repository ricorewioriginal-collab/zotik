class_name IconButton
extends Button
## Menu button with a drawn icon (no special glyphs needed), a caption and a
## key hint. Pressing it sends the same input action as the keyboard.

var action := ""
var icon_kind := ""
var key_hint := ""


static func create(act: String, caption: String, kind: String, key: String) -> IconButton:
	var b := IconButton.new()
	b.action = act
	b.icon_kind = kind
	b.key_hint = key
	b.text = caption
	b.name = "Icon_" + act
	b.custom_minimum_size = Vector2(92, 86)
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_font_size_override("font_size", 14)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(b._fire)
	return b


func _fire() -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)


func _draw() -> void:
	var c := Vector2(size.x / 2.0, 32)
	var g := UiStyle.GOLD
	match icon_kind:
		"bag":
			draw_rect(Rect2(c + Vector2(-13, -8), Vector2(26, 22)), g, false, 2.5)
			draw_arc(c + Vector2(0, -8), 8, PI, TAU, 16, g, 2.5)
			draw_line(c + Vector2(-13, 0), c + Vector2(13, 0), g, 2.0)
		"scroll":
			draw_rect(Rect2(c + Vector2(-11, -14), Vector2(22, 28)), g, false, 2.5)
			for i in 3:
				draw_line(c + Vector2(-6, -6 + i * 7), c + Vector2(6, -6 + i * 7), g, 2.0)
			draw_circle(c + Vector2(0, -20), 3.0, UiStyle.CRYSTAL)
		"book":
			draw_rect(Rect2(c + Vector2(-15, -12), Vector2(14, 24)), g, false, 2.5)
			draw_rect(Rect2(c + Vector2(1, -12), Vector2(14, 24)), g, false, 2.5)
			draw_circle(c + Vector2(8, 0), 3.5, UiStyle.CRYSTAL)
		"gear":
			draw_arc(c, 11, 0, TAU, 24, g, 3.0)
			draw_circle(c, 4.0, UiStyle.CRYSTAL)
			for i in 8:
				var d := Vector2.RIGHT.rotated(i * TAU / 8.0)
				draw_line(c + d * 11.0, c + d * 16.0, g, 3.0)
	if key_hint != "":
		draw_string(UiStyle.body_font(), Vector2(6, 16), key_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.TEXT_DIM)


func _ready() -> void:
	# caption below the drawn icon
	add_theme_constant_override("h_separation", 0)
	add_theme_stylebox_override("normal", _pad(get_theme_stylebox("normal")))
	add_theme_stylebox_override("hover", _pad(get_theme_stylebox("hover")))
	add_theme_stylebox_override("pressed", _pad(get_theme_stylebox("pressed")))


func _pad(sb: StyleBox) -> StyleBox:
	var s := sb.duplicate() as StyleBox
	s.content_margin_top = 52
	return s
