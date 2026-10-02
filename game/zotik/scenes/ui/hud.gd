class_name Hud
extends Control
## In-game HUD: health, area name, current objective, interaction prompt and
## short notifications.

var hp_bar: ProgressBar
var hp_label: Label
var area_label: Label
var objective_label: Label
var prompt_label: Label
var notify_label: Label
var _notify_time := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_label = _label(Vector2(20, 14), 22)
	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(20, 50)
	hp_bar.size = Vector2(260, 22)
	hp_bar.show_percentage = false
	add_child(hp_bar)
	hp_label = _label(Vector2(290, 50), 16)
	objective_label = _label(Vector2(820, 14), 18)
	objective_label.size = Vector2(440, 80)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	prompt_label = _label(Vector2(520, 600), 20)
	notify_label = _label(Vector2(420, 120), 24)
	EventBus.notify.connect(show_notification)


func _process(delta: float) -> void:
	var hp := int(GameState.player.get("hp", 0))
	var mx := maxi(1, int(GameState.player.get("max_hp", 1)))
	hp_bar.max_value = mx
	hp_bar.value = hp
	hp_label.text = "%d / %d" % [hp, mx]
	area_label.text = str(Content.get_entry("areas", GameState.player.get("area", "")).get("name", ""))
	if _notify_time > 0.0:
		_notify_time -= delta
		if _notify_time <= 0.0:
			notify_label.text = ""


func set_prompt(target: Interactable) -> void:
	prompt_label.text = "[E] " + target.prompt if target else ""


func set_objective(text: String) -> void:
	objective_label.text = text


func show_notification(text: String) -> void:
	notify_label.text = text
	_notify_time = 2.5


func _label(pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	return l
