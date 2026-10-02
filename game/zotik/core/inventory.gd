class_name Inventory
extends RefCounted
## Inventory, equipment and currency operations on GameState.


static func count(id: String) -> int:
	return int(GameState.inventory.get(id, 0))


static func add(id: String, amount: int = 1) -> int:
	var it := Content.item(id)
	if it.is_empty() or amount <= 0:
		return 0
	var have := count(id)
	var added := mini(amount, int(it.get("stack", 99)) - have)
	if added <= 0:
		return 0
	GameState.inventory[id] = have + added
	EventBus.item_added.emit(id, added)
	return added


static func remove(id: String, amount: int = 1) -> bool:
	if amount <= 0 or count(id) < amount or is_equipped(id) and count(id) - amount < 1:
		return false
	GameState.inventory[id] = count(id) - amount
	if GameState.inventory[id] == 0:
		GameState.inventory.erase(id)
	EventBus.item_removed.emit(id, amount)
	return true


static func is_equipped(id: String) -> bool:
	return id in GameState.equipment.values()


static func equip(id: String) -> bool:
	var slot: String = Content.item(id).get("slot", "")
	if slot == "" or count(id) < 1:
		return false
	GameState.equipment[slot] = id
	GameState.player.max_hp = Stats.max_hp()
	GameState.player.hp = mini(int(GameState.player.hp), Stats.max_hp())
	return true


static func unequip(slot: String) -> void:
	if slot == "weapon":
		return  # Zotik always keeps a weapon equipped once he has one.
	GameState.equipment.erase(slot)
	GameState.player.max_hp = Stats.max_hp()
	GameState.player.hp = mini(int(GameState.player.hp), Stats.max_hp())


static func add_currency(amount: int) -> void:
	GameState.currency = maxi(0, GameState.currency + amount)
	EventBus.currency_changed.emit(GameState.currency)


## Grants a unique reward at most once per save, regardless of how often it is triggered.
static func grant_unique(id: String) -> bool:
	if GameState.unique_rewards.has(id):
		return false
	GameState.unique_rewards[id] = true
	add(id, 1)
	return true
