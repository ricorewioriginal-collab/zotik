extends Node
## Local-first slot saves.
## - Envelope with schema_version, game_version, timestamp and SHA-256 checksum.
## - Atomic write: write .tmp, keep previous valid save as .bak, rename.
## - Corrupt or tampered slot: the file is kept as .corrupt and the .bak is loaded.
## - Newer schema versions are rejected (no unsafe downgrade).

const SCHEMA_VERSION := 1
const SLOT_COUNT := 3

enum Status { OK, EMPTY, RECOVERED_FROM_BACKUP, CORRUPT, UNSUPPORTED_VERSION, IO_ERROR }

signal saved(slot: int)
signal loaded(slot: int, status: Status)

var save_dir := "user://saves/"
## Migration callables: from version N to N+1, keyed by N.
var migrations := {}


func slot_path(slot: int) -> String:
	return save_dir.path_join("slot_%02d.json" % slot)


func save_slot(slot: int) -> Status:
	if slot < 1 or slot > SLOT_COUNT:
		return Status.IO_ERROR
	DirAccess.make_dir_recursive_absolute(save_dir)
	var data := GameState.to_dict()
	var env := {
		"schema_version": SCHEMA_VERSION,
		"game_version": App.VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"slot": slot,
		"area": GameState.player.get("area", ""),
		"play_time": GameState.play_time,
		"checksum": _checksum(data),
		"data": data,
	}
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return Status.IO_ERROR
	f.store_string(JSON.stringify(env, "\t"))
	f.close()
	if _read_envelope(tmp).status != Status.OK:
		DirAccess.remove_absolute(tmp)
		return Status.IO_ERROR
	if FileAccess.file_exists(path) and _read_envelope(path).status == Status.OK:
		DirAccess.copy_absolute(path, path + ".bak")
	if DirAccess.rename_absolute(tmp, path) != OK:
		return Status.IO_ERROR
	saved.emit(slot)
	return Status.OK


func load_slot(slot: int) -> Status:
	var path := slot_path(slot)
	var res := _read_envelope(path)
	var status: Status = res.status
	if status == Status.CORRUPT:
		var bak := _read_envelope(path + ".bak")
		DirAccess.copy_absolute(path, path + ".corrupt")
		if bak.status == Status.OK:
			res = bak
			status = Status.RECOVERED_FROM_BACKUP
	if res.status != Status.OK:
		loaded.emit(slot, status)
		return status
	var snapshot := GameState.to_dict()
	if not GameState.from_dict(res.data):
		GameState.from_dict(snapshot)
		loaded.emit(slot, Status.CORRUPT)
		return Status.CORRUPT
	loaded.emit(slot, status)
	return status


func slot_info(slot: int) -> Dictionary:
	var res := _read_envelope(slot_path(slot))
	if res.status != Status.OK:
		return {"slot": slot, "status": res.status}
	return {"slot": slot, "status": Status.OK, "saved_at": res.env.get("saved_at", ""), "area": res.env.get("area", ""), "play_time": res.env.get("play_time", 0.0)}


func delete_slot(slot: int) -> void:
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(slot_path(slot) + suffix):
			DirAccess.remove_absolute(slot_path(slot) + suffix)


func any_save_exists() -> bool:
	for s in range(1, SLOT_COUNT + 1):
		if FileAccess.file_exists(slot_path(s)):
			return true
	return false


## Returns {status, env, data}. Applies migrations for older schema versions.
func _read_envelope(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": Status.EMPTY}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"status": Status.IO_ERROR}
	var env = JSON.parse_string(f.get_as_text())
	if not env is Dictionary or not env.get("data") is Dictionary or not env.has("schema_version"):
		return {"status": Status.CORRUPT}
	var version := int(env.schema_version)
	if version > SCHEMA_VERSION:
		return {"status": Status.UNSUPPORTED_VERSION}
	if str(env.get("checksum", "")) != _checksum(env.data):
		return {"status": Status.CORRUPT}
	var data: Dictionary = env.data
	while version < SCHEMA_VERSION:
		if not migrations.has(version):
			return {"status": Status.UNSUPPORTED_VERSION}
		data = migrations[version].call(data)
		version += 1
	return {"status": Status.OK, "env": env, "data": data}


func _checksum(data: Dictionary) -> String:
	# Re-encode through JSON so the hash is identical before and after a round trip.
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)), "", true).sha256_text()
