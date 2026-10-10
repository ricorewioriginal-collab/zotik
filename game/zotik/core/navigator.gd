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


## Where to walk from `from` towards `to`: {"exit": area} for an exit in the
## current area, {"travel": true} to use this area's Weltenstein, or {}.
static func route(from: String, to: String) -> Dictionary:
	if from == to:
		return {}
	var hop := next_hop(from, to)
	if hop != "":
		return {"exit": hop}
	var here_world := Content.world_of(from)
	if Content.world_of(to) == here_world:
		return {}
	var hub: String = Content.get_entry("worlds", here_world).get("hub_area", "")
	if from == hub:
		return {"travel": true}
	hop = next_hop(from, hub)
	return {"exit": hop} if hop != "" else {}


## The quest whose objective is guided: main quest first, then others.
static func guided_quest() -> String:
	var active := Quests.active_quests()
	return active[0] if not active.is_empty() else ""


## The next world the story points to when no quest is active: the first unlocked world (chapter order)
## whose arrival flag (FLAG_<hub prefix>_ARRIVED) is not set yet. Chapter 1 has no unlock flag and is skipped.
static func next_world() -> String:
	var best := ""
	var best_chapter := 1000
	for id in Content.table("worlds"):
		var wd := Content.get_entry("worlds", id)
		if str(wd.get("requires_flag", "")) == "" or not Content.world_unlocked(id):
			continue
		var prefix := str(wd.hub_area).split("_")[1]
		if GameState.has_flag("FLAG_%s_ARRIVED" % prefix):
			continue
		if int(wd.chapter) < best_chapter:
			best_chapter = int(wd.chapter)
			best = id
	return best


## Guide target while nothing is active: the hub of the next world (the route leads to the Weltenstein).
static func world_target() -> Dictionary:
	if guided_quest() != "":
		return {}
	var w := next_world()
	if w == "":
		return {}
	return {"area": Content.get_entry("worlds", w).hub_area, "entity": ""}


## Objective line for the same case.
static func world_objective() -> String:
	for q in Quests.active_quests():
		if Content.get_entry("quests", q).get("type") == "main":
			return ""
	var w := next_world()
	if w == "":
		return ""
	var wd := Content.get_entry("worlds", w)
	return "Reise mit dem Weltenstein nach %s – %s." % [wd.name, wd.subtitle]
