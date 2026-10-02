class_name Shop
extends RefCounted
## Buy/sell rules for data/shops.json.

enum Result { OK, NOT_IN_STOCK, NOT_ENOUGH_CURRENCY, INVENTORY_FULL, NOT_SELLABLE, NOT_OWNED, EQUIPPED }


static func price(item_id: String) -> int:
	return int(Content.item(item_id).get("price", 0))


static func sell_price(shop_id: String, item_id: String) -> int:
	return int(floor(price(item_id) * float(Content.get_entry("shops", shop_id).get("sell_ratio", 0.5))))


static func buy(shop_id: String, item_id: String) -> Result:
	if not item_id in Content.get_entry("shops", shop_id).get("stock", []):
		return Result.NOT_IN_STOCK
	if GameState.currency < price(item_id):
		return Result.NOT_ENOUGH_CURRENCY
	if Inventory.count(item_id) >= int(Content.item(item_id).get("stack", 99)):
		return Result.INVENTORY_FULL
	Inventory.add_currency(-price(item_id))
	Inventory.add(item_id, 1)
	return Result.OK


static func can_sell(item_id: String) -> bool:
	var it := Content.item(item_id)
	return price(item_id) > 0 and it.get("type") != "key" and not it.get("unique", false)


static func sell(shop_id: String, item_id: String) -> Result:
	if not can_sell(item_id):
		return Result.NOT_SELLABLE
	if Inventory.is_equipped(item_id) and Inventory.count(item_id) <= 1:
		return Result.EQUIPPED
	if not Inventory.remove(item_id, 1):
		return Result.NOT_OWNED
	Inventory.add_currency(sell_price(shop_id, item_id))
	return Result.OK
