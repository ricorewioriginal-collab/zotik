class_name PuzzleLogic
extends RefCounted
## Data-driven puzzle rules (data/puzzles.json). State in GameState.puzzles:
## {state: INITIAL|IN_PROGRESS|SOLVED, current: Array[int], hints: int}.
## Kinds: "dials" (rotate dials, then submit) and "sequence" (strike nodes in
## order; a wrong node clears the attempt).

enum Result { OK, WRONG, SOLVED, ALREADY_SOLVED, INVALID }


static func data(id: String) -> Dictionary:
	return Content.get_entry("puzzles", id)


static func state(id: String) -> Dictionary:
	if not GameState.puzzles.has(id):
		var init: Array[int] = []
		for v in data(id).initial:
			init.append(int(v))
		GameState.puzzles[id] = {"state": "INITIAL", "current": init, "hints": 0}
	return GameState.puzzles[id]


static func is_solved(id: String) -> bool:
	return state(id).state == "SOLVED"


static func rotate(id: String, dial: int) -> Result:
	var d := data(id)
	if is_solved(id):
		return Result.ALREADY_SOLVED
	if d.kind != "dials" or dial < 0 or dial >= int(d.dial_count):
		return Result.INVALID
	var s := state(id)
	s.current[dial] = (int(s.current[dial]) + 1) % int(d.dial_states)
	s.state = "IN_PROGRESS"
	return Result.OK


static func submit(id: String) -> Result:
	var d := data(id)
	if is_solved(id):
		return Result.ALREADY_SOLVED
	if d.kind != "dials":
		return Result.INVALID
	if _matches(state(id).current, d.solution):
		return _solve(id)
	EventBus.notify.emit("Das Tor bleibt verschlossen.")
	return Result.WRONG


static func strike(id: String, node: int) -> Result:
	var d := data(id)
	if is_solved(id):
		return Result.ALREADY_SOLVED
	if d.kind != "sequence" or node < 0 or node >= int(d.nodes):
		return Result.INVALID
	var s := state(id)
	var cur: Array = s.current
	if int(d.solution[cur.size()]) != node:
		s.current = [] as Array[int]
		s.state = "INITIAL"
		EventBus.notify.emit("Die Resonanz bricht ab.")
		return Result.WRONG
	cur.append(node)
	s.state = "IN_PROGRESS"
	if cur.size() == d.solution.size():
		return _solve(id)
	return Result.OK


## Manual reset to the initial configuration (not possible once solved).
static func reset(id: String) -> Result:
	if is_solved(id):
		return Result.ALREADY_SOLVED
	var hints := int(state(id).hints)
	GameState.puzzles.erase(id)
	state(id).hints = hints  # hint tiers already seen stay unlocked
	return Result.OK


## Returns the next hint (tiers stop at the last one).
static func next_hint(id: String) -> String:
	var hints: Array = data(id).get("hints", [])
	if hints.is_empty():
		return ""
	var s := state(id)
	var i := mini(int(s.hints), hints.size() - 1)
	s.hints = mini(int(s.hints) + 1, hints.size())
	return hints[i]


static func _solve(id: String) -> Result:
	var s := state(id)
	s.state = "SOLVED"
	s.current = (data(id).solution as Array).map(func(v): return int(v))
	Effects.run(data(id).get("on_solved", []))
	EventBus.puzzle_solved.emit(id)
	EventBus.notify.emit("%s gelöst!" % data(id).name)
	return Result.SOLVED


static func _matches(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if int(a[i]) != int(b[i]):
			return false
	return true
