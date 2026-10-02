extends TestCase

const VALVES := "PUZ_VAL_VALVES_001"
var game: GameRoot


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves/"
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()
	GameState.set_flag("FLAG_VAL_ARRIVED")


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func test_tibor_opens_canal_gate() -> void:
	game.enter_area("AREA_VAL_CANAL_GATE", "default")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_VAL_CANALS"), "gate closed at first")
	eq(Dialogue.select_for_npc("NPC_TIBOR_001"), "DLG_TIBOR_CLOSED_001", "needs Veyr's word (V05)")
	Quests.start("QUEST_MAIN_VAL_001")
	Dialogue.talk_to("NPC_VEYR_001")
	await finish_dialogues()
	Dialogue.talk_to("NPC_TIBOR_001")
	eq(Dialogue.active_id, "DLG_TIBOR_OPEN_001", "opening dialogue")
	await finish_dialogues()
	check(game.area.is_exit_open("AREA_VAL_CANALS"), "gate open")
	check(not game.area.find_children("PLACEHOLDER_canal_gate", "", true, false)[0].visible, "gate prop gone")
	eq(Dialogue.select_for_npc("NPC_TIBOR_001"), "DLG_TIBOR_IDLE_001", "idle afterwards")
	eq(Navigator.next_hop("AREA_VAL_MARKET", "AREA_VAL_CISTERN"), "AREA_VAL_CANAL_GATE", "route to the cistern")


func test_valves_logic() -> void:
	eq(PuzzleLogic.state(VALVES).current, [1, 1, 1], "all flooded")
	eq(PuzzleLogic.turn_valve(VALVES, 0), PuzzleLogic.Result.OK, "valve 1")
	eq(PuzzleLogic.state(VALVES).current, [0, 0, 1], "west and middle drained")
	PuzzleLogic.turn_valve(VALVES, 1)
	eq(PuzzleLogic.state(VALVES).current, [0, 1, 0], "middle refilled")
	eq(PuzzleLogic.turn_valve(VALVES, 7), PuzzleLogic.Result.INVALID, "invalid valve")
	PuzzleLogic.reset(VALVES)
	eq(PuzzleLogic.state(VALVES).current, [1, 1, 1], "reset")
	var lun := GameState.currency
	PuzzleLogic.turn_valve(VALVES, 1)
	eq(PuzzleLogic.turn_valve(VALVES, 2), PuzzleLogic.Result.SOLVED, "middle + east drains all")
	check(GameState.has_flag("FLAG_VAL_CANALS_DRAINED"), "drained flag")
	eq(GameState.currency, lun + 60, "reward")
	eq(PuzzleLogic.turn_valve(VALVES, 0), PuzzleLogic.Result.ALREADY_SOLVED, "stays solved")
	eq(PuzzleLogic.next_hint(VALVES).is_empty(), false, "hints available")


func test_validator_rejects_bad_valves() -> void:
	var p: Dictionary = Content.tables.puzzles[VALVES]
	p.valve_map = [[0], [0], [0]]
	var errors := Content.validate()
	Content.load_all()
	check(errors.any(func(x): return x.contains(VALVES) and x.contains("unsolvable")), "unsolvable valves detected")


func test_canal_dungeon_in_world() -> void:
	GameState.set_flag("FLAG_VAL_CANALS_OPEN")
	game.enter_area("AREA_VAL_CANALS", "AREA_VAL_CANAL_GATE")
	await physics_frames(2)
	await finish_dialogues()
	check(not game.area.is_exit_open("AREA_VAL_CISTERN"), "cistern blocked while flooded")
	var water: Node3D = game.area.find_children("PLACEHOLDER_flooded_channel", "", true, false)[0]
	check(water.visible, "flooded channel blocks the way")
	for k in ["SPAWN_VAL_CANALS_SCHLEIM_1", "SPAWN_VAL_CANALS_KRABBE_1", "CHEST_VAL_001", "SAVEPOINT_VAL_CANALS_001"]:
		check(game.area.entities.has(k), k)
	var node: PuzzleNode = game.area.entities[VALVES]
	eq(node.gauges.size(), 3, "three channel gauges")
	node.parts[1].interact(game.player)
	node.parts[2].interact(game.player)
	check(PuzzleLogic.is_solved(VALVES), "solved in world")
	await frames(1)
	check(not water.visible, "water drained")
	check(game.area.is_exit_open("AREA_VAL_CISTERN"), "cistern open")
	check(not node.parts[0].enabled, "valves locked after solving")


func test_rostgolem_miniboss_persists() -> void:
	GameState.set_flag("FLAG_VAL_CANALS_DRAINED")
	game.enter_area("AREA_VAL_CISTERN", "AREA_VAL_CANALS")
	await physics_frames(2)
	var golem: Enemy = game.area.entities["SPAWN_VAL_CISTERN_GOLEM"]
	check(golem.break_max > 0.0, "golem has a break gauge")
	golem.take_hit(99999)
	check(GameState.has_flag("FLAG_VAL_ROSTGOLEM_DEFEATED"), "defeat flag")
	eq(Guild.kills("ENEMY_ROSTGOLEM_001"), 1, "in bestiary")
	SaveSystem.save_slot(1)
	GameState.reset_new_game()
	SaveSystem.load_slot(1)
	game.enter_area("AREA_VAL_CISTERN", "AREA_VAL_CANALS")
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_VAL_CISTERN_GOLEM"), "golem stays defeated after reload")
	GameState.set_flag("FLAG_VAL_CANALS_OPEN")
	eq(Dialogue.select_for_npc("NPC_TIBOR_001"), "DLG_TIBOR_GOLEM_001", "Tibor reacts")
