extends TestCase
## X01: the whole game in one session, without prepared saves. New game from
## the title, chapter 1 in Lunaris, Weltenstein to Elaris, chapter 2,
## Weltenstein to Valdoria, chapter 3, Weltenstein to Solmera, chapter 4, Weltenstein to Aqualis, chapter 5, Weltenstein to Frosthain, chapter 6, Weltenstein to Ignara, chapter 7, Weltenstein to Noctaris, chapter 8, then save -> reset -> load through the
## title. Unlike the per-chapter golden paths (m15/e08/v06) every chapter
## starts from the state the previous one really produced, so a broken
## hand-over between chapters fails here.

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


func _defeat_spawn(spawn: String) -> void:
	await _defeat(game.area.entities[spawn])


func _boss_intro(trigger: String, cutscene: String) -> void:
	game.player.global_position = game.area.entities[trigger].global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, cutscene, cutscene)
	await finish_dialogues()


func _travel(stone: String, world: String, arrival: String) -> void:
	game.area.entities[stone].interact(game.player)
	game.world_map.travel(world)
	await frames(3)
	await physics_frames(4)
	eq(Dialogue.active_id, arrival, arrival)
	await finish_dialogues()


func _use_savepoint(id: String, slot: int) -> void:
	game.area.entities[id].interact(game.player)
	check(game.save_menu.visible, id + " opens the save menu")
	game.save_menu.save(slot)
	game.save_menu.close_menu()


func _chapter_one() -> void:
	const M := "QUEST_MAIN_LUN_001"
	App.goto_scene(App.SCENE_TITLE)
	await frames(3)
	tree.current_scene.buttons["new_game"].pressed.emit()
	await frames(3)
	tree.current_scene.confirm()
	await frames(3)
	game = tree.current_scene
	eq(Dialogue.active_id, "CUT_LUN_DREAM_001", "dream intro")
	await finish_dialogues()
	await _exit_to("AREA_LUN_VILLAGE")
	await _talk("NPC_MIRA_001")
	await _talk("NPC_TOREN_001")
	await _defeat_spawn("SPAWN_LUN_DUMMY_001")
	check(GameState.has_flag("FLAG_LUN_FOREST_UNLOCKED"), "training done")
	await _talk("NPC_SARI_001")
	await _exit_to("AREA_LUN_FOREST")
	for i in range(1, 4):
		await _defeat_spawn("SPAWN_LUN_FOREST_RIFTLING_%d" % i)
	eq(Conditions.quest_step(M), 5, "riftlings done")
	game.area.entities["CHEST_LUN_001"].interact(game.player)
	game.area.entities["CHEST_LUN_002"].interact(game.player)
	await _exit_to("AREA_LUN_RUINS")
	var gate: PuzzleNode = game.area.entities["PUZ_LUN_MOONGATE_001"]
	for i in 2:
		gate.parts[0].interact(game.player)
	for i in 3:
		gate.parts[2].interact(game.player)
	gate.parts[3].interact(game.player)
	check(PuzzleLogic.is_solved("PUZ_LUN_MOONGATE_001"), "moon gate solved")
	await _exit_to("AREA_LUN_RIFT_CAVE")
	var bridge: PuzzleNode = game.area.entities["PUZ_LUN_RESONANCE_BRIDGE_001"]
	for n in [2, 0, 3, 1]:
		bridge.parts[n].interact(game.player)
	check(GameState.has_flag("FLAG_LUN_BRIDGE_ACTIVE"), "bridge active")
	game.area.entities["CHEST_LUN_003"].interact(game.player)
	await _defeat_spawn("SPAWN_LUN_CAVE_MOONWOLF_1")
	await _use_savepoint("SAVEPOINT_LUN_RIFT_001", 2)
	eq(Conditions.quest_step(M), 9, "ready for Orun")
	await _exit_to("AREA_LUN_ORUN_ARENA")
	await _boss_intro("TRIGGER_LUN_ORUN_INTRO", "CUT_LUN_ORUN_001")
	await _defeat_spawn("SPAWN_LUN_ARENA_ORUN")
	game.area.entities["WEAPON_WORLD_BLADE_001"].interact(game.player)
	await finish_dialogues()
	await frames(2)
	await physics_frames(2)
	eq(game.area.area_id, "AREA_LUN_VILLAGE", "returned home")
	await _talk("NPC_MIRA_001")
	await _talk("NPC_PROFESSORIUM_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 1 completed")
	await _talk("NPC_SARI_001")
	eq(Conditions.quest_state("QUEST_SIDE_LUN_001"), "COMPLETED", "Lunaris side quest completed")


