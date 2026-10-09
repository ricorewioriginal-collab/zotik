class_name PauseMenu
extends MenuPanel
## Pause menu: resume, settings shortcut values, back to title, quit.


func refresh() -> void:
	super()
	title_label.text = "Pause"
	info_label.text = "Spielzeit %d:%02d · Speichern ist am Weltenanker möglich." % [int(GameState.play_time) / 3600, (int(GameState.play_time) / 60) % 60]
	add_row("Weiterspielen", [["OK", close_menu]])
	add_row("Kamera invertieren: %s" % ("an" if Settings.get_value("camera_invert") else "aus"), [["Umschalten", _toggle_invert]])
	add_row("Casino (Familienoption): %s" % ("erlaubt" if Settings.get_value("casino_enabled") else "deaktiviert"), [["Umschalten", _toggle_casino]])
	add_row("Touch-Steuerung: %s" % ("an" if TouchControls.wanted() else "aus"), [["Umschalten", _toggle_touch]])
	if TouchControls.wanted():
		add_row("Touch-Größe: %d %%" % roundi(float(Settings.get_value("touch_scale")) * 100.0), [["Ändern", _cycle_touch_scale]])
		add_row("Touch-Deckkraft: %d %%" % roundi(float(Settings.get_value("touch_opacity")) * 100.0), [["Ändern", _cycle_touch_opacity]])
		add_row("Aktionstasten: %s (Tippen und Doppeltippen steuern auch ohne)" % ("an" if Settings.get_value("touch_buttons") else "aus"), [["Umschalten", _toggle_touch_buttons]])
	add_row("Zum Titelbildschirm (ungespeicherter Fortschritt geht verloren)", [["Titel", _to_title]])
	add_row("Spiel beenden", [["Beenden", App.quit_game]])


func _toggle_invert() -> void:
	Settings.set_value("camera_invert", not Settings.get_value("camera_invert"))
	Settings.save_settings()
	refresh()


func _toggle_touch() -> void:
	Settings.set_value("touch_controls", not Settings.get_value("touch_controls"))
	Settings.save_settings()
	refresh()


const TOUCH_SCALES := [0.8, 1.0, 1.2, 1.4]
const TOUCH_OPACITIES := [0.35, 0.6, 0.85]


func _cycle_touch_scale() -> void:
	Settings.set_value("touch_scale", _next_of(TOUCH_SCALES, float(Settings.get_value("touch_scale"))))
	Settings.save_settings()
	refresh()


func _cycle_touch_opacity() -> void:
	Settings.set_value("touch_opacity", _next_of(TOUCH_OPACITIES, float(Settings.get_value("touch_opacity"))))
	Settings.save_settings()
	refresh()


## The entry after the one closest to `current` (wraps around).
static func _next_of(options: Array, current: float) -> float:
	var best := 0
	for i in options.size():
		if absf(options[i] - current) < absf(options[best] - current):
			best = i
	return options[(best + 1) % options.size()]


func _toggle_touch_buttons() -> void:
	Settings.set_value("touch_buttons", not Settings.get_value("touch_buttons"))
	Settings.save_settings()
	refresh()


func _toggle_casino() -> void:
	Settings.set_value("casino_enabled", not Settings.get_value("casino_enabled"))
	Settings.save_settings()
	refresh()


func _to_title() -> void:
	hide()
	App.goto_scene(App.SCENE_TITLE)
