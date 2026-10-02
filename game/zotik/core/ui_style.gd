class_name UiStyle
extends RefCounted
## Shared UI look (U01): dark navy glass panels with gold trim and crystal-blue
## highlights, Cinzel for titles and Exo 2 for text (both SIL OFL,
## assets/fonts). Applied once to the root window as its theme; widgets use
## the helpers below for frames, bars and titles. The theme is saved as
## assets/ui/zotik_theme.tres (project setting gui/theme/custom) because a
## theme on the root window does not reach controls under a CanvasLayer;
## test_u01_ui keeps the file in sync with build_theme().

const NAVY := Color(0.04, 0.07, 0.15, 0.9)
const NAVY_LIGHT := Color(0.09, 0.14, 0.27, 0.95)
const GOLD := Color(0.86, 0.71, 0.38)
const GOLD_DARK := Color(0.55, 0.42, 0.2)
const CRYSTAL := Color(0.45, 0.82, 1.0)
const TEXT := Color(0.94, 0.95, 1.0)
const TEXT_DIM := Color(0.72, 0.78, 0.9)

static var _theme: Theme
static var _title_font: Font
static var _body_font: Font


static func body_font() -> Font:
	if _body_font == null:
		var f := FontVariation.new()
		f.base_font = load("res://assets/fonts/Exo2.ttf")
		f.variation_opentype = {"wght": 520}
		_body_font = f
	return _body_font


static func title_font() -> Font:
	if _title_font == null:
		var f := FontVariation.new()
		f.base_font = load("res://assets/fonts/Cinzel.ttf")
		f.variation_opentype = {"wght": 700}
		_title_font = f
	return _title_font


## Rounded navy panel with a gold (or crystal) border and soft shadow.
static func frame(border: Color = GOLD, bg: Color = NAVY, radius: int = 10, width: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	sb.set_content_margin_all(12)
	sb.anti_aliasing = true
	return sb


static func bar_styles(fill_top: Color) -> Array:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.03, 0.07, 0.9)
	bg.border_color = GOLD_DARK
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_top
	fill.set_corner_radius_all(6)
	fill.border_color = fill_top.lightened(0.35)
	fill.border_width_top = 2
	return [bg, fill]


static func style_bar(bar: ProgressBar, fill: Color) -> void:
	var s := bar_styles(fill)
	bar.add_theme_stylebox_override("background", s[0])
	bar.add_theme_stylebox_override("fill", s[1])
	bar.show_percentage = false
	bar.add_theme_font_size_override("font_size", 1)  # no text: allow thin bars


static func title(text: String, size: int = 26, color: Color = GOLD) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", title_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	return l


const THEME_PATH := "res://assets/ui/zotik_theme.tres"


static func theme() -> Theme:
	if _theme == null:
		_theme = load(THEME_PATH) if ResourceLoader.exists(THEME_PATH) else build_theme()
	return _theme


static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 18
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.8))
	t.set_constant("outline_size", "Label", 4)
	t.set_stylebox("panel", "PanelContainer", frame())
	t.set_stylebox("panel", "Panel", frame())
	var normal := frame(GOLD_DARK, NAVY_LIGHT, 8, 1)
	normal.set_content_margin_all(8)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.shadow_size = 0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = CRYSTAL
	hover.bg_color = Color(0.12, 0.22, 0.4, 0.95)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.2, 0.32, 0.55, 0.95)
	var focus := hover.duplicate() as StyleBoxFlat
	focus.bg_color = Color(0, 0, 0, 0)
	focus.set_border_width_all(2)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.08, 0.09, 0.13, 0.8)
	disabled.border_color = Color(0.3, 0.3, 0.35)
	for pair in [["normal", normal], ["hover", hover], ["pressed", pressed], ["focus", focus], ["disabled", disabled]]:
		t.set_stylebox(pair[0], "Button", pair[1])
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", CRYSTAL)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.55))
	var s := bar_styles(Color(0.3, 0.85, 0.45))
	t.set_stylebox("background", "ProgressBar", s[0])
	t.set_stylebox("fill", "ProgressBar", s[1])
	var grab := StyleBoxFlat.new()
	grab.bg_color = GOLD_DARK
	grab.set_corner_radius_all(4)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.3)
	track.set_corner_radius_all(4)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("scroll", "VScrollBar", track)
	return t