func _chapter_two() -> void:
	const M := "QUEST_MAIN_ELA_001"
	await _travel("TRAVEL_LUN_001", "WORLD_ELARIS", "CUT_ELA_ARRIVAL_001")
	eq(Conditions.quest_step(M), 0, "chapter 2 started")
	await _talk("NPC_MARA_001")
	await _talk("NPC_NIA_001")
	await _talk("NPC_SELA_001")
	eq(GameState.party.size(), 2, "Lyra + Nia")
	eq(game.companions.size(), 2, "two companions follow")
	await _exit_to("AREA_ELA_FOREST")
	for i in range(1, 4):
		await _defeat_spawn("SPAWN_ELA_FOREST_PILZ_%d" % i)
	game.area.entities["CHEST_ELA_001"].interact(game.player)
	var plat: MovingPlatform = game.area.entities["PLATFORM_ELA_PATH_1"]
	plat.t = 0.0
	await physics_frames(1)
	game.player.global_position = plat.global_position + Vector3(0, 0.6, 0)
	await physics_frames(int(plat.period * 0.5 * 60) + 10)
	check(game.player.global_position.z < -5.0, "crossed the ravine")
	await _talk("NPC_ROVAN_001")
	eq(GameState.party.size(), 3, "Rovan joined")
	await _exit_to("AREA_ELA_TOWER")
	var turm: PuzzleNode = game.area.entities["PUZ_ELA_TURM_001"]
	var labels: Array = PuzzleLogic.data("PUZ_ELA_TURM_001").node_labels
	for s in ["Mond", "Blatt", "Kristall", "Flamme"]:
		turm.parts[labels.find(s)].interact(game.player)
	eq(Dialogue.active_id, "CUT_ELA_TURM_EPILOG_001", "tower solved")
	await finish_dialogues()
	await _exit_to("AREA_ELA_DUNGEON")
	game.area.entities["CHEST_ELA_002"].interact(game.player)
	await _use_savepoint("SAVEPOINT_ELA_001", 2)
	await _defeat_spawn("SPAWN_ELA_DUNGEON_KRIECHER")
	eq(Conditions.quest_step(M), 9, "ready for the queen")
	await _exit_to("AREA_ELA_ROOT_ARENA")
	await _boss_intro("TRIGGER_ELA_QUEEN_INTRO", "CUT_ELA_QUEEN_001")
	await _defeat_spawn("SPAWN_ELA_ARENA_QUEEN")
	eq(Dialogue.active_id, "CUT_ELA_QUEEN_DEFEAT_001", "memory vision")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_ELA_TOWN", "back in town")
	await _talk("NPC_MARA_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 2 completed")
	await _talk("NPC_SELA_001")
	eq(Conditions.quest_state("QUEST_SIDE_ELA_001"), "COMPLETED", "Elaris side quest completed")


