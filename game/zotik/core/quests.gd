extends Node
## Event-driven quest progression (docs/03): steps advance only from gameplay
## events or verifiable state, never from UI. State lives in GameState.quests
## as {state, step, progress}.

const MAIN := "QUEST_MAIN_LUN_001"

var _busy := false
var _pending: Array = []


func _ready() -> void:
	EventBus.npc_talked.connect(func(npc, _d): _event({"type": "talk", "npc": npc}))
	EventBus.enemy_defeated.connect(func(id): _event({"type": "defeat", "enemy": id}))
	EventBus.area_entered.connect(func(id): _event({"type": "area", "area": id}))
	EventBus.puzzle_solved.connect(func(id): _event({"type": "puzzle", "puzzle": id}))
	EventBus.savepoint_used.connect(func(id): _event({"type": "savepoint", "savepoint": id}))
	EventBus.item_added.connect(func(_id, _n): _event({"type": "item"}))


func start(id: String) -> bool:
	if not Content.has_id("quests", id) or Conditions.quest_state(id) != "INACTIVE":
		return false
	GameState.quests[id] = {"state": "ACTIVE", "step": 0, "progress": 0}
	EventBus.quest_started.emit(id)
	EventBus.quest_updated.emit(id)
	_event({"type": "state"})
	return true


func current_step(id: String) -> Dictionary:
	var q := Content.get_entry("quests", id)
	var i := Conditions.quest_step(id)
	return q.steps[i] if i >= 0 and i < q.steps.size() else {}


func objective(id: String) -> String:
	var s := current_step(id)
	if s.is_empty():
		return ""
	var text: String = s.objective
	var c: Dictionary = s.condition
	if c.type == "defeat" and int(c.get("count", 1)) > 1:
		text += " (%d/%d)" % [int(GameState.quests[id].progress), int(c.count)]
	return text


func active_quests() -> Array:
	var out := []
	for id in Content.table("quests"):
		if Conditions.quest_state(id) == "ACTIVE":
			out.append(id)
	# Main quests first (Lunaris before later chapters), then side quests.
	out.sort_custom(func(a, b):
		var ma: bool = Content.get_entry("quests", a).get("type") == "main"
		var mb: bool = Content.get_entry("quests", b).get("type") == "main"
		if ma != mb:
			return ma
		if a == MAIN or b == MAIN:
			return a == MAIN
		return a < b)
	return out


## Events are processed one after another; effects that raise new events
## (e.g. give_item -> item_added) are queued instead of recursing.
func _event(ev: Dictionary) -> void:
	_pending.append(ev)
	if _busy:
		return
	_busy = true
	while not _pending.is_empty():
		var e: Dictionary = _pending.pop_front()
		for id in active_quests():
			_apply(id, e)
	_busy = false


func _apply(id: String, ev: Dictionary) -> void:
	var guard := 0
	while Conditions.quest_state(id) == "ACTIVE" and guard < 32:
		guard += 1
		var c: Dictionary = current_step(id).condition
		if not _satisfied(id, c, ev):
			return
		_complete_step(id)
		ev = {"type": "state"}


func _satisfied(id: String, c: Dictionary, ev: Dictionary) -> bool:
	match c.type:
		"item":
			return Inventory.count(c.item) >= int(c.get("count", 1))
		"area":
			return GameState.player.get("area", "") == c.area
		"talk":
			return ev.type == "talk" and ev.npc == c.npc
		"puzzle":
			return ev.type == "puzzle" and ev.puzzle == c.puzzle
		"savepoint":
			return ev.type == "savepoint" and ev.savepoint == c.savepoint
		"defeat":
			if ev.type != "defeat" or ev.enemy != c.enemy:
				return false
			GameState.quests[id].progress = int(GameState.quests[id].progress) + 1
			EventBus.quest_updated.emit(id)
			return int(GameState.quests[id].progress) >= int(c.get("count", 1))
	return false


func _complete_step(id: String) -> void:
	var q := Content.get_entry("quests", id)
	var step: Dictionary = current_step(id)
	var entry: Dictionary = GameState.quests[id]
	entry.step = int(entry.step) + 1
	entry.progress = 0
	Effects.run(step.get("on_complete", []))
	if int(entry.step) >= q.steps.size():
		entry.state = "COMPLETED"
		Effects.run(q.get("rewards", []))
		EventBus.quest_updated.emit(id)
		EventBus.quest_completed.emit(id)
		EventBus.notify.emit("Quest abgeschlossen: " + str(q.name))
	else:
		EventBus.quest_updated.emit(id)
		EventBus.notify.emit("Neues Ziel: " + objective(id))
