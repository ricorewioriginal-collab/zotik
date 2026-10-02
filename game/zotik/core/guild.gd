extends Node
## Monster hunter guild: bestiary (every defeated enemy is recorded) and
## data-driven bounties (data/bounties.json). State lives in GameState.

const MAX_ACTIVE := 3

signal bounty_updated(id: String)


func _ready() -> void:
	EventBus.enemy_defeated.connect(_on_defeated)


func _on_defeated(enemy_id: String) -> void:
	GameState.bestiary[enemy_id] = int(GameState.bestiary.get(enemy_id, 0)) + 1
	for id in GameState.bounties:
		var b: Dictionary = GameState.bounties[id]
		if b.state == "ACTIVE" and Content.get_entry("bounties", id).enemy == enemy_id:
			b.progress = int(b.progress) + 1
			if int(b.progress) >= int(Content.get_entry("bounties", id).count):
				b.state = "DONE"
				EventBus.notify.emit("Kopfgeld erfüllt: %s – bei der Gilde abholen." % Content.get_entry("bounties", id).name)
			bounty_updated.emit(id)


func kills(enemy_id: String) -> int:
	return int(GameState.bestiary.get(enemy_id, 0))


func state(id: String) -> String:
	return str(GameState.bounties.get(id, {}).get("state", "AVAILABLE"))


func is_offered(id: String) -> bool:
	var flag: String = Content.get_entry("bounties", id).get("requires_flag", "")
	return flag == "" or GameState.has_flag(flag)


func active_count() -> int:
	return GameState.bounties.values().filter(func(b): return b.state in ["ACTIVE", "DONE"]).size()


func accept(id: String) -> bool:
	if not Content.has_id("bounties", id) or state(id) != "AVAILABLE" or not is_offered(id) or active_count() >= MAX_ACTIVE:
		return false
	GameState.bounties[id] = {"state": "ACTIVE", "progress": 0}
	bounty_updated.emit(id)
	return true


## Pays out a fulfilled bounty once.
func claim(id: String) -> bool:
	if state(id) != "DONE":
		return false
	var data := Content.get_entry("bounties", id)
	GameState.bounties[id].state = "CLAIMED"
	Inventory.add_currency(int(data.get("reward_currency", 0)))
	for r in data.get("rewards", []):
		Inventory.add(r.id, int(r.get("count", 1)))
	EventBus.notify.emit("Belohnung erhalten: %d Lun" % int(data.get("reward_currency", 0)))
	bounty_updated.emit(id)
	return true