func _chapter_three() -> void:
	const M := "QUEST_MAIN_VAL_001"
	const S := "QUEST_SIDE_VAL_001"
	await _travel("TRAVEL_ELA_001", "WORLD_VALDORIA", "CUT_VAL_ARRIVAL_001")
	eq(Conditions.quest_step(M), 0, "chapter 3 started")
	eq(game.companions.size(), 3, "party travels along")
	await _talk("NPC_LOTTE_001")
	eq(Conditions.quest_step(S), 0, "Valdoria side quest started")
	await _exit_to("AREA_VAL_GUILD")
	await _talk("NPC_VEYR_001")
	eq(Conditions.quest_step(M), 1, "go to Tibor")
	game.area.entities["BOARD_VAL_GUILD_001"].interact(game.player)
	game.bounty_menu.accept("BOUNTY_RIFTLING_001")
	game.bounty_menu.close_menu()
	await _exit_to("AREA_VAL_ARENA")
	await _talk("NPC_KASIMIR_001")
	game.arena_menu.start("ARENA_BRONZE_001")
	for w in 2:
		for e in game.arena_run.alive.duplicate():
			await _defeat(e)
		await frames(2)
	check(GameState.has_flag("FLAG_VAL_ARENA_BRONZE"), "bronze won")
	await finish_dialogues()
	await _exit_to("AREA_VAL_GUILD")
	await _exit_to("AREA_VAL_MARKET")
	await _exit_to("AREA_VAL_CANAL_GATE")
	await _talk("NPC_TIBOR_001")
	eq(Conditions.quest_step(M), 2, "gate open")
	await _exit_to("AREA_VAL_CANALS")
	await _defeat_spawn("SPAWN_VAL_CANALS_KRABBE_1")
	await _defeat_spawn("SPAWN_VAL_CANALS_SCHLEIM_1")
	game.area.entities["CHEST_VAL_001"].interact(game.player)
	await _use_savepoint("SAVEPOINT_VAL_CANALS_001", 2)
	var valves: PuzzleNode = game.area.entities["PUZ_VAL_VALVES_001"]
	for n in [1, 2]:
		valves.parts[n].interact(game.player)
	eq(Conditions.quest_step(M), 4, "canals drained")
	await _exit_to("AREA_VAL_CISTERN")
	await _defeat_spawn("SPAWN_VAL_CISTERN_GOLEM")
	eq(Conditions.quest_step(S), 1, "enough scrap for Lotte")
	await _exit_to("AREA_VAL_FLOODGATE")
	await _boss_intro("TRIGGER_VAL_WAECHTER_INTRO", "CUT_VAL_WAECHTER_001")
	await _defeat_spawn("SPAWN_VAL_FLOODGATE_WAECHTER")
	eq(Dialogue.active_id, "CUT_VAL_WAECHTER_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_VAL_CANAL_GATE", "back at the canal gate")
	await _exit_to("AREA_VAL_MARKET")
	await _talk("NPC_LOTTE_001")
	eq(Conditions.quest_state(S), "COMPLETED", "Valdoria side quest completed")
	await _exit_to("AREA_VAL_GUILD")
	await _talk("NPC_VEYR_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 3 completed")


func _chapter_four() -> void:
	const M := "QUEST_MAIN_SOL_001"
	const S := "QUEST_SIDE_SOL_001"
	await _exit_to("AREA_VAL_MARKET")
	await _travel("TRAVEL_VAL_001", "WORLD_SOLMERA", "CUT_SOL_ARRIVAL_001")
	eq(game.area.area_id, "AREA_SOL_OASIS", "in the oasis")
	eq(game.companions.size(), 3, "party travels along")
	await _exit_to("AREA_SOL_BAZAAR")
	await _talk("NPC_JABIR_001")
	eq(Conditions.quest_step(S), 0, "Solmera side quest started")
	game.shop_menu.close_menu()
	await _exit_to("AREA_SOL_OASIS")
	await _talk("NPC_NURI_001")
	eq(Conditions.quest_step(M), 1, "find the sunken city")
	await _exit_to("AREA_SOL_DUNES")
	for id in ["SPAWN_SOL_DUNES_SKORPION_1", "SPAWN_SOL_DUNES_SKORPION_2", "SPAWN_SOL_DUNES_GEIST_1", "SPAWN_SOL_DUNES_GEIST_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_SOL_001"].interact(game.player)
	await _use_savepoint("SAVEPOINT_SOL_DUNES_001", 2)
	await _boss_intro("TRIGGER_SOL_RUINS", "CUT_SOL_RUINS_001")
	await _exit_to("AREA_SOL_SUNKEN")
	eq(Conditions.quest_step(M), 2, "mirrors next")
	for id in ["SPAWN_SOL_CITY_SKORPION_1", "SPAWN_SOL_CITY_SKORPION_2", "SPAWN_SOL_CITY_GEIST_1", "SPAWN_SOL_CITY_GEIST_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_SOL_002"].interact(game.player)
	var node: PuzzleNode = game.area.entities["PUZ_SOL_MIRRORS_001"]
	for i in 4:
		for t in [1, 3, 0, 2][i]:
			node.parts[i].interact(game.player)
	node.parts[4].interact(game.player)
	eq(Conditions.quest_step(M), 3, "Sandwächter next")
	await _exit_to("AREA_SOL_SUN_HALL")
	await _defeat_spawn("SPAWN_SOL_HALL_WAECHTER")
	eq(Conditions.quest_step(M), 4, "Kharos next")
	await _exit_to("AREA_SOL_ARENA")
	await _boss_intro("TRIGGER_SOL_KHAROS_INTRO", "CUT_SOL_KHAROS_001")
	await _defeat_spawn("SPAWN_SOL_ARENA_KHAROS")
	eq(Dialogue.active_id, "CUT_SOL_KHAROS_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_SOL_OASIS", "back in the oasis")
	await _talk("NPC_NURI_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 4 completed")
	await _exit_to("AREA_SOL_BAZAAR")
	await _talk("NPC_JABIR_001")
	eq(Conditions.quest_state(S), "COMPLETED", "Solmera side quest completed")


