extends Node
## User settings, stored separately from save slots.

const DEFAULTS := {"master_volume": 1.0, "music_volume": 0.8, "sfx_volume": 0.9, "camera_invert": false, "camera_sensitivity": 1.0, "text_speed": 1.0, "fullscreen": false}

var path := "user://settings.cfg"
var values := DEFAULTS.duplicate()


func _ready() -> void:
	load_settings()


func get_value(key: String) -> Variant:
	return values.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key) or typeof(value) != typeof(DEFAULTS[key]):
		push_warning("Settings: rejected %s" % key)
		return
	values[key] = value


func save_settings() -> Error:
	var cfg := ConfigFile.new()
	for k in values:
		cfg.set_value("settings", k, values[k])
	return cfg.save(path)


func load_settings() -> void:
	values = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for k in DEFAULTS:
		var v = cfg.get_value("settings", k, DEFAULTS[k])
		if typeof(v) == typeof(DEFAULTS[k]):
			values[k] = v
