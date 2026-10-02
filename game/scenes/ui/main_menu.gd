extends Control

const BACKGROUND := Color("#182936")
const PANEL := Color("#274653")
const ACCENT := Color("#ed8742")

var _menu_buttons: VBoxContainer
var _settings_panel: PanelContainer


func _ready() -> void:
	GameManager.set_state(GameManager.State.MAIN_MENU)
	_build_menu()


func _build_menu() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(410, 0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	_menu_buttons = VBoxContainer.new()
	_menu_buttons.add_theme_constant_override("separation", 12)
	_menu_buttons.add_theme_constant_override("margin_left", 28)
	_menu_buttons.add_theme_constant_override("margin_right", 28)
	_menu_buttons.add_theme_constant_override("margin_top", 28)
	_menu_buttons.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(_menu_buttons)

	var title := Label.new()
	title.text = "ZOTIK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", ACCENT)
	_menu_buttons.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Die Splitter der Welten"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	_menu_buttons.add_child(subtitle)
	var status := Label.new()
	status.text = "EARLY DEVELOPMENT  ·  VERTICAL SLICE"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 11)
	status.add_theme_color_override("font_color", Color("#b9c8c7"))
	_menu_buttons.add_child(status)
	_add_button(_menu_buttons, "Neues Spiel", GameManager.start_new_game)
	var continue_button := _add_button(_menu_buttons, "Spiel fortsetzen", GameManager.continue_game)
	continue_button.disabled = not SaveManager.has_save(1)
	_add_button(_menu_buttons, "Einstellungen", _show_settings)
	_add_button(_menu_buttons, "Beenden", _quit_game)

	_settings_panel = PanelContainer.new()
	_settings_panel.visible = false
	_settings_panel.custom_minimum_size = Vector2(410, 0)
	_settings_panel.add_theme_stylebox_override("panel", _panel_style())
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_settings_panel.position = Vector2(-205, -120)
	add_child(_settings_panel)
	_build_settings()


func _build_settings() -> void:
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 14)
	contents.add_theme_constant_override("margin_left", 24)
	contents.add_theme_constant_override("margin_right", 24)
	contents.add_theme_constant_override("margin_top", 24)
	contents.add_theme_constant_override("margin_bottom", 24)
	_settings_panel.add_child(contents)
	var heading := Label.new()
	heading.text = "Einstellungen"
	heading.add_theme_font_size_override("font_size", 24)
	contents.add_child(heading)
	var volume_label := Label.new()
	volume_label.text = "Master-Lautstärke"
	contents.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = SettingsManager.master_volume
	volume.value_changed.connect(SettingsManager.set_master_volume)
	contents.add_child(volume)
	_add_button(contents, "Zurück", _hide_settings)


func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 46
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _show_settings() -> void:
	_menu_buttons.visible = false
	_settings_panel.visible = true


func _hide_settings() -> void:
	_settings_panel.visible = false
	_menu_buttons.visible = true


func _quit_game() -> void:
	get_tree().quit()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(18)
	style.set_content_margin_all(4)
	return style