func _chapter_five() -> void:
	const M := "QUEST_MAIN_AQU_001"
	const S := "QUEST_SIDE_AQU_001"
	await _exit_to("AREA_SOL_OASIS")
	await _travel("TRAVEL_SOL_001", "WORLD_AQUALIS", "CUT_AQU_ARRIVAL_001")
	eq(game.area.area_id, "AREA_AQU_DOME", "in the dome")
	await _exit_to("AREA_AQU_HARBOUR")
	await _talk("NPC_PERLA_001")
	eq(Conditions.quest_step(S), 0, "Aqualis side quest started")
	game.shop_menu.close_menu()
	await _exit_to("AREA_AQU_DOME")
	await _talk("NPC_MIRAEL_001")
	eq(Conditions.quest_step(M), 1, "find the archive")
	await _exit_to("AREA_AQU_CAVES")
	for id in ["SPAWN_AQU_CAVES_KRABBE_1", "SPAWN_AQU_CAVES_KRABBE_2", "SPAWN_AQU_CAVES_QUALLE_1", "SPAWN_AQU_CAVES_QUALLE_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_AQU_001"].interact(game.player)
	await _use_savepoint("SAVEPOINT_AQU_CAVES_001", 2)
	await _boss_intro("TRIGGER_AQU_ARCHIVE", "CUT_AQU_ARCHIVE_001")
	await _exit_to("AREA_AQU_ARCHIVE")
	eq(Conditions.quest_step(M), 2, "currents next")
	for id in ["SPAWN_AQU_ARCHIVE_KRABBE_1", "SPAWN_AQU_ARCHIVE_KRABBE_2", "SPAWN_AQU_ARCHIVE_QUALLE_1", "SPAWN_AQU_ARCHIVE_QUALLE_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_AQU_002"].interact(game.player)
	var node: PuzzleNode = game.area.entities["PUZ_AQU_CURRENTS_001"]
	node.parts[0].interact(game.player)
	node.parts[2].interact(game.player)
	eq(Conditions.quest_step(M), 3, "Archivwächter next")
	await _exit_to("AREA_AQU_VAULT")
	await _defeat_spawn("SPAWN_AQU_VAULT_WAECHTER")
	eq(Conditions.quest_step(M), 4, "Neryx next")
	await _exit_to("AREA_AQU_ABYSS")
	await _boss_intro("TRIGGER_AQU_NERYX_INTRO", "CUT_AQU_NERYX_001")
	await _defeat_spawn("SPAWN_AQU_ABYSS_NERYX")
	eq(Dialogue.active_id, "CUT_AQU_NERYX_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_AQU_DOME", "back in the dome")
	await _talk("NPC_MIRAEL_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 5 completed")
	await _exit_to("AREA_AQU_HARBOUR")
	await _talk("NPC_PERLA_001")
	eq(Conditions.quest_state(S), "COMPLETED", "Aqualis side quest completed")


