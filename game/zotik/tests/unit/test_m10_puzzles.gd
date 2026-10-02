extends TestCase

const GATE := "PUZ_LUN_MOONGATE_001"
const BRIDGE := "PUZ_LUN_RESONANCE_BRIDGE_001"
const R := PuzzleLogic.Result


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves/"
	GameState.reset_new_game()
	Dialogue.reset()


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _solve_gate() -> void:
	for i in 2:
		PuzzleLogic.rotate(GATE, 0)
	for i in 3:
		PuzzleLogic.rotate(GATE, 2)


func test_moongate_wrong_reset_correct() -> void:
	var solved := []
	EventBus.puzzle_solved.connect(func(id): solved.append(id))
	eq(PuzzleLogic.submit(GATE), R.WRONG, "initial state is wrong")
	PuzzleLogic.rotate(GATE, 1)
	eq(PuzzleLogic.state(GATE).state, "IN_PROGRESS", "in progress")
	eq(PuzzleLogic.reset(GATE), R.OK, "manual reset")
	eq(Array(PuzzleLogic.state(GATE).current), [0, 0, 0], "back to initial")
	_solve_gate()
	eq(PuzzleLogic.submit(GATE), R.SOLVED, "correct")
	check(GameState.has_flag("FLAG_LUN_MOONGATE_OPEN"), "gate flag")
	eq(PuzzleLogic.submit(GATE), R.ALREADY_SOLVED, "idempotent")
	eq(PuzzleLogic.rotate(GATE, 0), R.ALREADY_SOLVED, "locked after solve")
	eq(PuzzleLogic.reset(GATE), R.ALREADY_SOLVED, "no reset after solve")
	eq(solved, [GATE], "solved event once")


func test_dial_wraps_around() -> void:
	for i in 4:
		PuzzleLogic.rotate(GATE, 0)
	eq(int(PuzzleLogic.state(GATE).current[0]), 0, "four steps wrap")


func test_bridge_sequence_wrong_clears() -> void:
	eq(PuzzleLogic.strike(BRIDGE, 2), R.OK, "first correct")
	eq(PuzzleLogic.strike(BRIDGE, 1), R.WRONG, "wrong node")
	eq(Array(PuzzleLogic.state(BRIDGE).current), [], "attempt cleared")
	for n in [2, 0, 3]:
		eq(PuzzleLogic.strike(BRIDGE, n), R.OK, "step %d" % n)
	eq(PuzzleLogic.strike(BRIDGE, 1), R.SOLVED, "solved")
	check(GameState.has_flag("FLAG_LUN_BRIDGE_ACTIVE"), "bridge flag")
	eq(PuzzleLogic.rotate(BRIDGE, 0), R.ALREADY_SOLVED, "solved first")


func test_invalid_inputs() -> void:
	eq(PuzzleLogic.rotate(GATE, 5), R.INVALID, "dial out of range")
	eq(PuzzleLogic.strike(GATE, 0), R.INVALID, "wrong kind")
	eq(PuzzleLogic.submit(BRIDGE), R.INVALID, "submit on sequence")


func test_hints_are_tiered_and_persist() -> void:
	var hints: Array = PuzzleLogic.data(GATE).hints
	eq(PuzzleLogic.next_hint(GATE), hints[0], "tier 1")
	eq(PuzzleLogic.next_hint(GATE), hints[1], "tier 2")
	PuzzleLogic.reset(GATE)
	eq(PuzzleLogic.next_hint(GATE), hints[2], "tier 3 after reset")
	eq(PuzzleLogic.next_hint(GATE), hints[2], "capped at last tier")


func test_partial_state_survives_save_load() -> void:
	PuzzleLogic.rotate(GATE, 0)
	PuzzleLogic.rotate(GATE, 2)
	PuzzleLogic.strike(BRIDGE, 2)
	PuzzleLogic.strike(BRIDGE, 0)
	SaveSystem.save_slot(1)
	GameState.reset_new_game()
	SaveSystem.load_slot(1)
	eq(Array(PuzzleLogic.state(GATE).current), [1, 0, 1], "dials restored")
	eq(Array(PuzzleLogic.state(BRIDGE).current), [2, 0], "sequence restored")
	PuzzleLogic.strike(BRIDGE, 3)
	eq(PuzzleLogic.strike(BRIDGE, 1), R.SOLVED, "finish after reload")


func test_in_world_moongate_opens_ruins_exit() -> void:
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	var game: GameRoot = tree.current_scene
	await finish_dialogues()
	game.enter_area("AREA_LUN_RUINS", "default")
	await physics_frames(2)
	var node: PuzzleNode = game.area.entities[GATE]
	check(not game.area.is_exit_open("AREA_LUN_RIFT_CAVE"), "cave locked")
	game.player.global_position = node.global_position + Vector3(0, 0, 4)
	await physics_frames(2)
	for i in 2:
		node.parts[0].interact(game.player)
	node.parts[2].interact(game.player)
	var ev := InputEventAction.new()
	ev.action = "puzzle_reset"
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(2)
	eq(Array(PuzzleLogic.state(GATE).current), [0, 0, 0], "reset key in range")
	for i in 2:
		node.parts[0].interact(game.player)
	for i in 3:
		node.parts[2].interact(game.player)
	node.parts[3].interact(game.player)
	check(PuzzleLogic.is_solved(GATE), "solved in world")
	check(game.area.is_exit_open("AREA_LUN_RIFT_CAVE"), "cave open")
	check(not node.parts[0].can_interact(), "parts disabled after solve")
