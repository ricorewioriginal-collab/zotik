extends Node
## Content registry: loads res://data/*.json and validates IDs and every
## cross-reference (docs/03_CONTENT_DATA_SPEC.md). Gameplay reads content
## only through this registry.

const DATA_DIR := "res://data/"
const TABLES := {
	"flags": ["FLAG_"], "areas": ["AREA_"], "items": ["ITEM_", "WEAPON_"],
	"cosmetics": ["COS_"], "enemies": ["ENEMY_", "BOSS_"], "chests": ["CHEST_"],
	"shops": ["SHOP_"], "puzzles": ["PUZ_"], "quests": ["QUEST_"], "npcs": ["NPC_"],
	"dialogues": ["DLG_"], "cutscenes": ["CUT_"],
}
const CANONICAL_IDS := ["QUEST_MAIN_LUN_001", "QUEST_SIDE_LUN_001", "PUZ_LUN_MOONGATE_001", "PUZ_LUN_RESONANCE_BRIDGE_001", "ENEMY_RIFTLING_001", "ENEMY_MOONWOLF_001", "BOSS_ORUN_001", "WEAPON_WORLD_BLADE_001", "CHEST_LUN_001", "CHEST_LUN_002", "SAVEPOINT_LUN_RIFT_001", "FLAG_LUN_FOREST_UNLOCKED", "FLAG_BOSS_LUN_ORUN_DEFEATED", "CHAR_ZOTIK_MASTER_001", "CHAR_MIRA_MASTER_001", "CHAR_LYRA_MASTER_001", "CHAR_PROFESSORIUM_MASTER_001"]
const EFFECT_TYPES := ["set_flag", "give_item", "take_item", "give_currency", "start_quest", "equip", "open_shop", "play_cutscene", "travel"]
const ENTITY_TYPES := ["npc", "enemy", "chest", "puzzle", "savepoint", "unique", "trigger"]
const CONDITION_TYPES := ["talk", "defeat", "area", "puzzle", "savepoint", "item"]
const GATE_TYPES := ["quest_step", "quest_state", "flag", "not_flag", "has_item"]

var tables := {}
var world := {}
var layouts := {}
var load_errors: Array[String] = []


func _ready() -> void:
	load_all()


func load_all() -> void:
	load_errors.clear()
	tables.clear()
	for t in TABLES:
		tables[t] = _read(DATA_DIR + t + ".json")
	world = _read(DATA_DIR + "world.json")
	layouts = _read(DATA_DIR + "layouts.json")


func _read(path: String) -> Dictionary:
	var v = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not v is Dictionary:
		load_errors.append("cannot load " + path)
		return {}
	return v


func table(t: String) -> Dictionary:
	return tables.get(t, {})


func get_entry(t: String, id: String) -> Dictionary:
	return tables.get(t, {}).get(id, {})


func item(id: String) -> Dictionary:
	return get_entry("items", id)


func enemy(id: String) -> Dictionary:
	return get_entry("enemies", id)


func has_id(t: String, id: String) -> bool:
	return tables.get(t, {}).has(id)


func savepoint(id: String) -> Dictionary:
	return world.get("savepoints", {}).get(id, {})


func player_stats() -> Dictionary:
	return world.get("player", {})


func speaker_name(id: String) -> String:
	for t in ["npcs", "enemies"]:
		if has_id(t, id):
			return str(get_entry(t, id).name)
	return str(world.get("characters", {}).get(id, {}).get("name", id))