func _chapter_six() -> void:
	const M := "QUEST_MAIN_FRO_001"
	const S := "QUEST_SIDE_FRO_001"
	await _exit_to("AREA_AQU_DOME")
	await _travel("TRAVEL_AQU_001", "WORLD_FROSTHAIN", "CUT_FRO_ARRIVAL_001")
	eq(game.area.area_id, "AREA_FRO_VILLAGE", "in the village")
	await _exit_to("AREA_FRO_HALL")
	await _talk("NPC_TORMUND_001")
	eq(Conditions.quest_step(S), 0, "Frosthain side quest started")
	game.shop_menu.close_menu()
	await _exit_to("AREA_FRO_VILLAGE")
	await _talk("NPC_KAELEN_001")
	eq(Conditions.quest_step(M), 1, "find the city")
	await _exit_to("AREA_FRO_FOREST")
	for id in ["SPAWN_FRO_FOREST_WOLF_1", "SPAWN_FRO_FOREST_WOLF_2", "SPAWN_FRO_FOREST_GEIST_1", "SPAWN_FRO_FOREST_GEIST_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_FRO_001"].interact(game.player)
	await _use_savepoint("SAVEPOINT_FRO_FOREST_001", 2)
	await _boss_intro("TRIGGER_FRO_CITY", "CUT_FRO_CITY_001")
	await _exit_to("AREA_FRO_CITY")
	eq(Conditions.quest_step(M), 2, "ice next")
	for id in ["SPAWN_FRO_CITY_WOLF_1", "SPAWN_FRO_CITY_WOLF_2", "SPAWN_FRO_CITY_GEIST_1", "SPAWN_FRO_CITY_GEIST_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_FRO_002"].interact(game.player)
	var node: PuzzleNode = game.area.entities["PUZ_FRO_ICE_001"]
	for i in [3, 1, 4, 0, 2]:
		node.parts[i].interact(game.player)
	eq(Conditions.quest_step(M), 3, "Eiswächter next")
	await _exit_to("AREA_FRO_TEMPLE")
	await _defeat_spawn("SPAWN_FRO_TEMPLE_WAECHTER")
	eq(Conditions.quest_step(M), 4, "Avarn next")
	await _exit_to("AREA_FRO_CORE")
	await _boss_intro("TRIGGER_FRO_AVARN_INTRO", "CUT_FRO_AVARN_001")
	await _defeat_spawn("SPAWN_FRO_CORE_AVARN")
	eq(Dialogue.active_id, "CUT_FRO_AVARN_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_FRO_VILLAGE", "back in the village")
	await _talk("NPC_KAELEN_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 6 completed")
	await _exit_to("AREA_FRO_HALL")
	await _talk("NPC_TORMUND_001")
	eq(Conditions.quest_state(S), "COMPLETED", "Frosthain side quest completed")


