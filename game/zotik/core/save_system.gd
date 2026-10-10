extends Node
## Local-first slot saves.
## - Envelope with schema_version, game_version, timestamp and SHA-256 checksum.
## - Atomic write: write .tmp, keep previous valid save as .bak, rename.
## - Corrupt or tampered slot: the file is kept as .corrupt and the .bak is loaded.
## - Newer schema versions are rejected (no unsafe downgrade).
## - Slot 0 is the autosave (area changes, app pause, page hide); slots 1-3 are manual.
## - Browser: every save is mirrored synchronously into localStorage, because the
##   IndexedDB file system behind user:// is flushed asynchronously and can be lost when
##   the tab closes; loading takes the newest valid copy of file and mirror.

const SCHEMA_VERSION := 2
const SLOT_COUNT := 3
const AUTO_SLOT := 0
const MIRROR_PREFIX := "zotik_save_"
const CODE_PREFIX := "ZOTIK1:"
const CODE_MAX_BYTES := 8 * 1024 * 1024

enum Status { OK, EMPTY, RECOVERED_FROM_BACKUP, CORRUPT, UNSUPPORTED_VERSION, IO_ERROR }

signal saved(slot: int)
signal loaded(slot: int, status: Status)

var save_dir := "user://saves/"
## Migration callables: from version N to N+1, keyed by N.
var migrations := {}
## Tests: a Dictionary here replaces the browser localStorage (slot -> text); null = real one.
var mirror_override = null
## Autosaves only while a game is running (set by the game root), never in headless tests.
var autosave_ready := false
var _page_cb: JavaScriptObject

## Built-in migrations shipped with the game (tests may replace `migrations`).
const BUILTIN_MIGRATIONS := {1: "_migrate_1_to_2"}


func _ready() -> void:
	reset_migrations()
	if OS.has_feature("web"):
		_hook_page_events()


## Browser: save when the page is hidden or closed (synchronous localStorage mirror).
func _hook_page_events() -> void:
	_page_cb = JavaScriptBridge.create_callback(func(_args): autosave())
	var win := JavaScriptBridge.get_interface("window")
	if win == null:
		return
	win.addEventListener("pagehide", _page_cb)
	win.addEventListener("beforeunload", _page_cb)
	JavaScriptBridge.get_interface("document").addEventListener("visibilitychange", _page_cb)


## Quiet save into slot 0 while a game is running.
func autosave() -> void:
	if autosave_ready and GameState.player.get("area", "") != "":
		save_slot(AUTO_SLOT)


func reset_migrations() -> void:
	migrations = {}
	for v in BUILTIN_MIGRATIONS:
		migrations[v] = Callable(self, BUILTIN_MIGRATIONS[v])


## v1 (Phase 1) -> v2 (Phase 2): adds the party list.
func _migrate_1_to_2(d: Dictionary) -> Dictionary:
	if not d.get("party") is Array:
		d["party"] = []
	return d


func slot_path(slot: int) -> String:
	return save_dir.path_join("autosave.json" if slot == AUTO_SLOT else "slot_%02d.json" % slot)


func _use_mirror() -> bool:
	return mirror_override != null or OS.has_feature("web")


func _mirror_write(slot: int, text: String) -> bool:
	if mirror_override != null:
		mirror_override[slot] = text
		return true
	if not OS.has_feature("web"):
		return false
	var key := JSON.stringify(MIRROR_PREFIX + str(slot))
	var ok = JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s);return true;}catch(e){return false;}})()" % [key, JSON.stringify(text)])
	return ok == true


func _mirror_read(slot: int) -> String:
	if mirror_override != null:
		return str(mirror_override.get(slot, ""))
	if not OS.has_feature("web"):
		return ""
	var v = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)||'';}catch(e){return '';}})()" % JSON.stringify(MIRROR_PREFIX + str(slot)))
	return str(v) if v != null else ""


func _mirror_remove(slot: int) -> void:
	if mirror_override != null:
		mirror_override.erase(slot)
	elif OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.removeItem(%s);}catch(e){}})()" % JSON.stringify(MIRROR_PREFIX + str(slot)))


func save_slot(slot: int) -> Status:
	if slot < AUTO_SLOT or slot > SLOT_COUNT:
		return Status.IO_ERROR
	DirAccess.make_dir_recursive_absolute(save_dir)
	EventBus.sync_state.emit()
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
	var text := JSON.stringify(env, "\t")
	var file_ok := _write_file(slot, text)
	var mirror_ok := _use_mirror() and _mirror_write(slot, text)
	if not file_ok and not mirror_ok:
		return Status.IO_ERROR
	saved.emit(slot)
	return Status.OK


