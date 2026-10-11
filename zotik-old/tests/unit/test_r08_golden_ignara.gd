extends TestCase
## Chapter-7 golden path. Starts from a save at the end of chapter 6
## (Frosthain village), loads it through the title, travels to Ignara and plays
## chapter 7 through real interactions: Brenna, the ash fields, the mines, the
## pressure valves, the Schmiedegolem, Magmarion, the side quest. Ends with a save that tests/restart_check.gd verifies in a fresh
## process.

const M := "QUEST_MAIN_IGN_001"
const S := "QUEST_SIDE_IGN_001"
const EXPECTED := "user://golden_expected_ign.json"
var game: GameRoot


func _write_chapter6_save() -> void:
	GameState.reset_new_game()
	GameState.quests = {
		"QUEST_MAIN_LUN_001": {"state": "COMPLETED", "step": 13, "progress": 0},
		"QUEST_MAIN_ELA_001": {"state": "COMPLETED", "step": 11, "progress": 0},
		"QUEST_MAIN_VAL_001": {"state": "COMPLETED", "step": 7, "progress": 0},
		"QUEST_MAIN_SOL_001": {"state": "COMPLETED", "step": 6, "progress": 0},
		"QUEST_MAIN_AQU_001": {"state": "COMPLETED", "step": 6, "progress": 0},
		"QUEST_MAIN_FRO_001": {"state": "COMPLETED", "step": 6, "progress": 0}}
	for f in ["FLAG_LUN_INTRO_SEEN", "FLAG_LUN_FOREST_UNLOCKED", "FLAG_BOSS_LUN_ORUN_DEFEATED", "FLAG_LUN_CHAPTER_COMPLETE", "FLAG_LUN_LYRA_MET", "FLAG_ELA_ARRIVED", "FLAG_ELA_LYRA_JOINED", "FLAG_ELA_NIA_JOINED", "FLAG_ELA_ROVAN_JOINED", "FLAG_BOSS_ELA_QUEEN_DEFEATED", "FLAG_ELA_CHAPTER_COMPLETE", "FLAG_VAL_ARRIVED", "FLAG_VAL_CHAPTER_COMPLETE", "FLAG_SOL_ARRIVED", "FLAG_SOL_DUNES_OPEN", "FLAG_SOL_CHAPTER_COMPLETE", "FLAG_AQU_ARRIVED", "FLAG_AQU_CAVES_OPEN", "FLAG_AQU_CHAPTER_COMPLETE", "FLAG_FRO_ARRIVED", "FLAG_FRO_FOREST_OPEN", "FLAG_FRO_CHAPTER_COMPLETE"]:
		GameState.flags[f] = true
	GameState.party = ["PARTY_LYRA_001", "PARTY_NIA_001", "PARTY_ROVAN_001"] as Array[String]
	GameState.inventory = {"WEAPON_WORLD_BLADE_001": 1, "ITEM_HEALING_POTION_001": 3, "ITEM_HI_POTION_001": 2}
	GameState.unique_rewards = {"WEAPON_WORLD_BLADE_001": true}
	GameState.equipment = {"weapon": "WEAPON_WORLD_BLADE_001"}
	GameState.currency = 1200
	GameState.player.area = "AREA_FRO_VILLAGE"
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


func test_golden_path_chapter_seven() -> void:
	SaveSystem.save_dir = "user://golden_saves_ign/"
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	Dialogue.reset()
	_write_chapter6_save()
	GameState.reset_new_game()
	App.goto_scene(App.SCENE_TITLE)
	await frames(3)
	tree.current_scene.buttons["load_1"].pressed.emit()
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)
	eq(game.area.area_id, "AREA_FRO_VILLAGE", "chapter-6 save loaded")
	eq(game.companions.size(), 3, "party restored")
	check(Content.world_unlocked("WORLD_IGNARA"), "Ignara unlocked by chapter 6")
	game.world_map.travel("WORLD_IGNARA")
	await frames(3)
	await physics_frames(4)
	eq(Dialogue.active_id, "CUT_IGN_ARRIVAL_001", "arrival")
	await finish_dialogues()
	eq(game.area.area_id, "AREA_IGN_VILLAGE", "in Kaldera")
	eq(Conditions.quest_step(M), 0, "main quest running")
	await _exit_to("AREA_IGN_FORGE")
	await _talk("NPC_VAREK_001")
	eq(Conditions.quest_step(S), 0, "side quest started")
	game.shop_menu.close_menu()
	await _exit_to("AREA_IGN_VILLAGE")
	await _talk("NPC_BRENNA_001")
	eq(Conditions.quest_step(M), 1, "find the mines")
	check(game.area.is_exit_open("AREA_IGN_ASH"), "ash fields open")
	await _exit_to("AREA_IGN_ASH")
	for id in ["SPAWN_IGN_ASH_KAEFER_1", "SPAWN_IGN_ASH_KAEFER_2", "SPAWN_IGN_ASH_FUNKE_1", "SPAWN_IGN_ASH_FUNKE_2"]:
		await _defeat(game.area.entities[id])
	game.area.entities["CHEST_IGN_001"].interact(game.player)
	game.area.entities["SAVEPOINT_IGN_ASH_001"].interact(game.player)
	game.save_menu.save(2)
	game.save_menu.close_menu()
	var gate: Node3D = game.area.entities["TRIGGER_IGN_MINES"]
	game.player.global_position = gate.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_IGN_MINES_001", "mines scene")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_IGN_MINES_OPEN"), "mines open")
	await _exit_to("AREA_IGN_MINES")
	eq(Conditions.quest_step(M), 2, "valves next")
	for id in ["SPAWN_IGN_MINES_KAEFER_1", "SPAWN_IGN_MINES_KAEFER_2", "SPAWN_IGN_MINES_FUNKE_1", "SPAWN_IGN_MINES_FUNKE_2"]:
		await _defeat(game.area.entities[id])
	game.area.entities["CHEST_IGN_002"].interact(game.player)
	var node: PuzzleNode = game.area.entities["PUZ_IGN_VALVES_001"]
	node.parts[0].interact(game.player)
	node.parts[1].interact(game.player)
	eq(Conditions.quest_step(M), 3, "Schmiedegolem next")
	check(Conditions.quest_step(S) >= 1, "enough embers for Varek")
	await _exit_to("AREA_IGN_CHAMBER")
	await _defeat(game.area.entities["SPAWN_IGN_CHAMBER_WAECHTER"])
	eq(Conditions.quest_step(M), 4, "Magmarion next")
	await _exit_to("AREA_IGN_HEART")
	var trig: Node3D = game.area.entities["TRIGGER_IGN_MAGMARION_INTRO"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_IGN_MAGMARION_001", "boss intro")
	await finish_dialogues()
	await _defeat(game.area.entities["SPAWN_IGN_HEART_MAGMARION"])
	eq(Dialogue.active_id, "CUT_IGN_MAGMARION_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_IGN_VILLAGE", "back in Kaldera")
	await _talk("NPC_BRENNA_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 7 completed")
	check(GameState.has_flag("FLAG_IGN_CHAPTER_COMPLETE"), "chapter flag")
	await _exit_to("AREA_IGN_FORGE")
	await _talk("NPC_VAREK_001")
	eq(Conditions.quest_state(S), "COMPLETED", "side quest completed")
	eq(Guild.kills("BOSS_MAGMARION_001"), 1, "bestiary entry")
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "final save")
	var f := FileAccess.open(EXPECTED, FileAccess.WRITE)
	f.store_string(JSON.stringify(GameState.to_dict()))
	f.close()
	SaveSystem.save_dir = "user://saves/"