func _chapter_seven() -> void:
	const M := "QUEST_MAIN_IGN_001"
	const S := "QUEST_SIDE_IGN_001"
	await _exit_to("AREA_FRO_VILLAGE")
	await _travel("TRAVEL_FRO_001", "WORLD_IGNARA", "CUT_IGN_ARRIVAL_001")
	eq(game.area.area_id, "AREA_IGN_VILLAGE", "in Kaldera")
	await _exit_to("AREA_IGN_FORGE")
	await _talk("NPC_VAREK_001")
	eq(Conditions.quest_step(S), 0, "Ignara side quest started")
	game.shop_menu.close_menu()
	await _exit_to("AREA_IGN_VILLAGE")
	await _talk("NPC_BRENNA_001")
	eq(Conditions.quest_step(M), 1, "find the mines")
	await _exit_to("AREA_IGN_ASH")
	for id in ["SPAWN_IGN_ASH_KAEFER_1", "SPAWN_IGN_ASH_KAEFER_2", "SPAWN_IGN_ASH_FUNKE_1", "SPAWN_IGN_ASH_FUNKE_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_IGN_001"].interact(game.player)
	await _use_savepoint("SAVEPOINT_IGN_ASH_001", 2)
	await _boss_intro("TRIGGER_IGN_MINES", "CUT_IGN_MINES_001")
	await _exit_to("AREA_IGN_MINES")
	eq(Conditions.quest_step(M), 2, "valves next")
	for id in ["SPAWN_IGN_MINES_KAEFER_1", "SPAWN_IGN_MINES_KAEFER_2", "SPAWN_IGN_MINES_FUNKE_1", "SPAWN_IGN_MINES_FUNKE_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_IGN_002"].interact(game.player)
	var node: PuzzleNode = game.area.entities["PUZ_IGN_VALVES_001"]
	node.parts[0].interact(game.player)
	node.parts[1].interact(game.player)
	eq(Conditions.quest_step(M), 3, "Schmiedegolem next")
	await _exit_to("AREA_IGN_CHAMBER")
	await _defeat_spawn("SPAWN_IGN_CHAMBER_WAECHTER")
	eq(Conditions.quest_step(M), 4, "Magmarion next")
	await _exit_to("AREA_IGN_HEART")
	await _boss_intro("TRIGGER_IGN_MAGMARION_INTRO", "CUT_IGN_MAGMARION_001")
	await _defeat_spawn("SPAWN_IGN_HEART_MAGMARION")
	eq(Dialogue.active_id, "CUT_IGN_MAGMARION_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_IGN_VILLAGE", "back in Kaldera")
	await _talk("NPC_BRENNA_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 7 completed")
	await _exit_to("AREA_IGN_FORGE")
	await _talk("NPC_VAREK_001")
	eq(Conditions.quest_state(S), "COMPLETED", "Ignara side quest completed")


func _chapter_eight() -> void:
	const M := "QUEST_MAIN_NOC_001"
	const S := "QUEST_SIDE_NOC_001"
	await _exit_to("AREA_IGN_VILLAGE")
	await _travel("TRAVEL_IGN_001", "WORLD_NOCTARIS", "CUT_NOC_ARRIVAL_001")
	eq(game.area.area_id, "AREA_NOC_CITY", "in Nocturna")
	await _exit_to("AREA_NOC_ARCHIVE")
	await _talk("NPC_NYX_001")
	eq(Conditions.quest_step(S), 0, "Noctaris side quest started")
	game.shop_menu.close_menu()
	await _exit_to("AREA_NOC_CITY")
	await _talk("NPC_ERYN_001")
	eq(Conditions.quest_step(M), 1, "find the ruins")
	await _exit_to("AREA_NOC_LANES")
	for id in ["SPAWN_NOC_LANES_FALTER_1", "SPAWN_NOC_LANES_FALTER_2", "SPAWN_NOC_LANES_VERGESSENER_1", "SPAWN_NOC_LANES_VERGESSENER_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_NOC_001"].interact(game.player)
	await _use_savepoint("SAVEPOINT_NOC_LANES_001", 2)
	await _boss_intro("TRIGGER_NOC_NULL", "CUT_NOC_NULL_001")
	await _exit_to("AREA_NOC_NULL")
	eq(Conditions.quest_step(M), 2, "memory puzzle next")
	for id in ["SPAWN_NOC_NULL_FALTER_1", "SPAWN_NOC_NULL_FALTER_2", "SPAWN_NOC_NULL_VERGESSENER_1", "SPAWN_NOC_NULL_VERGESSENER_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_NOC_002"].interact(game.player)
	var node: PuzzleNode = game.area.entities["PUZ_NOC_MEMORY_001"]
	for i in [3, 0, 4, 1, 2]:
		node.parts[i].interact(game.player)
	eq(Conditions.quest_step(M), 3, "Nullwächter next")
	await _exit_to("AREA_NOC_CHAMBER")
	await _defeat_spawn("SPAWN_NOC_CHAMBER_WAECHTER")
	eq(Conditions.quest_step(M), 4, "Hüter next")
	await _exit_to("AREA_NOC_CORE")
	await _boss_intro("TRIGGER_NOC_HUETER_INTRO", "CUT_NOC_HUETER_001")
	await _defeat_spawn("SPAWN_NOC_CORE_HUETER")
	eq(Dialogue.active_id, "CUT_NOC_HUETER_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_NOC_CITY", "back in Nocturna")
	await _talk("NPC_ERYN_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 8 completed")
	await _exit_to("AREA_NOC_ARCHIVE")
	await _talk("NPC_NYX_001")
	eq(Conditions.quest_state(S), "COMPLETED", "Noctaris side quest completed")


