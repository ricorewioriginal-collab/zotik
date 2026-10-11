class_name InventoryMenu
extends MenuPanel
## Inventory and equipment overview.

var player: Node


func refresh() -> void:
	super()
	title_label.text = "Inventar"
	info_label.text = "Lun: %d   ·   Angriff: %d   ·   Verteidigung: %d   ·   LP: %d/%d" % [GameState.currency, Stats.attack(), Stats.defense(), int(GameState.player.hp), Stats.max_hp()]
	var ids := GameState.inventory.keys()
	ids.sort()
	for id in ids:
		var it := Content.item(id)
		var actions := []
		if it.has("slot"):
			var equipped := Inventory.is_equipped(id)
			actions.append(["Ausgerüstet" if equipped else "Ausrüsten", equip.bind(id), not equipped])
			if equipped and it.slot != "weapon":
				actions.append(["Ablegen", unequip.bind(it.slot)])
		elif it.get("type") == "consumable":
			actions.append(["Benutzen", use.bind(id)])
		if it.has("lore"):
			actions.append(["Lesen", read.bind(id)])
		add_row("%s  x%d" % [it.name, Inventory.count(id)], actions)


func equip(id: String) -> void:
	Inventory.equip(id)
	refresh()


func unequip(slot: String) -> void:
	Inventory.unequip(slot)
	refresh()


## Keepsakes and shards carry a short text: it opens in the dialogue box.
func read(id: String) -> void:
	var lore: String = Content.item(id).get("lore", "")
	if lore == "":
		return
	close_menu()
	Dialogue.read_lore(lore)


func use(id: String) -> void:
	if not Inventory.use(id, player):
		EventBus.notify.emit("Das hat gerade keine Wirkung.")
	refresh()
