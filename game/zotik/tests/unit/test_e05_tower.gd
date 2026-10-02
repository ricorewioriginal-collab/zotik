extends TestCase

const TURM := "PUZ_ELA_TURM_001"
const R := PuzzleLogic.Result
var game: GameRoot


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()
	for f in ["FLAG_LUN_CHAPTER_COMPLETE", "FLAG_ELA_ARRIVED", "FLAG_ELA_FOREST_OPEN"]:
		GameState.set_flag(f)


func _labels() -> Array:
	return PuzzleLogic.data(TURM).node_labels


func _press(node: PuzzleNode, symbol: String) -> void:
	node.parts[_labels().find(symbol)].interact(game.player)


func test_spec_order_mond_blatt_kristall_flamme() -> void:
	var order := []
	for i in PuzzleLogic.data(TURM).solution:
		order.append(_labels()[int(i)])
	eq(order, ["Mond", "Blatt", "Kristall", "Flamme"], "solution matches ELARIS_TURM_01")
	eq(PuzzleLogic.data(TURM).spec_id, "ELARIS_TURM_01", "spec id")


func test_wrong_symbol_resets_then_solve_rewards_and_epilog() -> void:
	game.enter_area("AREA_ELA_TOWER", "default")
	await physics_frames(2)
	var node: PuzzleNode = game.area.entities[TURM]
	check(not game.area.is_exit_open("AREA_ELA_DUNGEON"), "inner forest locked")
	_press(node, "Mond")
	_press(node, "Kristall")
	eq(Array(PuzzleLogic.state(TURM).current), [], "wrong symbol resets (RESET_FAILURE)")
	var lun := GameState.currency
	for s in ["Mond", "Blatt", "Kristall", "Flamme"]:
		_press(node, s)
	check(PuzzleLogic.is_solved(TURM), "solved")
	check(game.area.is_exit_open("AREA_ELA_DUNGEON"), "key to the inner area")
	eq(GameState.currency, lun + 80, "Lun reward")
	eq(Inventory.count("ITEM_MEMORY_CRYSTAL_001"), 2, "rare materials")
	eq(Dialogue.active_id, "CUT_ELA_TURM_EPILOG_001", "spec epilogue plays")
	var lines: Array = Content.get_entry("cutscenes", "CUT_ELA_TURM_EPILOG_001").lines
	eq(lines[0], ["CHAR_ZOTIK", "Geschafft."], "epilogue text from the spec")
	await finish_dialogues()
	check(not node.parts[0].can_interact(), "pillars locked after solve")


func test_hints_and_manual_reset() -> void:
	PuzzleLogic.strike(TURM, 1)
	eq(PuzzleLogic.reset(TURM), R.OK, "manual reset")
	eq(Array(PuzzleLogic.state(TURM).current), [], "cleared")
	var hints: Array = PuzzleLogic.data(TURM).hints
	eq(hints.size(), 3, "hint levels 1-3")
	eq(PuzzleLogic.next_hint(TURM), hints[0], "level 1")
	eq(PuzzleLogic.next_hint(TURM), hints[1], "level 2")
	eq(PuzzleLogic.next_hint(TURM), "Mond, dann Blatt, dann Kristall, dann Flamme.", "level 3 = solution")


func test_pillars_show_symbols() -> void:
	game.enter_area("AREA_ELA_TOWER", "default")
	await physics_frames(2)
	var node: PuzzleNode = game.area.entities[TURM]
	check(node.parts[1].prompt.contains("Mond"), "pillar prompt names its symbol")
	var labels := node.parts[1].find_children("*", "Label3D", false, false)
	eq(labels.size(), 1, "symbol label above pillar")
