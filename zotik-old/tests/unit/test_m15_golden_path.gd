extends TestCase
## docs/08 critical golden path, played through real interactions.
## Stage 1 (this test) ends with a save and writes the expected state;
## tests/restart_check.gd verifies it in a fresh process (tools/run_regression.sh).

const MAIN := "QUEST_MAIN_LUN_001"
const EXPECTED := "user://golden_expected.json"
var game: GameRoot


func _exit_to(target: String) -> void:
	await tree.create_timer(WorldArea.EXIT_GRACE_MSEC / 1000.0 + 0.05).timeout
	var trig: Area3D = game.area.exits[target].trigger
	game.player.global_position = trig.global_position - Vector3(0, 1.5, 0)
	await physics_frames(4)
	await frames(2)
	eq(game.area.area_id, target, "entered " + target)
	await finish_dialogues()


func _talk(npc: String) -> void:
	var n: Npc = game.area.entities[npc]
	game.player.global_position = n.global_position + Vector3(0, 0, 1.5)
	await physics_frames(2)
	n.interact(game.player)
	await finish_dialogues()


func _defeat(spawn: String) -> void:
	var e: Enemy = game.area.entities[spawn]
	var guard := 0
	while not e.is_dead() and guard < 200:
		game.player.global_position = e.global_position + Vector3(0, 0, 1.4)
		game.player.face(e.global_position - game.player.global_position)
		game.player.attack_cooldown = 0.0
		game.player.attack()
		guard += 1
	check(e.is_dead(), spawn + " defeated")
	if e is Boss:
		for s in (e as Boss).summons:
			pass


func test_golden_path() -> void:
	SaveSystem.save_dir = "user://golden_saves/"
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	Dialogue.reset()
	# Title -> New Game -> customize Zotik
	App.goto_scene(App.SCENE_TITLE)
	await frames(3)
	tree.current_scene.buttons["new_game"].pressed.emit()
	await frames(3)
	var creator = tree.current_scene
	creator.change("scarf", 1)
	creator.change("fur_shade", 1)
	var custom := GameState.customization.duplicate()
	creator.confirm()
	await frames(3)
	game = tree.current_scene
	eq(Dialogue.active_id, "CUT_LUN_DREAM_001", "dream intro")
	await finish_dialogues()
	eq(GameState.customization, custom, "customization kept")
	# Lunaris -> Mira -> Toren -> training
	await _exit_to("AREA_LUN_VILLAGE")
	await _talk("NPC_MIRA_001")
	await _talk("NPC_TOREN_001")
	await _defeat("SPAWN_LUN_DUMMY_001")
	check(GameState.has_flag("FLAG_LUN_FOREST_UNLOCKED"), "training done")
	# Side quest offer
	await _talk("NPC_SARI_001")
	# Forest -> combat -> chests
	await _exit_to("AREA_LUN_FOREST")
	for i in range(1, 4):
		await _defeat("SPAWN_LUN_FOREST_RIFTLING_%d" % i)
	eq(Conditions.quest_step(MAIN), 5, "riftlings done")
	game.area.entities["CHEST_LUN_001"].interact(game.player)
	game.area.entities["CHEST_LUN_002"].interact(game.player)
	# Ruins: Moon Gate wrong -> reset -> correct
	await _exit_to("AREA_LUN_RUINS")
	var gate: PuzzleNode = game.area.entities["PUZ_LUN_MOONGATE_001"]
	gate.parts[1].interact(game.player)
	gate.parts[3].interact(game.player)
	check(not PuzzleLogic.is_solved("PUZ_LUN_MOONGATE_001"), "wrong attempt rejected")
	PuzzleLogic.reset("PUZ_LUN_MOONGATE_001")
	gate.refresh()
	for i in 2:
		gate.parts[0].interact(game.player)
	for i in 3:
		gate.parts[2].interact(game.player)
	gate.parts[3].interact(game.player)
	check(PuzzleLogic.is_solved("PUZ_LUN_MOONGATE_001"), "moon gate solved")
	# Dungeon: Resonance Bridge, Moonwolf, savepoint
	await _exit_to("AREA_LUN_RIFT_CAVE")
	var bridge: PuzzleNode = game.area.entities["PUZ_LUN_RESONANCE_BRIDGE_001"]
	for n in [2, 0, 3, 1]:
		bridge.parts[n].interact(game.player)
	check(GameState.has_flag("FLAG_LUN_BRIDGE_ACTIVE"), "bridge active")
	game.area.entities["CHEST_LUN_003"].interact(game.player)
	await _defeat("SPAWN_LUN_CAVE_MOONWOLF_1")
	game.area.entities["SAVEPOINT_LUN_RIFT_001"].interact(game.player)
	game.save_menu.save(2)
	game.save_menu.close_menu()
	eq(Conditions.quest_step(MAIN), 9, "ready for Orun")
	# Orun
	await _exit_to("AREA_LUN_ORUN_ARENA")
	game.player.global_position = game.area.entities["TRIGGER_LUN_ORUN_INTRO"].global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_LUN_ORUN_001", "Orun recognises Zotik")
	await finish_dialogues()
	await _defeat("SPAWN_LUN_ARENA_ORUN")
	check(GameState.has_flag("FLAG_BOSS_LUN_ORUN_DEFEATED"), "Orun defeated")
	# Rift -> Weltenklinge -> return
	game.area.entities["WEAPON_WORLD_BLADE_001"].interact(game.player)
	await finish_dialogues()
	await frames(2)
	await physics_frames(2)
	eq(game.area.area_id, "AREA_LUN_VILLAGE", "returned home")
	# Quest completion and Professorium/Lyra hook
	await _talk("NPC_MIRA_001")
	await _talk("NPC_PROFESSORIUM_001")
	eq(Conditions.quest_state(MAIN), "COMPLETED", "main quest completed")
	check(GameState.has_flag("FLAG_LUN_LYRA_MET"), "Lyra hook")
	await _talk("NPC_SARI_001")
	eq(Conditions.quest_state("QUEST_SIDE_LUN_001"), "COMPLETED", "side quest completed")
	# Save -> expected state for the restart check
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "final save")
	var f := FileAccess.open(EXPECTED, FileAccess.WRITE)
	f.store_string(JSON.stringify(GameState.to_dict()))
	f.close()
	SaveSystem.save_dir = "user://saves/"
