class_name Effects
extends RefCounted
## Executes data-defined effects (validated by Content). Single place where
## content changes game state.


static func run(list: Array) -> void:
	for fx in list:
		apply(fx)


static func apply(fx: Dictionary) -> void:
	match fx.get("type", ""):
		"set_flag": GameState.set_flag(fx.id, fx.get("value", true))
		"give_item":
			if Content.item(fx.id).get("unique", false):
				Inventory.grant_unique(fx.id)
			else:
				Inventory.add(fx.id, int(fx.get("count", 1)))
		"take_item": Inventory.remove(fx.id, int(fx.get("count", 1)))
		"give_currency": Inventory.add_currency(int(fx.amount))
		"equip": Inventory.equip(fx.id)
		"start_quest": Quests.start(fx.id)
		"open_shop": EventBus.shop_requested.emit(fx.id)
		"play_cutscene": EventBus.cutscene_requested.emit(fx.id)
		"travel": EventBus.travel_requested.emit(fx.area, fx.spawn)
		_: push_error("Effects: unknown effect %s" % fx)
