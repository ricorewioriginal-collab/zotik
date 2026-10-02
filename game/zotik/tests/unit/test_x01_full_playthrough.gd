extends TestCase
## X01: the whole game in one session, without prepared saves. New game from
## the title, chapter 1 in Lunaris, Weltenstein to Elaris, chapter 2,
## Weltenstein to Valdoria, chapter 3, then save -> reset -> load through the
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
	for q in ["QUEST_MAIN_LUN_001", "QUEST_SIDE_LUN_001", "QUEST_MAIN_ELA_001", "QUEST_SIDE_ELA_001", "QUEST_MAIN_VAL_001", "QUEST_SIDE_VAL_001"]:
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
	eq(game.area.area_id, "AREA_VAL_GUILD", "loaded where the game was saved")
	eq(game.companions.size(), 3, "party restored")
	eq(_state_without_clock(), expected, "state survives save/load")
	SaveSystem.save_dir = "user://saves/"
