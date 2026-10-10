extends TestCase
## Chapter-8 golden path. Starts from a save at the end of chapter 7
## (Ignara village), loads it through the title, travels to Noctaris and plays
## chapter 8 through real interactions: Eryn, the lanes, the Nullkern, the
## memory puzzle, the Nullwächter, the Erinnerungshüter, the side quest. Ends with a save that tests/restart_check.gd verifies in a fresh
## process.

const M := "QUEST_MAIN_NOC_001"
const S := "QUEST_SIDE_NOC_001"
const EXPECTED := "user://golden_expected_noc.json"
var game: GameRoot


func _write_chapter7_save() -> void:
	GameState.reset_new_game()
	GameState.quests = {
		"QUEST_MAIN_LUN_001": {"state": "COMPLETED", "step": 13, "progress": 0},
		"QUEST_MAIN_ELA_001": {"state": "COMPLETED", "step": 11, "progress": 0},
		"QUEST_MAIN_VAL_001": {"state": "COMPLETED", "step": 7, "progress": 0},
		"QUEST_MAIN_SOL_001": {"state": "COMPLETED", "step": 6, "progress": 0},
		"QUEST_MAIN_AQU_001": {"state": "COMPLETED", "step": 6, "progress": 0},
		"QUEST_MAIN_FRO_001": {"state": "COMPLETED", "step": 6, "progress": 0},
		"QUEST_MAIN_IGN_001": {"state": "COMPLETED", "step": 6, "progress": 0}}
	for f in ["FLAG_LUN_INTRO_SEEN", "FLAG_LUN_FOREST_UNLOCKED", "FLAG_BOSS_LUN_ORUN_DEFEATED", "FLAG_LUN_CHAPTER_COMPLETE", "FLAG_LUN_LYRA_MET", "FLAG_ELA_ARRIVED", "FLAG_ELA_LYRA_JOINED", "FLAG_ELA_NIA_JOINED", "FLAG_ELA_ROVAN_JOINED", "FLAG_BOSS_ELA_QUEEN_DEFEATED", "FLAG_ELA_CHAPTER_COMPLETE", "FLAG_VAL_ARRIVED", "FLAG_VAL_CHAPTER_COMPLETE", "FLAG_SOL_ARRIVED", "FLAG_SOL_DUNES_OPEN", "FLAG_SOL_CHAPTER_COMPLETE", "FLAG_AQU_ARRIVED", "FLAG_AQU_CAVES_OPEN", "FLAG_AQU_CHAPTER_COMPLETE", "FLAG_FRO_ARRIVED", "FLAG_FRO_FOREST_OPEN", "FLAG_FRO_CHAPTER_COMPLETE", "FLAG_IGN_ARRIVED", "FLAG_IGN_ASH_OPEN", "FLAG_IGN_CHAPTER_COMPLETE"]:
		GameState.flags[f] = true
	GameState.party = ["PARTY_LYRA_001", "PARTY_NIA_001", "PARTY_ROVAN_001"] as Array[String]
	GameState.inventory = {"WEAPON_WORLD_BLADE_001": 1, "ITEM_HEALING_POTION_001": 3, "ITEM_HI_POTION_001": 2}
	GameState.unique_rewards = {"WEAPON_WORLD_BLADE_001": true}
	GameState.equipment = {"weapon": "WEAPON_WORLD_BLADE_001"}
	GameState.currency = 1200
	GameState.player.area = "AREA_IGN_VILLAGE"
	GameState.player.position = [0.0, 0.0, 10.0]
	SaveSystem.save_slot(1)


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
	while is_instance_valid(e) and not e.is_dead() and guard < 600:
		game.player.global_position = e.global_position + Vector3(0, 0, 1.4)
		game.player.face(e.global_position - game.player.global_position)
		game.player.invulnerable_time = 999.0
		game.player.attack_cooldown = 0.0
		game.player.attack(guard % 3 == 0)
		guard += 1
	check(not is_instance_valid(e) or e.is_dead(), "%s defeated" % e.enemy_id)


