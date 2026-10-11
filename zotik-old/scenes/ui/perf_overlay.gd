class_name PerfOverlay
extends Label
## Optional performance read-out (pause menu: "Leistungsanzeige"): frames per second, the average and
## the worst frame of the last half second, draw calls and the quality in use. For reporting
## stutter on a real device with numbers instead of impressions. Costs next to nothing while hidden.

const INTERVAL := 0.5

var _time := 0.0
var _frames := 0
var _worst := 0.0


func _ready() -> void:
	name = "PerfOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_top = 4
	offset_left = -190
	offset_right = 190
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 14)
	add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("outline_size", 5)
	visible = false


func _process(delta: float) -> void:
	var on := bool(Settings.get_value("perf_overlay"))
	if visible != on:
		visible = on
		_time = 0.0
		_frames = 0
		_worst = 0.0
	if not on:
		return
	_time += delta
	_frames += 1
	_worst = maxf(_worst, delta)
	if _time < INTERVAL:
		return
	text = report(_frames, _time, _worst, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)))
	_time = 0.0
	_frames = 0
	_worst = 0.0


## One line of text from a measuring interval.
static func report(frames: int, seconds: float, worst: float, draws: int) -> String:
	var fps := frames / maxf(seconds, 0.001)
	return "%d fps | %.0f ms (max %.0f) | %d draws | %s" % [roundi(fps), 1000.0 * seconds / maxi(frames, 1), 1000.0 * worst, draws, Quality.label()]