## Returns all validation errors; empty array means the content is consistent.
func validate() -> Array[String]:
	var e: Array[String] = load_errors.duplicate()
	var seen := {}
	for t in TABLES:
		for id in table(t):
			if not TABLES[t].any(func(p): return id.begins_with(p)):
				e.append("%s: id %s outside namespaces %s" % [t, id, TABLES[t]])
			if seen.has(id):
				e.append("duplicate id %s in %s and %s" % [id, seen[id], t])
			seen[id] = t
	for id in world.get("savepoints", {}):
		if not id.begins_with("SAVEPOINT_"):
			e.append("savepoint id %s" % id)
		_ref(e, "areas", world.savepoints[id].get("area", ""), id)
	for id in table("areas"):
		var a: Dictionary = table("areas")[id]
		for x in a.get("exits", []):
			_ref(e, "areas", x, id)
		for x in a.get("gate", {}):
			_ref(e, "areas", x, id)
			_ref(e, "flags", a.gate[x], id)
	for id in table("items"):
		var it: Dictionary = table("items")[id]
		if it.get("type") in ["weapon", "accessory"] and not it.has("slot"):
			e.append("%s: equipment without slot" % id)
	var defaults := {}
	for id in table("cosmetics"):
		var c: Dictionary = table("cosmetics")[id]
		defaults[c.option] = defaults.get(c.option, 0) + (1 if c.get("default", false) else 0)
	for opt in defaults:
		if defaults[opt] != 1:
			e.append("cosmetic option %s needs exactly one default" % opt)
	for id in table("enemies"):
		var en: Dictionary = table("enemies")[id]
		for d in en.get("drops", []):
			_ref(e, "items", d.id, id)
		_effects(e, en.get("on_defeat", []), id)
		for ph in en.get("phases", []):
			if ph.has("summon"):
				_ref(e, "enemies", ph.summon, id)
	for id in table("chests"):
		_ref(e, "areas", table("chests")[id].area, id)
		for c in table("chests")[id].contents:
			_ref(e, "items", c.id, id)
	for id in table("shops"):
		_ref(e, "npcs", table("shops")[id].npc, id)
		for s in table("shops")[id].stock:
			_ref(e, "items", s, id)
			if not item(s).has("price"):
				e.append("%s: %s has no price" % [id, s])
	for id in table("puzzles"):
		var p: Dictionary = table("puzzles")[id]
		_ref(e, "areas", p.area, id)
		_effects(e, p.get("on_solved", []), id)
		if p.kind == "dials":
			if p.solution.size() != p.dial_count or p.initial.size() != p.dial_count or p.solution.any(func(v): return v < 0 or v >= p.dial_states):
				e.append("%s: invalid dial setup" % id)
			if p.solution == p.initial:
				e.append("%s: solution equals initial state" % id)
		elif p.kind == "sequence":
			if p.solution.any(func(v): return v < 0 or v >= p.nodes):
				e.append("%s: invalid sequence" % id)
		else:
			e.append("%s: unknown puzzle kind" % id)
		if p.get("hints", []).is_empty():
			e.append("%s: no hints" % id)
	for id in table("quests"):
		var q: Dictionary = table("quests")[id]
		for s in q.steps:
			_condition(e, s.condition, id)
			_effects(e, s.get("on_complete", []), id)
		_effects(e, q.get("rewards", []), id)
	for id in table("npcs"):
		var n: Dictionary = table("npcs")[id]
		_ref(e, "areas", n.area, id)
		if n.has("appears_when"):
			_ref(e, "flags", n.appears_when, id)
		if n.get("dialogues", []).is_empty() or not n.dialogues[-1].when.is_empty():
			e.append("%s: last dialogue entry must be an unconditional fallback" % id)
		for d in n.get("dialogues", []):
			_ref(e, "dialogues", d.dialogue, id)
			for g in d.when:
				_gate(e, g, id)
	for t in ["dialogues", "cutscenes"]:
		for id in table(t):
			var dl: Dictionary = table(t)[id]
			if dl.get("lines", []).is_empty():
				e.append("%s: no lines" % id)
			for line in dl.get("lines", []):
				if not (line is Array and line.size() == 2):
					e.append("%s: malformed line" % id)
				elif not (has_id("npcs", line[0]) or has_id("enemies", line[0]) or world.get("characters", {}).has(line[0])):
					e.append("%s: unknown speaker %s" % [id, line[0]])
			_effects(e, dl.get("effects", []), id)
	for id in world.get("uniques", {}):
		var u: Dictionary = world.uniques[id]
		_ref(e, "items", id, "uniques")
		if not item(id).get("unique", false):
			e.append("%s listed as unique but item is not unique" % id)
		_ref(e, "areas", u.area, id)
		_ref(e, "flags", u.requires_flag, id)
		_ref(e, "flags", u.sets_flag, id)
		_ref(e, "cutscenes", u.cutscene, id)
		_effects(e, u.get("after", []), id)
	_validate_layouts(e)
	var used_dialogues := {}
	for id in table("npcs"):
		for d in table("npcs")[id].get("dialogues", []):
			used_dialogues[d.dialogue] = true
	for id in table("dialogues"):
		if not used_dialogues.has(id):
			e.append("%s is never used by an NPC" % id)
	var chars := {}
	for id in table("npcs"):
		chars[table("npcs")[id].get("character", "")] = true
	for id in world.get("characters", {}):
		chars[world.characters[id].get("master", "")] = true
	for id in CANONICAL_IDS:
		if not (seen.has(id) or world.get("savepoints", {}).has(id) or chars.has(id)):
			e.append("canonical id missing: " + id)
	return e


func _ref(e: Array[String], t: String, id: String, owner: String) -> void:
	if not has_id(t, id):
		e.append("%s: unknown %s reference %s" % [owner, t, id])


