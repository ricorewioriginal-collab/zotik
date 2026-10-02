class_name SaveMenu
extends MenuPanel
## Slot selection at a savepoint.


func refresh() -> void:
	super()
	title_label.text = "Spielstand speichern"
	info_label.text = "Wähle einen Slot."
	for slot in range(1, SaveSystem.SLOT_COUNT + 1):
		var info := SaveSystem.slot_info(slot)
		var text := "Slot %d – leer" % slot
		if info.status in [SaveSystem.Status.OK, SaveSystem.Status.RECOVERED_FROM_BACKUP]:
			text = "Slot %d – %s, %s" % [slot, Content.get_entry("areas", info.area).get("name", info.area), info.saved_at]
		add_row(text, [["Speichern", save.bind(slot)]])


func save(slot: int) -> void:
	if SaveSystem.save_slot(slot) == SaveSystem.Status.OK:
		EventBus.notify.emit("Gespeichert in Slot %d." % slot)
	else:
		EventBus.notify.emit("Speichern fehlgeschlagen!")
	refresh()
