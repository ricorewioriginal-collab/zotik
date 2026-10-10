class_name TransferMenu
extends MenuPanel
## Move a save to another device: export a slot as a text code (copy / download) and import
## a code into one of the three manual slots.

signal imported

var _export_slot := -1
var _export_code := ""
var _import_text := ""
var _result := ""
var _confirm := -1
var _file_cb: JavaScriptObject


func _ready() -> void:
	super()
	CloudSync.state_changed.connect(func(): if visible: refresh())


func refresh() -> void:
	super()
	title_label.text = "Spielstand übertragen"
	info_label.text = "Exportieren erzeugt einen Code (Kopieren oder als Datei), mit dem du einen Spielstand auf einem anderen Gerät oder Browser einspielen kannst."
	if CloudSync.configured():
		add_heading("Cloud-Speicher")
		if CloudSync.signed_in():
			var who: String = CloudSync.account_name if CloudSync.account_name != "" else "Google-Konto"
			add_row("Mit Google verbunden: %s%s" % [who, " (%s)" % CloudSync.account_email if CloudSync.account_email != "" else ""], [["In Google speichern", CloudSync.sync], ["Mit Google wiederherstellen", CloudSync.restore], ["Abmelden", CloudSync.sign_out]])
		elif CloudSync.user_code != "":
			add_row("Code %s" % CloudSync.user_code, [["Abbrechen", CloudSync.sign_out]])
		else:
			add_row("Spielstand mit Google speichern oder auf diesem Gerät wiederherstellen", [["Mit Google anmelden", CloudSync.start_login]])
		if CloudSync.message != "":
			add_note(CloudSync.message)
	add_heading("Exportieren")
	for slot in [SaveSystem.AUTO_SLOT, 1, 2, 3]:
		var info := SaveSystem.slot_info(slot)
		if info.status in [SaveSystem.Status.OK, SaveSystem.Status.RECOVERED_FROM_BACKUP]:
			add_row("%s – %s, %s" % [_slot_name(slot), Content.get_entry("areas", info.area).get("name", info.area), info.saved_at], [["Code erzeugen", _make_code.bind(slot)]])
	if _export_code != "":
		add_note("Code für %s (%d Zeichen):" % [_slot_name(_export_slot), _export_code.length()])
		var te := TextEdit.new()
		te.text = _export_code
		te.editable = false
		te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		te.custom_minimum_size = Vector2(760, 110)
		list.add_child(te)
		var actions := [["In Zwischenablage kopieren", _copy_code]]
		if OS.has_feature("web"):
			actions.append(["Als Datei laden", _download_code])
		elif _native_files():
			actions.append(["Als Datei speichern", _save_code_file])
		add_row("Code weitergeben", actions)
	add_heading("Importieren")
	add_note("Code hier einfügen (Strg+V, am Handy langes Tippen und Einfügen) und den Ziel-Slot wählen. Ein belegter Slot fragt vor dem Überschreiben nach.")
	var imp := TextEdit.new()
	imp.text = _import_text
	imp.placeholder_text = "ZOTIK1:…"
	imp.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	imp.custom_minimum_size = Vector2(760, 90)
	imp.text_changed.connect(func(): _import_text = imp.text)
	list.add_child(imp)
	var pick := [["Einfügen", _paste.bind(imp)]]
	if OS.has_feature("web") or _native_files():
		pick.append(["Datei wählen", _pick_file])
	add_row("Code aus der Zwischenablage einfügen oder aus einer Datei laden (Export-Datei oder kopierte Spielstand-Datei slot_01.json)", pick)
	for slot in range(1, SaveSystem.SLOT_COUNT + 1):
		var used: bool = SaveSystem.slot_info(slot).status in [SaveSystem.Status.OK, SaveSystem.Status.RECOVERED_FROM_BACKUP]
		var label := "Importieren"
		if used:
			label = "Wirklich überschreiben?" if _confirm == slot else "Überschreiben"
		add_row("In Slot %d importieren%s" % [slot, " (belegt)" if used else ""], [[label, _import.bind(slot)]])
	if _result != "":
		add_note(_result)
	_confirm = -1


static func _slot_name(slot: int) -> String:
	return "Autospeicherung" if slot == SaveSystem.AUTO_SLOT else "Slot %d" % slot


