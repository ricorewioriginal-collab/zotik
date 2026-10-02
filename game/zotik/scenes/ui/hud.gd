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
var boss_label: Label
var help_label: Label
var hurt_flash: ColorRect
var boss_bar: ProgressBar
var _notify_time := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_label = _label(Vector2(20, 14), 22)
	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(20, 50)
	hp_bar.size = Vector2(260, 22)
	hp_bar.show_percentage = false
	_style_bar(hp_bar, Color(0.3, 0.8, 0.35))
	add_child(hp_bar)
	hp_label = _label(Vector2(290, 50), 16)
	objective_label = _label(Vector2(820, 14), 18)
	objective_label.size = Vector2(440, 80)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	prompt_label = _label(Vector2(520, 600), 20)
	notify_label = _label(Vector2(420, 120), 24)
	boss_label = _label(Vector2(440, 650), 18)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(440, 676)
	boss_bar.size = Vector2(400, 18)
	boss_bar.show_percentage = false
	_style_bar(boss_bar, Color(0.75, 0.3, 0.9))
	add_child(boss_bar)
	hurt_flash = ColorRect.new()
	hurt_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	hurt_flash.color = Color(0.9, 0.1, 0.1, 0.0)
	hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hurt_flash)
	help_label = _label(Vector2(20, 520), 15)
	help_label.text = HELP_TEXT
	help_label.visible = Settings.get_value("show_controls")
	EventBus.notify.connect(show_notification)


func _process(delta: float) -> void:
	var hp := int(GameState.player.get("hp", 0))
	var mx := maxi(1, int(GameState.player.get("max_hp", 1)))
	hp_bar.max_value = mx
	hp_bar.value = hp
	(hp_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.3, 0.8, 0.35) if hp * 3 > mx else Color(0.9, 0.25, 0.2)
	hp_label.text = "%d / %d" % [hp, mx]
	area_label.text = str(Content.get_entry("areas", GameState.player.get("area", "")).get("name", ""))
	var boss: Boss = null
	for n in get_tree().get_nodes_in_group("enemy"):
		if n is Boss and n.engaged():
			boss = n
	boss_bar.visible = boss != null
	boss_label.visible = boss != null
	if boss:
		boss_label.text = "%s – %s" % [boss.data.name, boss.data.phases[boss.phase].name]
		boss_bar.max_value = boss.max_hp
		boss_bar.value = boss.hp
	hurt_flash.color.a = maxf(0.0, hurt_flash.color.a - delta * 1.2)
	if _notify_time > 0.0:
		_notify_time -= delta
		if _notify_time <= 0.0:
			notify_label.text = ""


const HELP_TEXT := "WASD bewegen · Maus/←→ Kamera · Leertaste springen\nLinksklick/J angreifen · F ausweichen · Rechtsklick blocken · Q Zielen\nE sprechen/benutzen · R Heiltrank · I Inventar · L Questlog\nT Rätsel zurücksetzen · H Hinweis · Esc Pause · F1 Hilfe ein/aus"


func toggle_help() -> void:
	help_label.visible = not help_label.visible
	Settings.set_value("show_controls", help_label.visible)
	Settings.save_settings()


func flash_hurt() -> void:
	hurt_flash.color.a = 0.35


func set_prompt(target: Interactable) -> void:
	prompt_label.text = "[E] " + target.prompt if target else ""


func set_objective(text: String) -> void:
	objective_label.text = text


func show_notification(text: String) -> void:
	notify_label.text = text
	_notify_time = 2.5 + text.length() * 0.03


func _style_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12, 0.85)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


func _label(pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	return l
