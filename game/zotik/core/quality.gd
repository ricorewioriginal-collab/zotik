class_name Quality
extends RefCounted
## Graphics quality: how sharp the 3D picture is (render scale), whether the sun casts shadows and the
## frame-rate cap. Phones and browsers start on "low" (fill rate is what limits them), PCs on "high".
## The choice is stored in the setting "graphics" ("" = automatic) and cycled in the pause menu.

const LEVELS := ["low", "medium", "high"]
const NAMES := {"low": "Niedrig", "medium": "Mittel", "high": "Hoch"}
const SCALE := {"low": 0.6, "medium": 0.8, "high": 1.0}


static func level() -> String:
	var s := str(Settings.get_value("graphics"))
	if s in LEVELS:
		return s
	return "low" if Look.low_end() else "high"


static func is_auto() -> bool:
	return not (str(Settings.get_value("graphics")) in LEVELS)


static func render_scale() -> float:
	return float(SCALE[level()])


static func shadows() -> bool:
	return level() != "low"


## Physics steps per second: half the work on low (the picture is capped at 30 fps anyway).
static func physics_rate() -> int:
	return 30 if level() == "low" else 60


## A slow frame must not trigger a burst of physics steps (which makes the next frame slower still).
static func max_physics_steps() -> int:
	return 2 if level() == "low" else 8


## Frame cap: 30 on low (an even 30 feels smoother than an uneven 45), the display rate otherwise.
static func max_fps() -> int:
	return 30 if level() == "low" else 0


static func label() -> String:
	return "%s%s" % [NAMES[level()], " (automatisch)" if is_auto() else ""]


## Next level after the current one; the last step goes back to automatic.
static func cycle() -> void:
	var s := str(Settings.get_value("graphics"))
	var next := ""
	if s == "" or not (s in LEVELS):
		next = LEVELS[0]
	elif s != LEVELS[LEVELS.size() - 1]:
		next = LEVELS[LEVELS.find(s) + 1]
	Settings.set_value("graphics", next)
	Settings.save_settings()


static func apply(tree: SceneTree) -> void:
	if DisplayServer.get_name() == "headless":
		return
	tree.root.scaling_3d_scale = render_scale()
	Engine.max_fps = max_fps()
	Engine.physics_ticks_per_second = physics_rate()
	Engine.max_physics_steps_per_frame = max_physics_steps()
	for l in tree.root.find_children("*", "DirectionalLight3D", true, false):
		(l as DirectionalLight3D).shadow_enabled = shadows()
