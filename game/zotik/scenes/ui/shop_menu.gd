class_name ShopMenu
extends MenuPanel
## Buy/sell UI for one shop.

const MESSAGES := {Shop.Result.NOT_ENOUGH_CURRENCY: "Nicht genug Lun.", Shop.Result.INVENTORY_FULL: "Davon kannst du nicht mehr tragen.", Shop.Result.NOT_SELLABLE: "Das kann nicht verkauft werden.", Shop.Result.EQUIPPED: "Ausgerüstetes kannst du nicht verkaufen."}

var shop_id := ""


func open_shop(id: String) -> void:
	shop_id = id
	open()


func refresh() -> void:
	super()
	var npc: String = Content.get_entry("shops", shop_id).get("npc", "")
	title_label.text = "Laden: " + Content.speaker_name(npc)
	info_label.text = "Lun: %d" % GameState.currency
	for id in Content.get_entry("shops", shop_id).get("stock", []):
		add_row("Kaufen: %s – %d Lun (du hast %d)" % [Content.item(id).name, Shop.price(id), Inventory.count(id)], [["Kaufen", buy.bind(id), GameState.currency >= Shop.price(id)]])
	var ids := GameState.inventory.keys()
	ids.sort()
	for id in ids:
		if Shop.can_sell(id) and not (Inventory.is_equipped(id) and Inventory.count(id) <= 1):
			add_row("Verkaufen: %s – %d Lun" % [Content.item(id).name, Shop.sell_price(shop_id, id)], [["Verkaufen", sell.bind(id)]])


func buy(id: String) -> void:
	_report(Shop.buy(shop_id, id))


func sell(id: String) -> void:
	_report(Shop.sell(shop_id, id))


func _report(r: Shop.Result) -> void:
	if MESSAGES.has(r):
		EventBus.notify.emit(MESSAGES[r])
	refresh()
