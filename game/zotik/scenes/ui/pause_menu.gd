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


func _toggle_casino() -> void:
	Settings.set_value("casino_enabled", not Settings.get_value("casino_enabled"))
	Settings.save_settings()
	refresh()


func _to_title() -> void:
	hide()
	App.goto_scene(App.SCENE_TITLE)