func _chapter_nine() -> void:
	const M := "QUEST_MAIN_AST_001"
	const S := "QUEST_SIDE_AST_001"
	await _exit_to("AREA_NOC_CITY")
	await _travel("TRAVEL_NOC_001", "WORLD_ASTRALIS", "CUT_AST_ARRIVAL_001")
	eq(game.area.area_id, "AREA_AST_PORT", "in the Wolkenhafen")
	await _exit_to("AREA_AST_GARDEN")
	await _talk("NPC_SORA_001")
	eq(Conditions.quest_step(S), 0, "Astralis side quest started")
	game.shop_menu.close_menu()
	await _exit_to("AREA_AST_PORT")
	await _talk("NPC_AERA_001")
	eq(Conditions.quest_step(M), 1, "find the ruins")
	await _exit_to("AREA_AST_ISLES")
	for id in ["SPAWN_AST_ISLES_SCHWINGE_1", "SPAWN_AST_ISLES_SCHWINGE_2", "SPAWN_AST_ISLES_WAECHTER_1", "SPAWN_AST_ISLES_WAECHTER_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_AST_001"].interact(game.player)
	await _use_savepoint("SAVEPOINT_AST_ISLES_001", 2)
	await _boss_intro("TRIGGER_AST_RUINS", "CUT_AST_RUINS_001")
	await _exit_to("AREA_AST_RUINS")
	eq(Conditions.quest_step(M), 2, "memory puzzle next")
	for id in ["SPAWN_AST_RUINS_SCHWINGE_1", "SPAWN_AST_RUINS_SCHWINGE_2", "SPAWN_AST_RUINS_WAECHTER_1", "SPAWN_AST_RUINS_WAECHTER_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_AST_002"].interact(game.player)
	var node: PuzzleNode = game.area.entities["PUZ_AST_DIALS_001"]
	for i in 4:
		for t in [2, 0, 3, 1][i]:
			node.parts[i].interact(game.player)
	node.parts[4].interact(game.player)
	eq(Conditions.quest_step(M), 3, "Tempelwächter next")
	await _exit_to("AREA_AST_TEMPLE")
	await _defeat_spawn("SPAWN_AST_TEMPLE_WAECHTER")
	eq(Conditions.quest_step(M), 4, "Hüter next")
	await _exit_to("AREA_AST_SUMMIT")
	await _boss_intro("TRIGGER_AST_SOLYRA_INTRO", "CUT_AST_SOLYRA_001")
	await _defeat_spawn("SPAWN_AST_SUMMIT_SOLYRA")
	eq(Dialogue.active_id, "CUT_AST_SOLYRA_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_AST_PORT", "back in the Wolkenhafen")
	await _talk("NPC_AERA_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 9 completed")
	await _exit_to("AREA_AST_GARDEN")
	await _talk("NPC_SORA_001")
	eq(Conditions.quest_state(S), "COMPLETED", "Astralis side quest completed")


