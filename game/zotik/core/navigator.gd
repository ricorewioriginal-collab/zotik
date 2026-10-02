class_name Navigator
extends RefCounted
## Finds where the player should go next for a quest step: the target area,
## the entity key inside it and, from another area, the next exit on the
## shortest path (BFS over data/areas.json exits).


## Returns {"area": String, "entity": String} for the current step, or {}.
static func step_target(quest_id: String) -> Dictionary:
	var step := Quests.current_step(quest_id)
	if step.is_empty():
		return {}
	var c: Dictionary = step.condition
	match c.type:
		"talk":
			return {"area": Content.get_entry("npcs", c.npc).area, "entity": c.npc}
		"puzzle":
			return {"area": Content.get_entry("puzzles", c.puzzle).area, "entity": c.puzzle}
		"savepoint":
			return {"area": Content.savepoint(c.savepoint).area, "entity": c.savepoint}
		"area":
			return {"area": c.area, "entity": ""}
		"defeat":
			for area in Content.layouts:
				for en in Content.layout(area).get("entities", []):
					if en.type == "enemy" and en.enemy == c.enemy and not GameState.defeated.has(en.spawn):
						return {"area": area, "entity": "enemy:" + c.enemy}
		"item":
			if Content.world.get("uniques", {}).has(c.item):
				return {"area": Content.world.uniques[c.item].area, "entity": c.item}
			for id in Content.table("chests"):
				if GameState.chests_opened.has(id):
					continue
				for it in Content.get_entry("chests", id).contents:
					if it.id == c.item:
						return {"area": Content.get_entry("chests", id).area, "entity": id}
	return {}


## Next area to walk into on the way from `from` to `to` ("" if none/same).
static func next_hop(from: String, to: String) -> String:
	if from == to:
		return ""
	var prev := {from: ""}
	var queue := [from]
	while not queue.is_empty():
		var a: String = queue.pop_front()
		for x in Content.get_entry("areas", a).get("exits", []):
			if prev.has(x):
				continue
			prev[x] = a
			if x == to:
				var hop: String = x
				while prev[hop] != from:
					hop = prev[hop]
				return hop
			queue.append(x)
	return ""


## The quest whose objective is guided: main quest first, then others.
static func guided_quest() -> String:
	var active := Quests.active_quests()
	return active[0] if not active.is_empty() else ""