func _effects(e: Array[String], list: Array, owner: String) -> void:
	for fx in list:
		var ty: String = fx.get("type", "")
		if not ty in EFFECT_TYPES:
			e.append("%s: unknown effect %s" % [owner, ty])
			continue
		match ty:
			"set_flag": _ref(e, "flags", fx.id, owner)
			"give_item", "take_item", "equip": _ref(e, "items", fx.id, owner)
			"start_quest": _ref(e, "quests", fx.id, owner)
			"open_shop": _ref(e, "shops", fx.id, owner)
			"play_cutscene": _ref(e, "cutscenes", fx.id, owner)
			"travel":
				_ref(e, "areas", fx.area, owner)
				if not layouts.get(fx.area, {}).get("spawns", {}).has(fx.get("spawn", "")):
					e.append("%s: travel to unknown spawn %s" % [owner, fx.get("spawn", "")])
			"give_currency":
				if int(fx.get("amount", 0)) <= 0:
					e.append("%s: give_currency without positive amount" % owner)


func _condition(e: Array[String], c: Dictionary, owner: String) -> void:
	match c.get("type", ""):
		"talk": _ref(e, "npcs", c.npc, owner)
		"defeat": _ref(e, "enemies", c.enemy, owner)
		"area": _ref(e, "areas", c.area, owner)
		"puzzle": _ref(e, "puzzles", c.puzzle, owner)
		"item": _ref(e, "items", c.item, owner)
		"savepoint":
			if not world.get("savepoints", {}).has(c.savepoint):
				e.append("%s: unknown savepoint %s" % [owner, c.savepoint])
		_: e.append("%s: unknown condition %s" % [owner, c.get("type", "")])


func _gate(e: Array[String], g: Dictionary, owner: String) -> void:
	match g.get("type", ""):
		"quest_step", "quest_state": _ref(e, "quests", g.id, owner)
		"flag", "not_flag": _ref(e, "flags", g.id, owner)
		"has_item": _ref(e, "items", g.id, owner)
		_: e.append("%s: unknown gate %s" % [owner, g.get("type", "")])


func layout(area: String) -> Dictionary:
	return layouts.get(area, {})


func _validate_layouts(e: Array[String]) -> void:
	var placed := {}
	var spawns_seen := {}
	for area in table("areas"):
		if not layouts.has(area):
			e.append("area %s has no layout" % area)
	for area in layouts:
		_ref(e, "areas", area, "layouts")
		var l: Dictionary = layouts[area]
		if not l.get("spawns", {}).has("default"):
			e.append("%s: layout without default spawn" % area)
		var declared: Array = get_entry("areas", area).get("exits", [])
		var exits := []
		for x in l.get("exits", []):
			exits.append(x.to)
			if not x.to in declared:
				e.append("%s: exit to %s not declared in areas.json" % [area, x.to])
			if not layouts.get(x.to, {}).get("spawns", {}).has(area):
				e.append("%s: target %s has no spawn for arrivals from %s" % [area, x.to, area])
		for x in declared:
			if not x in exits:
				e.append("%s: declared exit %s has no layout exit" % [area, x])
		for p in l.get("props", []):
			for k in ["requires_flag", "hidden_by_flag"]:
				if p.has(k):
					_ref(e, "flags", p[k], area)
		for en in l.get("entities", []):
			var ty: String = en.get("type", "")
			if not ty in ENTITY_TYPES:
				e.append("%s: unknown entity type %s" % [area, ty])
				continue
			var key: String = en.get("spawn", en.get("id", ""))
			if placed.has(key):
				e.append("%s placed twice" % key)
			placed[key] = area
			match ty:
				"npc":
					_ref(e, "npcs", en.id, area)
					if get_entry("npcs", en.id).get("area") != area:
						e.append("%s placed outside its area" % en.id)
				"enemy":
					_ref(e, "enemies", en.enemy, area)
					if not key.begins_with("SPAWN_"):
						e.append("%s: enemy spawn id must start with SPAWN_" % area)
				"chest", "puzzle":
					var t := "chests" if ty == "chest" else "puzzles"
					_ref(e, t, en.id, area)
					if get_entry(t, en.id).get("area") != area:
						e.append("%s placed outside its area" % en.id)
				"savepoint":
					if savepoint(en.id).get("area") != area:
						e.append("%s placed outside its area" % en.id)
				"unique":
					if world.get("uniques", {}).get(en.id, {}).get("area") != area:
						e.append("%s placed outside its area" % en.id)
				"trigger":
					_ref(e, "cutscenes", en.cutscene, area)
					_ref(e, "flags", en.once_flag, area)
	for t in ["npcs", "chests", "puzzles"]:
		for id in table(t):
			if not placed.has(id):
				e.append("%s is never placed in a layout" % id)
	for id in world.get("savepoints", {}).keys() + world.get("uniques", {}).keys():
		if not placed.has(id):
			e.append("%s is never placed in a layout" % id)
