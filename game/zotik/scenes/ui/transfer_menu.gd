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


func refresh() -> void:
	super()
	title_label.text = "Spielstand übertragen"
	info_label.text = "Exportieren erzeugt einen Code (Kopieren oder als Datei), mit dem du einen Spielstand auf einem anderen Gerät oder Browser einspielen kannst."
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
	add_row("Aus der Zwischenablage einfügen", [["Einfügen", _paste.bind(imp)]])
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
