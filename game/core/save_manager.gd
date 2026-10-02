extends Node

signal save_completed(slot: int)
signal save_failed(slot: int, reason: String)

const SAVE_VERSION := 1
const SLOT_COUNT := 3
const SAVE_DIRECTORY := "user://saves"


func save_slot(slot: int, payload: Dictionary) -> bool:
	if not _is_valid_slot(slot):
		save_failed.emit(slot, "Invalid save slot.")
		return false
	var directory_path := ProjectSettings.globalize_path(SAVE_DIRECTORY)
	var directory_error := DirAccess.make_dir_recursive_absolute(directory_path)
	if directory_error != OK:
		save_failed.emit(slot, "Could not create save directory.")
		return false

	var data := {
		"version": SAVE_VERSION,
		"payload": payload.duplicate(true),
	}
	data["checksum"] = _checksum(data["payload"])
	var path := _slot_path(slot)
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		save_failed.emit(slot, "Could not open temporary save file.")
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()

	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		var backup_error := DirAccess.copy_absolute(path, path + ".bak")
		if backup_error != OK:
			DirAccess.remove_absolute(temporary_path)
			save_failed.emit(slot, "Could not create save backup.")
			return false
		DirAccess.remove_absolute(path)
	var rename_error := DirAccess.rename_absolute(temporary_path, path)
	if rename_error != OK:
		DirAccess.remove_absolute(temporary_path)
		if not FileAccess.file_exists(path) and FileAccess.file_exists(path + ".bak"):
			DirAccess.copy_absolute(path + ".bak", path)
		save_failed.emit(slot, "Could not replace save file.")
		return false
	save_completed.emit(slot)
	return true


func load_slot(slot: int) -> Dictionary:
	if not _is_valid_slot(slot):
		return {}
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: Could not read slot %d." % slot)
		return {}
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		push_warning("SaveManager: Slot %d contains invalid JSON." % slot)
		return {}
	var parsed: Variant = json.data
	if not parsed is Dictionary or not parsed.get("payload") is Dictionary:
		push_warning("SaveManager: Slot %d is malformed." % slot)
		return {}
	var version: int = parsed.get("version", -1)
	if version != SAVE_VERSION:
		push_warning("SaveManager: Slot %d uses unsupported version %d." % [slot, version])
		return {}
	var payload: Dictionary = parsed["payload"]
	if parsed.get("checksum", -1) != _checksum(payload):
		push_warning("SaveManager: Slot %d failed checksum validation." % slot)
		return {}
	return payload.duplicate(true)


func has_save(slot: int) -> bool:
	return _is_valid_slot(slot) and FileAccess.file_exists(_slot_path(slot))


func _is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT


func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIRECTORY, slot]


func _checksum(payload: Dictionary) -> int:
	return hash(JSON.stringify(_normalize_for_checksum(payload)))


func _normalize_for_checksum(value: Variant) -> Variant:
	if value is Dictionary:
		var normalized: Dictionary = {}
		for key in value:
			normalized[key] = _normalize_for_checksum(value[key])
		return normalized
	if value is Array:
		var normalized: Array = []
		for entry in value:
			normalized.append(_normalize_for_checksum(entry))
		return normalized
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return float(value)
	return value