func _chapter_ten() -> void:
	const M := "QUEST_MAIN_ELY_001"
	const S := "QUEST_SIDE_ELY_001"
	await _exit_to("AREA_AST_PORT")
	await _travel("TRAVEL_AST_001", "WORLD_ELYNDRA", "CUT_ELY_ARRIVAL_001")
	eq(game.area.area_id, "AREA_ELY_CITY", "in Elyndra")
	await _exit_to("AREA_ELY_QUARTER")
	await _talk("NPC_KAEL_001")
	eq(Conditions.quest_step(S), 0, "Elyndra side quest started")
	game.shop_menu.close_menu()
	await _exit_to("AREA_ELY_CITY")
	await _talk("NPC_VEYRA_001")
	eq(Conditions.quest_step(M), 1, "find the void")
	await _exit_to("AREA_ELY_LAYERS")
	for id in ["SPAWN_ELY_LAYERS_SPINNE_1", "SPAWN_ELY_LAYERS_SPINNE_2", "SPAWN_ELY_LAYERS_KRIEGER_1", "SPAWN_ELY_LAYERS_KRIEGER_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_ELY_001"].interact(game.player)
	await _use_savepoint("SAVEPOINT_ELY_LAYERS_001", 2)
	await _boss_intro("TRIGGER_ELY_VOID", "CUT_ELY_VOID_001")
	await _exit_to("AREA_ELY_VOID")
	eq(Conditions.quest_step(M), 2, "memory puzzle next")
	for id in ["SPAWN_ELY_VOID_SPINNE_1", "SPAWN_ELY_VOID_SPINNE_2", "SPAWN_ELY_VOID_KRIEGER_1", "SPAWN_ELY_VOID_KRIEGER_2"]:
		await _defeat_spawn(id)
	game.area.entities["CHEST_ELY_002"].interact(game.player)
	var node: PuzzleNode = game.area.entities["PUZ_ELY_ECHO_001"]
	for i in [4, 1, 5, 0, 3, 2]:
		node.parts[i].interact(game.player)
	eq(Conditions.quest_step(M), 3, "Tempelwächter next")
	await _exit_to("AREA_ELY_GATE")
	await _defeat_spawn("SPAWN_ELY_GATE_WAECHTER")
	eq(Conditions.quest_step(M), 4, "Hüter next")
	await _exit_to("AREA_ELY_CORE")
	await _boss_intro("TRIGGER_ELY_ELYON_INTRO", "CUT_ELY_ELYON_001")
	await _defeat_spawn("SPAWN_ELY_CORE_ELYON")
	eq(Dialogue.active_id, "CUT_ELY_ELYON_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_ELY_CITY", "back in Elyndra")
	await _talk("NPC_VEYRA_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 10 completed")
	await _exit_to("AREA_ELY_QUARTER")
	await _talk("NPC_KAEL_001")
	eq(Conditions.quest_state(S), "COMPLETED", "Elyndra side quest completed")


## Saved state minus play_time, which keeps counting once the game runs.
func _state_without_clock() -> String:
	var d := GameState.to_dict()
	d.erase("play_time")
	return JSON.stringify(d)


func test_full_playthrough() -> void:
	SaveSystem.save_dir = "user://playthrough_saves/"
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	Dialogue.reset()
	GameState.reset_new_game()
	await _chapter_one()
	await _chapter_two()
	await _chapter_three()
	await _chapter_four()
	await _chapter_five()
	await _chapter_six()
	await _chapter_seven()
	await _chapter_eight()
	await _chapter_nine()
	await _chapter_ten()
	for q in ["QUEST_MAIN_LUN_001", "QUEST_SIDE_LUN_001", "QUEST_MAIN_ELA_001", "QUEST_SIDE_ELA_001", "QUEST_MAIN_VAL_001", "QUEST_SIDE_VAL_001", "QUEST_MAIN_SOL_001", "QUEST_SIDE_SOL_001", "QUEST_MAIN_AQU_001", "QUEST_SIDE_AQU_001", "QUEST_MAIN_FRO_001", "QUEST_SIDE_FRO_001", "QUEST_MAIN_IGN_001", "QUEST_SIDE_IGN_001", "QUEST_MAIN_NOC_001", "QUEST_SIDE_NOC_001", "QUEST_MAIN_AST_001", "QUEST_SIDE_AST_001", "QUEST_MAIN_ELY_001", "QUEST_SIDE_ELY_001"]:
		eq(Conditions.quest_state(q), "COMPLETED", q)
	eq(GameState.party.size(), 3, "full party at the end")
	# Save -> fresh state -> load through the title
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "final save")
	var expected := _state_without_clock()
	GameState.reset_new_game()
	App.goto_scene(App.SCENE_TITLE)
	await frames(3)
	tree.current_scene.buttons["load_1"].pressed.emit()
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)
	eq(game.area.area_id, "AREA_ELY_QUARTER", "loaded where the game was saved")
	eq(game.companions.size(), 3, "party restored")
	eq(_state_without_clock(), expected, "state survives save/load")
	SaveSystem.save_dir = "user://saves/"
