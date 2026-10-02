extends Node
## Persistent world state of one game session. Everything that must survive
## save -> quit -> restart -> load lives here and nowhere else.
## Serialized with plain JSON types; from_dict() restores exact types.

const START_AREA := "AREA_LUN_HOME"
const START_CURRENCY := 50
const START_HP := 100

var flags := {}            # FLAG_* -> bool
var inventory := {}        # ITEM_*/WEAPON_* -> int
var equipment := {}        # slot -> item id
var currency := 0
var quests := {}           # QUEST_* -> {state: String, step: int}
var chests_opened := {}    # CHEST_* -> true
var puzzles := {}          # PUZ_* -> {state: String, current: Array[int]}
var unique_rewards := {}   # id -> true (idempotent grants)
var defeated := {}         # spawn/boss ids -> true
var npc_states := {}       # NPC_* -> String
var customization := {}    # option -> String
var player := {}           # area, position, hp, max_hp
var party: Array[String] = []  # PARTY_* member ids in join order
var bestiary := {}         # ENEMY_*/BOSS_* -> times defeated
var bounties := {}         # BOUNTY_* -> {state, progress}
var arena := {}            # ARENA_* -> times won
var casino := {"spins": 0, "best_win": 0}
var play_time := 0.0


func _ready() -> void:
	reset_new_game()


func reset_new_game() -> void:
	flags = {}
	inventory = {}
	equipment = {}
	currency = START_CURRENCY
	quests = {}
	chests_opened = {}
	puzzles = {}
	unique_rewards = {}
	defeated = {}
	npc_states = {}
	customization = {}
	player = {"area": START_AREA, "position": [0.0, 0.0, 0.0], "hp": START_HP, "max_hp": START_HP}
	party = []
	bestiary = {}
	bounties = {}
	arena = {}
	casino = {"spins": 0, "best_win": 0}
	play_time = 0.0


func set_flag(id: String, value: bool = true) -> void:
	if flags.get(id, false) == value:
		return
	flags[id] = value
	EventBus.flag_changed.emit(id, value)


func has_flag(id: String) -> bool:
	return flags.get(id, false)


func to_dict() -> Dictionary:
	return {
		"flags": flags.duplicate(true),
		"inventory": inventory.duplicate(true),
		"equipment": equipment.duplicate(true),
		"currency": currency,
		"quests": quests.duplicate(true),
		"chests_opened": chests_opened.keys(),
		"puzzles": puzzles.duplicate(true),
		"unique_rewards": unique_rewards.keys(),
		"defeated": defeated.keys(),
		"npc_states": npc_states.duplicate(true),
		"customization": customization.duplicate(true),
		"player": player.duplicate(true),
		"party": party.duplicate(),
		"bestiary": bestiary.duplicate(),
		"bounties": bounties.duplicate(true),
		"arena": arena.duplicate(),
		"casino": casino.duplicate(),
		"play_time": play_time,
	}


## Restores state from a (JSON-decoded) dictionary. Unknown keys are ignored,
## missing keys fall back to new-game defaults. Returns false on type errors.
func from_dict(d: Dictionary) -> bool:
	reset_new_game()
	for k in _dict(d, "flags"):
		flags[str(k)] = bool(d.flags[k])
	for k in _dict(d, "inventory"):
		inventory[str(k)] = int(d.inventory[k])
	for k in _dict(d, "equipment"):
		equipment[str(k)] = str(d.equipment[k])
	currency = int(d.get("currency", START_CURRENCY))
	for k in _dict(d, "quests"):
		var q = d.quests[k]
		if not q is Dictionary:
			return false
		quests[str(k)] = {"state": str(q.get("state", "INACTIVE")), "step": int(q.get("step", 0)), "progress": int(q.get("progress", 0))}
	for k in _dict(d, "puzzles"):
		var p = d.puzzles[k]
		if not p is Dictionary:
			return false
		var cur: Array[int] = []
		for v in p.get("current", []):
			cur.append(int(v))
		puzzles[str(k)] = {"state": str(p.get("state", "INITIAL")), "current": cur, "hints": int(p.get("hints", 0))}
	for id in _arr(d, "chests_opened"):
		chests_opened[str(id)] = true
	for id in _arr(d, "unique_rewards"):
		unique_rewards[str(id)] = true
	for id in _arr(d, "defeated"):
		defeated[str(id)] = true
	for k in _dict(d, "npc_states"):
		npc_states[str(k)] = str(d.npc_states[k])
	for k in _dict(d, "customization"):
		customization[str(k)] = str(d.customization[k])
	var pl = d.get("player", {})
	if pl is Dictionary:
		var pos = pl.get("position", [0, 0, 0])
		if not pos is Array or pos.size() != 3:
			return false
		player = {
			"area": str(pl.get("area", START_AREA)),
			"position": [float(pos[0]), float(pos[1]), float(pos[2])],
			"hp": int(pl.get("hp", START_HP)),
			"max_hp": int(pl.get("max_hp", START_HP)),
		}
	for m in _arr(d, "party"):
		if not str(m) in party:
			party.append(str(m))
	for k in _dict(d, "bestiary"):
		bestiary[str(k)] = int(d.bestiary[k])
	for k in _dict(d, "bounties"):
		var b = d.bounties[k]
		if b is Dictionary:
			bounties[str(k)] = {"state": str(b.get("state", "ACTIVE")), "progress": int(b.get("progress", 0))}
	for k in _dict(d, "arena"):
		arena[str(k)] = int(d.arena[k])
	var cz = d.get("casino", {})
	if cz is Dictionary:
		casino = {"spins": int(cz.get("spins", 0)), "best_win": int(cz.get("best_win", 0))}
	play_time = float(d.get("play_time", 0.0))
	return true


func _dict(d: Dictionary, key: String) -> Array:
	var v = d.get(key, {})
	return v.keys() if v is Dictionary else []


func _arr(d: Dictionary, key: String) -> Array:
	var v = d.get(key, [])
	return v if v is Array else []
