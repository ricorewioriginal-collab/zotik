extends TestCase
## Chapter-3 golden path. Starts from a schema-v2 save at the end of
## chapter 2 (as a Phase-2 player would have it), loads it through the title,
## travels to Valdoria and plays chapter 3 through real interactions,
## including the arena, a bounty, the casino and the side quest. Ends with
## a save that tests/restart_check.gd verifies in a fresh process.

const M := "QUEST_MAIN_VAL_001"
const S := "QUEST_SIDE_VAL_001"
const EXPECTED := "user://golden_expected_val.json"
var game: GameRoot


func _write_chapter2_save() -> void:
	GameState.reset_new_game()
	GameState.quests = {
		"QUEST_MAIN_LUN_001": {"state": "COMPLETED", "step": 13, "progress": 0},
		"QUEST_MAIN_ELA_001": {"state": "COMPLETED", "step": 11, "progress": 0}}
	for f in ["FLAG_LUN_INTRO_SEEN", "FLAG_LUN_FOREST_UNLOCKED", "FLAG_BOSS_LUN_ORUN_DEFEATED", "FLAG_LUN_CHAPTER_COMPLETE", "FLAG_LUN_LYRA_MET", "FLAG_ELA_ARRIVED", "FLAG_ELA_LYRA_JOINED", "FLAG_ELA_NIA_JOINED", "FLAG_ELA_ROVAN_JOINED", "FLAG_BOSS_ELA_QUEEN_DEFEATED", "FLAG_ELA_CHAPTER_COMPLETE"]:
		GameState.flags[f] = true
	GameState.party = ["PARTY_LYRA_001", "PARTY_NIA_001", "PARTY_ROVAN_001"] as Array[String]
	GameState.inventory = {"WEAPON_WORLD_BLADE_001": 1, "ITEM_HEALING_POTION_001": 3, "ITEM_HI_POTION_001": 2}
	GameState.unique_rewards = {"WEAPON_WORLD_BLADE_001": true}
	GameState.equipment = {"weapon": "WEAPON_WORLD_BLADE_001"}
	GameState.currency = 600
	GameState.player.area = "AREA_ELA_TOWN"
	GameState.player.position = [0.0, 0.0, 20.0]
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
	while is_instance_valid(e) and not e.is_dead() and guard < 400:
		game.player.global_position = e.global_position + Vector3(0, 0, 1.4)
		game.player.face(e.global_position - game.player.global_position)
		game.player.invulnerable_time = 999.0
		game.player.attack_cooldown = 0.0
		game.player.attack(guard % 3 == 0)
		guard += 1
	check(not is_instance_valid(e) or e.is_dead(), "%s defeated" % e.enemy_id)


