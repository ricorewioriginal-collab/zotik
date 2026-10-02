extends Node

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_MASTER_VOLUME := 1.0

var master_volume := DEFAULT_MASTER_VOLUME


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		master_volume = clampf(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME), 0.0, 1.0)
	_apply_audio()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("SettingsManager: Could not save settings.")
	_apply_audio()


func _apply_audio() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_linear(bus_index, master_volume)
