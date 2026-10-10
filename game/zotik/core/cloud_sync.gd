extends Node
## Cloud saves for the native apps (Windows, Linux, Android). Same Firebase project and the same
## document format as the browser script `cloud/anmacha-cloud.js` of the easygames repo, so a
## player's saves follow them between the web version and the apps.
## - Sign-in: Google device flow (code shown in the game, entered at google.com/device),
##   exchanged for a Firebase user via Identity Toolkit. Only the refresh token is stored.
## - Data: users/<uid>/saves/zotik, one string field "d" = JSON {"zotik_save_<slot>": {v, t}},
##   v = save envelope text, t = save time in ms. Per slot the newer save wins.
## - Browser build: does nothing here (the web script handles it).
## - Not configured (OAUTH_CLIENT_ID empty): does nothing, the game stays local-only.

signal state_changed

const PROJECT_ID := "ricorewi-games-save"
const API_KEY := "AIzaSyB-4IuC85PsOrvsY0GkBGsCIXdW_i1SrnM"
## OAuth client of type "TVs and Limited Input devices" (Google Cloud console). Shipped inside
## the app, so it is not a secret.
const OAUTH_CLIENT_ID := ""
const OAUTH_CLIENT_SECRET := ""
const GAME := "zotik"
const KEY_PREFIX := "zotik_save_"
const CFG_PATH := "user://cloud.cfg"
const COMPRESS_FROM := 20000
const MAX_DOC := 900000

var message := ""
var user_code := ""
var verify_url := ""
var _refresh := ""
var _uid := ""
var _id_token := ""
var _token_exp := 0
var _busy := false
var _login_running := false
var _timer: Timer


func configured() -> bool:
	return OAUTH_CLIENT_ID != "" and not OS.has_feature("web")


func signed_in() -> bool:
	return _refresh != ""


func _ready() -> void:
	if not configured():
		return
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		_refresh = str(cfg.get_value("auth", "refresh", ""))
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = 5.0
	_timer.timeout.connect(sync)
	add_child(_timer)
	SaveSystem.saved.connect(func(_slot): queue_sync())
	if signed_in():
		get_tree().create_timer(2.0).timeout.connect(sync)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and configured() and signed_in():
		sync()


func queue_sync() -> void:
	if signed_in() and _timer != null:
		_timer.start()


func _status(msg: String) -> void:
	message = msg
	state_changed.emit()


# ---- pure helpers (tested) ----

## local / remote: key -> {v: String, t: int(ms)}. Per key the newer entry wins.
static func merge(local: Dictionary, remote: Dictionary) -> Dictionary:
	var apply := {}
	var push := {}
	for k in remote:
		if not local.has(k) or int(remote[k].get("t", 0)) > int(local[k].get("t", 0)):
			apply[k] = remote[k]
	for k in local:
		if not remote.has(k) or int(local[k].get("t", 0)) > int(remote[k].get("t", 0)):
			push[k] = local[k]
	return {"apply": apply, "push": push}


## Document string "d" (plain JSON or "z:" + base64 gzip, as written by the web script).
static func decode_doc(d: String) -> Dictionary:
	var text := d
	if d.begins_with("z:"):
		var bytes := Marshalls.base64_to_raw(d.substr(2))
		var raw := bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
		if raw.is_empty():
			return {}
		text = raw.get_string_from_utf8()
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return {}
	return parser.data


static func encode_doc(entries: Dictionary) -> String:
	var text := JSON.stringify(entries)
	if text.length() < COMPRESS_FROM:
		return text
	return "z:" + Marshalls.raw_to_base64(text.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))


## Save time of an envelope text in ms (0 if unreadable).
static func envelope_ms(text: String) -> int:
	var env = JSON.parse_string(text)
	if not env is Dictionary:
		return 0
	return int(Time.get_unix_time_from_datetime_string(str(env.get("saved_at", ""))) * 1000.0)


func _local_state() -> Dictionary:
	var o := {}
	for slot in range(SaveSystem.AUTO_SLOT, SaveSystem.SLOT_COUNT + 1):
		var text := SaveSystem.raw_text(slot)
		if text != "":
			o[KEY_PREFIX + str(slot)] = {"v": text, "t": envelope_ms(text)}
	return o


# ---- http ----

func _http(url: String, method: int, headers: PackedStringArray, body: String) -> Dictionary:
	var r := HTTPRequest.new()
	r.timeout = 20.0
	add_child(r)
	if r.request(url, headers, method, body) != OK:
		r.queue_free()
		return {"code": 0, "json": {}}
	var res = await r.request_completed
	r.queue_free()
	var j = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	return {"code": int(res[1]) if int(res[0]) == HTTPRequest.RESULT_SUCCESS else 0, "json": j if j is Dictionary else {}}


const FORM := ["Content-Type: application/x-www-form-urlencoded"]


# ---- sign-in ----