## Writes the slot file. Native: temp file + backup + rename. Browser: straight write
## (every closed file triggers the IndexedDB flush; a rename would not).
func _write_file(slot: int, text: String) -> bool:
	var path := slot_path(slot)
	var web := OS.has_feature("web")
	if FileAccess.file_exists(path) and _read_envelope(path).status == Status.OK:
		DirAccess.copy_absolute(path, path + ".bak")
	var target := path if web else path + ".tmp"
	var f := FileAccess.open(target, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	if _read_envelope(target).status != Status.OK:
		DirAccess.remove_absolute(target)
		return false
	if web:
		return true
	if DirAccess.rename_absolute(target, path) != OK:
		# some platforms refuse to rename over an existing file
		DirAccess.remove_absolute(path)
		if DirAccess.rename_absolute(target, path) != OK:
			return false
	return true


## Newest valid copy of a slot from the file and the browser mirror.
## Returns {status, env, data}; falls back to the file's .bak, then reports the problem.
func _best(slot: int) -> Dictionary:
	var path := slot_path(slot)
	var from_file := _read_envelope(path)
	var from_mirror := {"status": Status.EMPTY}
	if _use_mirror():
		var text := _mirror_read(slot)
		if text != "":
			from_mirror = _parse_envelope(text)
	if from_file.status == Status.OK and from_mirror.status == Status.OK:
		return from_mirror if str(from_mirror.env.get("saved_at", "")) > str(from_file.env.get("saved_at", "")) else from_file
	if from_file.status == Status.OK:
		return from_file
	if from_mirror.status == Status.OK:
		return from_mirror
	if from_file.status == Status.CORRUPT:
		var bak := _read_envelope(path + ".bak")
		if bak.status == Status.OK:
			bak["status"] = Status.RECOVERED_FROM_BACKUP
			return bak
	if from_file.status == Status.EMPTY and from_mirror.status != Status.EMPTY:
		return from_mirror
	return from_file


## Transfer code of a slot ("ZOTIK1:<size>:<base64 of the deflated save envelope>") for moving
## a save to another device by copy and paste or a text file. "" if the slot has no valid save.
func export_code(slot: int) -> String:
	var res := _best(slot)
	if res.status != Status.OK and res.status != Status.RECOVERED_FROM_BACKUP:
		return ""
	var bytes := JSON.stringify(res.env).to_utf8_buffer()
	return "%s%d:%s" % [CODE_PREFIX, bytes.size(), Marshalls.raw_to_base64(bytes.compress(FileAccess.COMPRESSION_DEFLATE))]


## Imports a transfer code into a manual slot (1-3). The save must pass the normal checks
## (structure, checksum, schema version). Returns OK or the reason it was refused.
func import_code(code: String, slot: int) -> Status:
	if slot < 1 or slot > SLOT_COUNT:
		return Status.IO_ERROR
	var text := ""
	var clean := code.strip_edges()
	if clean.begins_with("{"):
		# a raw save file (slot_01.json copied from another device)
		text = clean
	else:
		text = _decode_code(clean.replace("\n", "").replace("\r", "").replace(" ", "").replace("\t", ""))
		if text == "":
			return Status.CORRUPT
	var res := _parse_envelope(text)
	if res.status != Status.OK:
		return res.status
	DirAccess.make_dir_recursive_absolute(save_dir)
	var file_ok := _write_file(slot, text)
	var mirror_ok := _use_mirror() and _mirror_write(slot, text)
	if not file_ok and not mirror_ok:
		return Status.IO_ERROR
	saved.emit(slot)
	return Status.OK


## "ZOTIK1:<size>:<base64>" -> envelope JSON text, "" if anything is wrong.
func _decode_code(clean: String) -> String:
	if not clean.begins_with(CODE_PREFIX):
		return ""
	var parts := clean.trim_prefix(CODE_PREFIX).split(":", false)
	if parts.size() != 2 or not parts[0].is_valid_int():
		return ""
	var size := int(parts[0])
	if size <= 0 or size > CODE_MAX_BYTES:
		return ""
	var packed := Marshalls.base64_to_raw(parts[1])
	if packed.is_empty():
		return ""
	var bytes := packed.decompress(size, FileAccess.COMPRESSION_DEFLATE)
	if bytes.size() != size:
		return ""
	return bytes.get_string_from_utf8()


func load_slot(slot: int) -> Status:
	var res := _best(slot)
	var status: Status = res.status
	if _read_envelope(slot_path(slot)).status == Status.CORRUPT:
		DirAccess.copy_absolute(slot_path(slot), slot_path(slot) + ".corrupt")
	if status != Status.OK and status != Status.RECOVERED_FROM_BACKUP:
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
	var res := _best(slot)
	var status: Status = res.status
	if status != Status.OK and status != Status.RECOVERED_FROM_BACKUP:
		return {"slot": slot, "status": status}
	return {"slot": slot, "status": status, "saved_at": res.env.get("saved_at", ""), "area": res.env.get("area", ""), "play_time": res.env.get("play_time", 0.0)}


func delete_slot(slot: int) -> void:
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(slot_path(slot) + suffix):
			DirAccess.remove_absolute(slot_path(slot) + suffix)
	_mirror_remove(slot)


func any_save_exists() -> bool:
	for s in range(AUTO_SLOT, SLOT_COUNT + 1):
		if FileAccess.file_exists(slot_path(s)) or (_use_mirror() and _mirror_read(s) != ""):
			return true
	return false


## Returns {status, env, data}. Applies migrations for older schema versions.
func _read_envelope(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": Status.EMPTY}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"status": Status.IO_ERROR}
	return _parse_envelope(f.get_as_text())


func _parse_envelope(text: String) -> Dictionary:
	var env = JSON.parse_string(text)
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
