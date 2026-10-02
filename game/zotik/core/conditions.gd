class_name Conditions
extends RefCounted
## Evaluates dialogue/NPC gates (data: {"type": ..., "id": ...}).


static func quest_state(id: String) -> String:
	return str(GameState.quests.get(id, {}).get("state", "INACTIVE"))


static func quest_step(id: String) -> int:
	return int(GameState.quests.get(id, {}).get("step", -1)) if quest_state(id) == "ACTIVE" else -1


static func check(g: Dictionary) -> bool:
	match g.get("type", ""):
		"quest_step": return quest_step(g.id) == int(g.step)
		"quest_state": return quest_state(g.id) == g.state
		"flag": return GameState.has_flag(g.id)
		"not_flag": return not GameState.has_flag(g.id)
		"has_item": return Inventory.count(g.id) >= int(g.get("count", 1))
	return false


static func all(list: Array) -> bool:
	for g in list:
		if not check(g):
			return false
	return true