func start_login() -> void:
	if _login_running or not configured():
		return
	_login_running = true
	var r := await _http("https://oauth2.googleapis.com/device/code", HTTPClient.METHOD_POST, FORM, "client_id=%s&scope=%s" % [OAUTH_CLIENT_ID.uri_encode(), "openid email profile".uri_encode()])
	if r.code != 200 or not r.json.has("device_code"):
		_login_end("Anmeldung gerade nicht möglich (%d)." % r.code)
		return
	var j: Dictionary = r.json
	user_code = str(j.get("user_code", ""))
	verify_url = str(j.get("verification_url", "https://www.google.com/device"))
	var interval := float(j.get("interval", 5))
	var deadline := Time.get_ticks_msec() + int(j.get("expires_in", 600)) * 1000
	_status("Öffne %s auf einem beliebigen Gerät und gib den Code %s ein." % [verify_url, user_code])
	while _login_running and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(interval).timeout
		var t := await _http("https://oauth2.googleapis.com/token", HTTPClient.METHOD_POST, FORM, "client_id=%s&client_secret=%s&device_code=%s&grant_type=%s" % [OAUTH_CLIENT_ID.uri_encode(), OAUTH_CLIENT_SECRET.uri_encode(), str(j.device_code).uri_encode(), "urn:ietf:params:oauth:grant-type:device_code".uri_encode()])
		if t.code == 200 and t.json.has("id_token"):
			await _firebase_login(str(t.json.id_token))
			return
		var err := str(t.json.get("error", ""))
		if err == "slow_down":
			interval += 5.0
		elif err != "authorization_pending" and t.code != 0:
			_login_end("Anmeldung abgelehnt oder abgelaufen.")
			return
	_login_end("Anmeldung abgelaufen.")


func _firebase_login(google_id_token: String) -> void:
	var body := JSON.stringify({"postBody": "id_token=%s&providerId=google.com" % google_id_token, "requestUri": "http://localhost", "returnIdpCredential": true, "returnSecureToken": true})
	var r := await _http("https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=" + API_KEY, HTTPClient.METHOD_POST, ["Content-Type: application/json"], body)
	if r.code != 200 or not r.json.has("refreshToken"):
		_login_end("Firebase-Anmeldung fehlgeschlagen (%d)." % r.code)
		return
	_apply_token(str(r.json.idToken), str(r.json.refreshToken), str(r.json.localId), int(r.json.get("expiresIn", 3600)))
	_login_running = false
	user_code = ""
	_status("Angemeldet.")
	sync()


func _login_end(msg: String) -> void:
	_login_running = false
	user_code = ""
	_status(msg)


func sign_out() -> void:
	_refresh = ""
	_uid = ""
	_id_token = ""
	_login_running = false
	user_code = ""
	DirAccess.remove_absolute(CFG_PATH)
	_status("Abgemeldet. Spielstände bleiben auf diesem Gerät.")


func _apply_token(id_token: String, refresh: String, uid: String, expires_in: int) -> void:
	_id_token = id_token
	_refresh = refresh
	_uid = uid
	_token_exp = int(Time.get_unix_time_from_system()) + expires_in
	var cfg := ConfigFile.new()
	cfg.set_value("auth", "refresh", refresh)
	cfg.save(CFG_PATH)


func _ensure_token() -> bool:
	if _id_token != "" and int(Time.get_unix_time_from_system()) < _token_exp - 60:
		return true
	var r := await _http("https://securetoken.googleapis.com/v1/token?key=" + API_KEY, HTTPClient.METHOD_POST, FORM, "grant_type=refresh_token&refresh_token=" + _refresh.uri_encode())
	if r.code != 200 or not r.json.has("id_token"):
		return false
	_apply_token(str(r.json.id_token), str(r.json.get("refresh_token", _refresh)), str(r.json.user_id), int(r.json.get("expires_in", 3600)))
	return true


# ---- sync ----

func _doc_url() -> String:
	return "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s/saves/%s" % [PROJECT_ID, _uid, GAME]


func sync() -> void:
	if _busy or not signed_in():
		return
	_busy = true
	_status("Synchronisiere …")
	var msg := await _sync_inner()
	_busy = false
	_status(msg)


func _sync_inner() -> String:
	if not await _ensure_token():
		return "Bitte erneut anmelden."
	var auth := PackedStringArray(["Authorization: Bearer " + _id_token])
	var g := await _http(_doc_url(), HTTPClient.METHOD_GET, auth, "")
	var remote := {}
	if g.code == 200:
		remote = decode_doc(str(g.json.get("fields", {}).get("d", {}).get("stringValue", "")))
	elif g.code != 404:
		return "Laden fehlgeschlagen (%d)." % g.code
	var m := merge(_local_state(), remote)
	var applied := 0
	for k in m.apply:
		var slot := int(str(k).substr(KEY_PREFIX.length()))
		if SaveSystem.store_raw(slot, str(m.apply[k].get("v", ""))):
			applied += 1
	if not m.push.is_empty():
		var combined := remote.duplicate()
		for k in m.push:
			combined[k] = m.push[k]
		var d := encode_doc(combined)
		if d.length() > MAX_DOC:
			return "Spielstand zu groß für die Cloud."
		var body := JSON.stringify({"fields": {"d": {"stringValue": d}, "t": {"integerValue": str(int(Time.get_unix_time_from_system() * 1000.0))}}})
		var p := await _http(_doc_url() + "?updateMask.fieldPaths=d&updateMask.fieldPaths=t", HTTPClient.METHOD_PATCH, PackedStringArray(["Authorization: Bearer " + _id_token, "Content-Type: application/json"]), body)
		if p.code != 200:
			return "Speichern fehlgeschlagen (%d)." % p.code
	var t := Time.get_time_dict_from_system()
	return "Zuletzt synchronisiert um %02d:%02d.%s" % [t.hour, t.minute, " %d Spielstand/-stände geladen." % applied if applied > 0 else ""]
