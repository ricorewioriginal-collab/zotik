class_name SaveMenu
extends MenuPanel
## Slot selection (Weltenanker or pause menu). Overwriting a used slot asks first.

var _confirm := -1


func refresh() -> void:
	super()
	title_label.text = "Spielstand speichern"
	info_label.text = "Wähle einen Slot. Zusätzlich speichert das Spiel automatisch (Gebietswechsel, App im Hintergrund)."
	for slot in range(1, SaveSystem.SLOT_COUNT + 1):
		var info := SaveSystem.slot_info(slot)
		var used: bool = info.status in [SaveSystem.Status.OK, SaveSystem.Status.RECOVERED_FROM_BACKUP]
		var text := "Slot %d – leer" % slot
		if used:
			text = "Slot %d – %s, %s, %s" % [slot, Content.get_entry("areas", info.area).get("name", info.area), _time(info.play_time), info.saved_at]
		var label := "Speichern"
		if used:
			label = "Wirklich überschreiben?" if _confirm == slot else "Überschreiben"
		add_row(text, [[label, save.bind(slot)]])
	_confirm = -1


static func _time(t: float) -> String:
	return "%d:%02d h" % [int(t) / 3600, (int(t) / 60) % 60]


func save(slot: int) -> void:
	var used: bool = SaveSystem.slot_info(slot).status in [SaveSystem.Status.OK, SaveSystem.Status.RECOVERED_FROM_BACKUP]
	if used and _confirm != slot:
		_confirm = slot
		refresh()
		_confirm = slot
		return
	if SaveSystem.save_slot(slot) == SaveSystem.Status.OK:
		EventBus.notify.emit("Gespeichert in Slot %d." % slot)
	else:
		EventBus.notify.emit("Speichern fehlgeschlagen!")
	_confirm = -1
	refresh()
