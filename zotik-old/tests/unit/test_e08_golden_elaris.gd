extends TestCase
## Chapter-2 golden path. Starts from a real schema-v1 save at the end of
## chapter 1 (as a Phase-1 player would have it), loads it through the title,
## travels to Elaris and plays chapter 2 through real interactions. Ends with
## a save that tests/restart_check.gd verifies in a fresh process.

const M := "QUEST_MAIN_ELA_001"
const EXPECTED := "user://golden_expected_ela.json"
var game: GameRoot


func _write_v1_chapter1_save() -> void:
	GameState.reset_new_game()
	GameState.quests = {"QUEST_MAIN_LUN_001": {"state": "COMPLETED", "step": 13, "progress": 0}}
	for f in ["FLAG_LUN_INTRO_SEEN", "FLAG_LUN_FOREST_UNLOCKED", "FLAG_BOSS_LUN_ORUN_DEFEATED", "FLAG_LUN_CHAPTER_COMPLETE", "FLAG_LUN_LYRA_MET", "FLAG_LUN_PROFESSORIUM_ARRIVED", "FLAG_LUN_RETURNED"]:
		GameState.flags[f] = true
	GameState.inventory = {"WEAPON_WORLD_BLADE_001": 1, "ITEM_HEALING_POTION_001": 3}
	GameState.unique_rewards = {"WEAPON_WORLD_BLADE_001": true}
	GameState.equipment = {"weapon": "WEAPON_WORLD_BLADE_001"}
	GameState.currency = 250
	GameState.player.area = "AREA_LUN_VILLAGE"
	GameState.player.position = [-20.0, 0.0, 22.0]
	SaveSystem.save_slot(1)
	var env = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(1)))
	env.schema_version = 1
	env.data.erase("party")
	env.checksum = SaveSystem._checksum(env.data)
	var f := FileAccess.open(SaveSystem.slot_path(1), FileAccess.WRITE)
	f.store_string(JSON.stringify(env))
	f.close()


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


func _defeat(e: Enemy) -> void:
	var guard := 0
	while is_instance_valid(e) and not e.is_dead() and guard < 300:
		game.player.global_position = e.global_position + Vector3(0, 0, 1.4)
		game.player.face(e.global_position - game.player.global_position)
		game.player.invulnerable_time = 999.0
		game.player.attack_cooldown = 0.0
		game.player.attack(guard % 3 == 0)
		guard += 1
	check(not is_instance_valid(e) or e.is_dead(), "%s defeated" % e.enemy_id)


func test_golden_path_chapter_two() -> void:
	SaveSystem.save_dir = "user://golden_saves_ela/"
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	Dialogue.reset()
	_write_v1_chapter1_save()
	GameState.reset_new_game()
	# Load the Phase-1 save through the title (v1 -> v2 migration)
	App.goto_scene(App.SCENE_TITLE)
	await frames(3)
	tree.current_scene.buttons["load_1"].pressed.emit()
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)
	eq(game.area.area_id, "AREA_LUN_VILLAGE", "Phase-1 save loaded")
	eq(GameState.party, [] as Array[String], "migrated party")
	# Weltenstein -> Elaris
	game.area.entities["TRAVEL_LUN_001"].interact(game.player)
	game.world_map.travel("WORLD_ELARIS")
	await frames(3)
	await physics_frames(4)
	eq(Dialogue.active_id, "CUT_ELA_ARRIVAL_001", "arrival")
	await finish_dialogues()
	eq(Conditions.quest_step(M), 0, "chapter 2 started")
	# Town: Mara, Nia, Sela
	await _talk("NPC_MARA_001")
	await _talk("NPC_NIA_001")
	await _talk("NPC_SELA_001")
	eq(GameState.party.size(), 2, "Lyra + Nia")
	# Living forest: Pilzlinge, chest, moving path, Rovan
	await _exit_to("AREA_ELA_FOREST")
	for i in range(1, 4):
		await _defeat(game.area.entities["SPAWN_ELA_FOREST_PILZ_%d" % i])
	game.area.entities["CHEST_ELA_001"].interact(game.player)
	var plat: MovingPlatform = game.area.entities["PLATFORM_ELA_PATH_1"]
	plat.t = 0.0
	await physics_frames(1)
	game.player.global_position = plat.global_position + Vector3(0, 0.6, 0)
	await physics_frames(int(plat.period * 0.5 * 60) + 10)
	check(game.player.global_position.z < -5.0, "crossed the ravine on the moving path")
	await _talk("NPC_ROVAN_001")
	eq(GameState.party.size(), 3, "Rovan joined")
	# Tower of Memory
	await _exit_to("AREA_ELA_TOWER")
	var turm: PuzzleNode = game.area.entities["PUZ_ELA_TURM_001"]
	var labels: Array = PuzzleLogic.data("PUZ_ELA_TURM_001").node_labels
	turm.parts[labels.find("Flamme")].interact(game.player)
	check(Array(PuzzleLogic.state("PUZ_ELA_TURM_001").current).is_empty(), "wrong start resets")
	for s in ["Mond", "Blatt", "Kristall", "Flamme"]:
		turm.parts[labels.find(s)].interact(game.player)
	eq(Dialogue.active_id, "CUT_ELA_TURM_EPILOG_001", "spec epilogue")
	await finish_dialogues()
	# Heart of the forest: anchor, chest, Wurzelkriecher
	await _exit_to("AREA_ELA_DUNGEON")
	game.area.entities["CHEST_ELA_002"].interact(game.player)
	game.area.entities["SAVEPOINT_ELA_001"].interact(game.player)
	game.save_menu.save(2)
	game.save_menu.close_menu()
	await _defeat(game.area.entities["SPAWN_ELA_DUNGEON_KRIECHER"])
	eq(Conditions.quest_step(M), 9, "ready for the queen")
	# Root throne
	await _exit_to("AREA_ELA_ROOT_ARENA")
	game.player.global_position = game.area.entities["TRIGGER_ELA_QUEEN_INTRO"].global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_ELA_QUEEN_001", "queen intro")
	await finish_dialogues()
	await _defeat(game.area.entities["SPAWN_ELA_ARENA_QUEEN"])
	eq(Dialogue.active_id, "CUT_ELA_QUEEN_DEFEAT_001", "memory vision")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_ELA_TOWN", "back in town")
	# Report to Mara; Sela's spores (3 from Pilzlinge + 3 from the chest)
	await _talk("NPC_MARA_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 2 completed")
	check(Inventory.count("ITEM_SPORE_001") >= 5, "enough spores collected")
	await _talk("NPC_SELA_001")
	eq(Conditions.quest_state("QUEST_SIDE_ELA_001"), "COMPLETED", "side quest completed")
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "final save")
	var f := FileAccess.open(EXPECTED, FileAccess.WRITE)
	f.store_string(JSON.stringify(GameState.to_dict()))
	f.close()
	SaveSystem.save_dir = "user://saves/"