func test_golden_path_chapter_eight() -> void:
	SaveSystem.save_dir = "user://golden_saves_noc/"
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	Dialogue.reset()
	_write_chapter7_save()
	GameState.reset_new_game()
	App.goto_scene(App.SCENE_TITLE)
	await frames(3)
	tree.current_scene.buttons["load_1"].pressed.emit()
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)
	eq(game.area.area_id, "AREA_IGN_VILLAGE", "chapter-7 save loaded")
	eq(game.companions.size(), 3, "party restored")
	check(Content.world_unlocked("WORLD_NOCTARIS"), "Noctaris unlocked by chapter 7")
	game.world_map.travel("WORLD_NOCTARIS")
	await frames(3)
	await physics_frames(4)
	eq(Dialogue.active_id, "CUT_NOC_ARRIVAL_001", "arrival")
	await finish_dialogues()
	eq(game.area.area_id, "AREA_NOC_CITY", "in Nocturna")
	eq(Conditions.quest_step(M), 0, "main quest running")
	await _exit_to("AREA_NOC_ARCHIVE")
	await _talk("NPC_NYX_001")
	eq(Conditions.quest_step(S), 0, "side quest started")
	game.shop_menu.close_menu()
	await _exit_to("AREA_NOC_CITY")
	await _talk("NPC_ERYN_001")
	eq(Conditions.quest_step(M), 1, "find the Nullkern")
	check(game.area.is_exit_open("AREA_NOC_LANES"), "lanes open")
	await _exit_to("AREA_NOC_LANES")
	for id in ["SPAWN_NOC_LANES_FALTER_1", "SPAWN_NOC_LANES_FALTER_2", "SPAWN_NOC_LANES_VERGESSENER_1", "SPAWN_NOC_LANES_VERGESSENER_2"]:
		await _defeat(game.area.entities[id])
	game.area.entities["CHEST_NOC_001"].interact(game.player)
	game.area.entities["SAVEPOINT_NOC_LANES_001"].interact(game.player)
	game.save_menu.save(2)
	game.save_menu.close_menu()
	var gate: Node3D = game.area.entities["TRIGGER_NOC_NULL"]
	game.player.global_position = gate.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_NOC_NULL_001", "Nullkern scene")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_NOC_NULL_OPEN"), "Nullkern open")
	await _exit_to("AREA_NOC_NULL")
	eq(Conditions.quest_step(M), 2, "memory puzzle next")
	for id in ["SPAWN_NOC_NULL_FALTER_1", "SPAWN_NOC_NULL_FALTER_2", "SPAWN_NOC_NULL_VERGESSENER_1", "SPAWN_NOC_NULL_VERGESSENER_2"]:
		await _defeat(game.area.entities[id])
	game.area.entities["CHEST_NOC_002"].interact(game.player)
	var node: PuzzleNode = game.area.entities["PUZ_NOC_MEMORY_001"]
	for i in [3, 0, 4, 1, 2]:
		node.parts[i].interact(game.player)
	eq(Conditions.quest_step(M), 3, "Nullwächter next")
	check(Conditions.quest_step(S) >= 1, "enough splitters for Nyx")
	await _exit_to("AREA_NOC_CHAMBER")
	await _defeat(game.area.entities["SPAWN_NOC_CHAMBER_WAECHTER"])
	eq(Conditions.quest_step(M), 4, "den Erinnerungshüter next")
	await _exit_to("AREA_NOC_CORE")
	var trig: Node3D = game.area.entities["TRIGGER_NOC_HUETER_INTRO"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_NOC_HUETER_001", "boss intro")
	await finish_dialogues()
	await _defeat(game.area.entities["SPAWN_NOC_CORE_HUETER"])
	eq(Dialogue.active_id, "CUT_NOC_HUETER_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_NOC_CITY", "back in Nocturna")
	await _talk("NPC_ERYN_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 8 completed")
	check(GameState.has_flag("FLAG_NOC_CHAPTER_COMPLETE"), "chapter flag")
	await _exit_to("AREA_NOC_ARCHIVE")
	await _talk("NPC_NYX_001")
	eq(Conditions.quest_state(S), "COMPLETED", "side quest completed")
	eq(Guild.kills("BOSS_ERINNERUNGSHUETER_001"), 1, "bestiary entry")
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "final save")
	var f := FileAccess.open(EXPECTED, FileAccess.WRITE)
	f.store_string(JSON.stringify(GameState.to_dict()))
	f.close()
	SaveSystem.save_dir = "user://saves/"