func test_golden_path_chapter_three() -> void:
	SaveSystem.save_dir = "user://golden_saves_val/"
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	Dialogue.reset()
	_write_chapter2_save()
	GameState.reset_new_game()
	App.goto_scene(App.SCENE_TITLE)
	await frames(3)
	tree.current_scene.buttons["load_1"].pressed.emit()
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)
	eq(game.area.area_id, "AREA_ELA_TOWN", "chapter-2 save loaded")
	eq(game.companions.size(), 3, "party restored")
	# Weltenstein -> Valdoria
	game.area.entities["TRAVEL_ELA_001"].interact(game.player)
	game.world_map.travel("WORLD_VALDORIA")
	await frames(3)
	await physics_frames(4)
	eq(Dialogue.active_id, "CUT_VAL_ARRIVAL_001", "arrival")
	await finish_dialogues()
	eq(Conditions.quest_step(M), 0, "chapter 3 started")
	# Market: Lotte's side quest, one casino spin with virtual Lun
	await _talk("NPC_LOTTE_001")
	eq(Conditions.quest_step(S), 0, "side quest started")
	game.area.entities["CASINO_VAL_001"].interact(game.player)
	await frames(1)
	check(game.casino_menu.visible, "casino open")
	Casino.rng.seed = 7
	check(not Casino.spin(10).is_empty(), "spin")
	game.casino_menu.close_menu()
	# Guild: Veyr, bounty, arena
	await _exit_to("AREA_VAL_GUILD")
	await _talk("NPC_VEYR_001")
	eq(Conditions.quest_step(M), 1, "go to Tibor")
	game.area.entities["BOARD_VAL_GUILD_001"].interact(game.player)
	game.bounty_menu.accept("BOUNTY_RIFTLING_001")
	game.bounty_menu.close_menu()
	await _exit_to("AREA_VAL_ARENA")
	await _talk("NPC_KASIMIR_001")
	check(game.arena_menu.visible, "arena menu")
	game.arena_menu.start("ARENA_BRONZE_001")
	for w in 2:
		for e in game.arena_run.alive.duplicate():
			await _defeat(e)
		await frames(2)
	check(GameState.has_flag("FLAG_VAL_ARENA_BRONZE"), "bronze won")
	await finish_dialogues()
	# Canal gate -> canals
	await _exit_to("AREA_VAL_GUILD")
	await _exit_to("AREA_VAL_MARKET")
	await _exit_to("AREA_VAL_CANAL_GATE")
	await _talk("NPC_TIBOR_001")
	eq(Conditions.quest_step(M), 2, "gate open")
	await _exit_to("AREA_VAL_CANALS")
	eq(Conditions.quest_step(M), 3, "in the canals")
	await _defeat(game.area.entities["SPAWN_VAL_CANALS_KRABBE_1"])
	await _defeat(game.area.entities["SPAWN_VAL_CANALS_SCHLEIM_1"])
	game.area.entities["CHEST_VAL_001"].interact(game.player)
	game.area.entities["SAVEPOINT_VAL_CANALS_001"].interact(game.player)
	game.save_menu.save(2)
	game.save_menu.close_menu()
	var valves: PuzzleNode = game.area.entities["PUZ_VAL_VALVES_001"]
	valves.parts[0].interact(game.player)
	valves.parts[0].interact(game.player)
	eq(Array(PuzzleLogic.state("PUZ_VAL_VALVES_001").current), [1, 1, 1], "second turn undoes the first")
	valves.parts[1].interact(game.player)
	valves.parts[2].interact(game.player)
	eq(Conditions.quest_step(M), 4, "canals drained")
	# Cistern: Rostgolem
	await _exit_to("AREA_VAL_CISTERN")
	await _defeat(game.area.entities["SPAWN_VAL_CISTERN_GOLEM"])
	eq(Conditions.quest_step(M), 5, "boss next")
	eq(Conditions.quest_step(S), 1, "enough scrap for Lotte")
	# Floodgate: Kanalwächter
	await _exit_to("AREA_VAL_FLOODGATE")
	game.player.global_position = game.area.entities["TRIGGER_VAL_WAECHTER_INTRO"].global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_VAL_WAECHTER_001", "boss intro")
	await finish_dialogues()
	await _defeat(game.area.entities["SPAWN_VAL_FLOODGATE_WAECHTER"])
	eq(Dialogue.active_id, "CUT_VAL_WAECHTER_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_VAL_CANAL_GATE", "back at the canal gate")
	# Lotte, then Veyr
	await _exit_to("AREA_VAL_MARKET")
	await _talk("NPC_LOTTE_001")
	eq(Conditions.quest_state(S), "COMPLETED", "side quest completed")
	await _exit_to("AREA_VAL_GUILD")
	await _talk("NPC_VEYR_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 3 completed")
	check(GameState.has_flag("FLAG_VAL_CHAPTER_COMPLETE"), "chapter flag")
	eq(Guild.kills("BOSS_KANALWAECHTER_001"), 1, "bestiary entry")
	check(Guild.state("BOUNTY_RIFTLING_001") != "", "bounty tracked")
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "final save")
	var f := FileAccess.open(EXPECTED, FileAccess.WRITE)
	f.store_string(JSON.stringify(GameState.to_dict()))
	f.close()
	SaveSystem.save_dir = "user://saves/"
