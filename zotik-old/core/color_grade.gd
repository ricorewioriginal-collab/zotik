class_name ColorGrade
extends RefCounted
## Optional colour grading (Rytelier "Color Grading", MIT, see compositor/LICENSE.txt).
## A compute-shader compositor effect: it needs the Forward+/Mobile renderer
## (RenderingDevice), so it exists on the PC build only and is off by default.


## True where the effect can run (not on web/Android, not headless/Compatibility).
static func available() -> bool:
	return not Look.low_end() and RenderingServer.get_rendering_device() != null


static func wanted() -> bool:
	return available() and bool(Settings.get_value("color_grading"))


## Gentle look: cool shadows, warm highlights, slightly richer colours.
static func build() -> Compositor:
	var fx := ColorGrading.new()
	fx.shadows = Vector4(0.62, 0.05, 1.0, 1.0)
	fx.midtones = Vector4(0.0, 0.0, 1.12, 1.0)
	fx.highlights = Vector4(0.1, 0.05, 1.08, 1.0)
	var c := Compositor.new()
	c.compositor_effects = [fx]
	return c


## Switch the effect on or off for a camera.
static func apply(camera: Camera3D) -> void:
	if camera == null:
		return
	camera.compositor = build() if wanted() else null
