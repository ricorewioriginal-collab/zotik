extends Node
## Quest state (M06: start/query; progression added in M09).


func start(id: String) -> bool:
	if not Content.has_id("quests", id) or Conditions.quest_state(id) != "INACTIVE":
		return false
	GameState.quests[id] = {"state": "ACTIVE", "step": 0, "progress": 0}
	EventBus.quest_started.emit(id)
	EventBus.quest_updated.emit(id)
	return true