func _make_code(slot: int) -> void:
	_export_slot = slot
	_export_code = SaveSystem.export_code(slot)
	_result = "" if _export_code != "" else "Dieser Slot enthält keinen gültigen Spielstand."
	refresh()


func _copy_code() -> void:
	DisplayServer.clipboard_set(_export_code)
	EventBus.notify.emit("Code kopiert.")


func _download_code() -> void:
	var fname := "zotik_%s.txt" % ("autosave" if _export_slot == SaveSystem.AUTO_SLOT else "slot%d" % _export_slot)
	JavaScriptBridge.download_buffer(_export_code.to_utf8_buffer(), fname, "text/plain")


static func _native_files() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE)


## Browser: a hidden file input; native: the system file dialog (Windows, macOS, Linux, Android).
func _pick_file() -> void:
	if OS.has_feature("web"):
		_file_cb = JavaScriptBridge.create_callback(func(args): _apply_file_text(str(args[0]) if args.size() > 0 else ""))
		JavaScriptBridge.get_interface("window").zotikImportCb = _file_cb
		JavaScriptBridge.eval("(function(){var i=document.createElement('input');i.type='file';i.accept='.txt,.json,.zotik,text/plain,application/json';i.onchange=function(){var f=i.files[0];if(!f){return;}var r=new FileReader();r.onload=function(){window.zotikImportCb(String(r.result));};r.readAsText(f);};i.click();})()")
	elif _native_files():
		DisplayServer.file_dialog_show("Spielstand-Datei wählen", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(["*.txt,*.json,*.zotik ; Spielstand"]), _on_native_file)


func _on_native_file(ok: bool, paths: PackedStringArray, _filter: int) -> void:
	if not ok or paths.is_empty():
		return
	var text := FileAccess.get_file_as_string(paths[0])
	if text == "" and FileAccess.get_open_error() != OK:
		_result = "Die Datei konnte nicht gelesen werden."
		refresh()
		return
	_apply_file_text(text)


## Text of a chosen file: the Spielstand code or a raw save file. The slot is chosen next.
func _apply_file_text(text: String) -> void:
	_import_text = text.strip_edges()
	if _import_text == "":
		_result = "Die Datei ist leer."
	elif _import_text.length() > SaveSystem.CODE_MAX_BYTES:
		_import_text = ""
		_result = "Die Datei ist zu groß für einen Spielstand."
	else:
		_result = "Datei geladen. Jetzt unten den Ziel-Slot wählen."
	refresh()


func _save_code_file() -> void:
	var fname := "zotik_%s.txt" % ("autosave" if _export_slot == SaveSystem.AUTO_SLOT else "slot%d" % _export_slot)
	DisplayServer.file_dialog_show("Spielstand-Datei speichern", "", fname, false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, PackedStringArray(["*.txt ; Spielstand"]), func(ok: bool, paths: PackedStringArray, _f: int):
		if not ok or paths.is_empty():
			return
		var f := FileAccess.open(paths[0], FileAccess.WRITE)
		if f == null:
			_result = "Die Datei konnte nicht geschrieben werden."
		else:
			f.store_string(_export_code)
			f.close()
			_result = "Datei gespeichert."
		refresh())


func _paste(imp: TextEdit) -> void:
	_import_text = DisplayServer.clipboard_get()
	imp.text = _import_text
	if _import_text.strip_edges() == "":
		_result = "Die Zwischenablage ist leer (oder der Browser erlaubt das Einfügen nicht – dann Strg+V im Feld benutzen)."
		refresh()


func _import(slot: int) -> void:
	var used: bool = SaveSystem.slot_info(slot).status in [SaveSystem.Status.OK, SaveSystem.Status.RECOVERED_FROM_BACKUP]
	if used and _confirm != slot:
		_confirm = slot
		refresh()
		_confirm = slot
		return
	var status := SaveSystem.import_code(_import_text, slot)
	match status:
		SaveSystem.Status.OK:
			_result = "Spielstand in Slot %d importiert." % slot
			_import_text = ""
			imported.emit()
		SaveSystem.Status.UNSUPPORTED_VERSION:
			_result = "Dieser Spielstand stammt aus einer neueren Spielversion."
		SaveSystem.Status.IO_ERROR:
			_result = "Speichern ist fehlgeschlagen."
		_:
			_result = "Der Code ist unvollständig oder beschädigt."
	_confirm = -1
	refresh()
