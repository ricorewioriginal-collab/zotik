extends TestCase
## Chapter-4 golden path. Starts from a schema-v2 save at the end of
## chapter 3 (Valdoria guild), loads it through the title, travels to
## Solmera and plays chapter 4 through real interactions: Nuri, the dunes,
## the sunken city, the mirror puzzle, the Sandwächter, Kharos, the side
## quest. Ends with a save that tests/restart_check.gd verifies in a fresh
## process.

const M := "QUEST_MAIN_SOL_001"
const S := "QUEST_SIDE_SOL_001"
const EXPECTED := "user://golden_expected_sol.json"
var game: GameRoot


func _write_chapter3_save() -> void:
	GameState.reset_new_game()
	GameState.quests = {
		"QUEST_MAIN_LUN_001": {"state": "COMPLETED", "step": 13, "progress": 0},
		"QUEST_MAIN_ELA_001": {"state": "COMPLETED", "step": 11, "progress": 0},
		"QUEST_MAIN_VAL_001": {"state": "COMPLETED", "step": 7, "progress": 0}}
	for f in ["FLAG_LUN_INTRO_SEEN", "FLAG_LUN_FOREST_UNLOCKED", "FLAG_BOSS_LUN_ORUN_DEFEATED", "FLAG_LUN_CHAPTER_COMPLETE", "FLAG_LUN_LYRA_MET", "FLAG_ELA_ARRIVED", "FLAG_ELA_LYRA_JOINED", "FLAG_ELA_NIA_JOINED", "FLAG_ELA_ROVAN_JOINED", "FLAG_BOSS_ELA_QUEEN_DEFEATED", "FLAG_ELA_CHAPTER_COMPLETE", "FLAG_VAL_ARRIVED", "FLAG_VAL_CHAPTER_COMPLETE"]:
		GameState.flags[f] = true
	GameState.party = ["PARTY_LYRA_001", "PARTY_NIA_001", "PARTY_ROVAN_001"] as Array[String]
	GameState.inventory = {"WEAPON_WORLD_BLADE_001": 1, "ITEM_HEALING_POTION_001": 3, "ITEM_HI_POTION_001": 2}
	GameState.unique_rewards = {"WEAPON_WORLD_BLADE_001": true}
	GameState.equipment = {"weapon": "WEAPON_WORLD_BLADE_001"}
	GameState.currency = 800
	GameState.player.area = "AREA_VAL_GUILD"
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


func test_golden_path_chapter_four() -> void:
	SaveSystem.save_dir = "user://golden_saves_sol/"
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	Dialogue.reset()
	_write_chapter3_save()
	GameState.reset_new_game()
	App.goto_scene(App.SCENE_TITLE)
	await frames(3)
	tree.current_scene.buttons["load_1"].pressed.emit()
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)
	eq(game.area.area_id, "AREA_VAL_GUILD", "chapter-3 save loaded")
	eq(game.companions.size(), 3, "party restored")
	# Weltenstein in Valdoria -> Solmera
	check(Content.world_unlocked("WORLD_SOLMERA"), "Solmera unlocked by chapter 3")
	await _exit_to("AREA_VAL_MARKET")
	game.area.entities["TRAVEL_VAL_001"].interact(game.player)
	game.world_map.travel("WORLD_SOLMERA")
	await frames(3)
	await physics_frames(4)
	eq(Dialogue.active_id, "CUT_SOL_ARRIVAL_001", "arrival")
	await finish_dialogues()
	eq(game.area.area_id, "AREA_SOL_OASIS", "in the oasis")
	# Bazaar: Jabir's side quest
	await _exit_to("AREA_SOL_BAZAAR")
	await _talk("NPC_JABIR_001")
	eq(Conditions.quest_step(S), 0, "side quest started")
	game.shop_menu.close_menu()
	await _exit_to("AREA_SOL_OASIS")
	# Nuri opens the Dünentor
	await _talk("NPC_NURI_001")
	eq(Conditions.quest_step(M), 1, "find the sunken city")
	check(game.area.is_exit_open("AREA_SOL_DUNES"), "dunes open")
	# Dunes
	await _exit_to("AREA_SOL_DUNES")
	for id in ["SPAWN_SOL_DUNES_SKORPION_1", "SPAWN_SOL_DUNES_SKORPION_2", "SPAWN_SOL_DUNES_GEIST_1", "SPAWN_SOL_DUNES_GEIST_2"]:
		await _defeat(game.area.entities[id])
	game.area.entities["CHEST_SOL_001"].interact(game.player)
	game.area.entities["SAVEPOINT_SOL_DUNES_001"].interact(game.player)
	game.save_menu.save(2)
	game.save_menu.close_menu()
	# Ruins trigger opens the stairs
	var ruins: Node3D = game.area.entities["TRIGGER_SOL_RUINS"]
	game.player.global_position = ruins.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_SOL_RUINS_001", "ruins scene")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_SOL_RUINS_OPEN"), "stairs open")
	# Sunken city: enemies, chest, mirror puzzle
	await _exit_to("AREA_SOL_SUNKEN")
	eq(Conditions.quest_step(M), 2, "mirrors next")
	for id in ["SPAWN_SOL_CITY_SKORPION_1", "SPAWN_SOL_CITY_SKORPION_2", "SPAWN_SOL_CITY_GEIST_1", "SPAWN_SOL_CITY_GEIST_2"]:
		await _defeat(game.area.entities[id])
	game.area.entities["CHEST_SOL_002"].interact(game.player)
	var node: PuzzleNode = game.area.entities["PUZ_SOL_MIRRORS_001"]
	for i in 4:
		for t in [1, 3, 0, 2][i]:
			node.parts[i].interact(game.player)
	node.parts[4].interact(game.player)
	eq(Conditions.quest_step(M), 3, "Sandwächter next")
	check(Conditions.quest_step(S) >= 1, "enough Sonnenstaub for Jabir")
	# Sun hall: guardian miniboss
	await _exit_to("AREA_SOL_SUN_HALL")
	await _defeat(game.area.entities["SPAWN_SOL_HALL_WAECHTER"])
	eq(Conditions.quest_step(M), 4, "Kharos next")
	# Arena: Kharos
	await _exit_to("AREA_SOL_ARENA")
	var trig: Node3D = game.area.entities["TRIGGER_SOL_KHAROS_INTRO"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_SOL_KHAROS_001", "boss intro")
	await finish_dialogues()
	await _defeat(game.area.entities["SPAWN_SOL_ARENA_KHAROS"])
	eq(Dialogue.active_id, "CUT_SOL_KHAROS_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_SOL_OASIS", "back in the oasis")
	# Report to Nuri, then Jabir
	await _talk("NPC_NURI_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 4 completed")
	check(GameState.has_flag("FLAG_SOL_CHAPTER_COMPLETE"), "chapter flag")
	await _exit_to("AREA_SOL_BAZAAR")
	await _talk("NPC_JABIR_001")
	eq(Conditions.quest_state(S), "COMPLETED", "side quest completed")
	eq(Guild.kills("BOSS_KHAROS_001"), 1, "bestiary entry")
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "final save")
	var f := FileAccess.open(EXPECTED, FileAccess.WRITE)
	f.store_string(JSON.stringify(GameState.to_dict()))
	f.close()
	SaveSystem.save_dir = "user://saves/"
