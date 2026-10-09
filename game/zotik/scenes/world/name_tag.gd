class_name NameTag
extends RefCounted
## Shared look of the floating names above people and enemies: smaller, in the
## UI font, with a soft dark outline, and only visible close by.

const FRIEND := Color(1.0, 0.93, 0.7)
const ALLY := Color(0.65, 0.9, 1.0)
const FOE := Color(1.0, 0.75, 0.7)


static func style(l: Label3D, color: Color, range_m: float = 13.0) -> void:
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font = UiStyle.body_font()
	l.font_size = 30
	l.outline_size = 8
	l.outline_modulate = Color(0.02, 0.04, 0.1, 0.9)
	l.modulate = color
	l.fixed_size = true
	l.pixel_size = 0.0009
	l.no_depth_test = false
	l.visibility_range_end = range_m
	l.visibility_range_end_margin = 3.0
	l.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
