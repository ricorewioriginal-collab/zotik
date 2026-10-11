extends TestCase

const M := "QUEST_MAIN_ELA_001"
const S := "QUEST_SIDE_ELA_001"
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
	GameState.quests["QUEST_MAIN_LUN_001"] = {"state": "COMPLETED", "step": 13, "progress": 0}
	for f in ["FLAG_LUN_CHAPTER_COMPLETE", "FLAG_LUN_LYRA_MET"]:
		GameState.set_flag(f)
	game.enter_area("AREA_ELA_TOWN", "travel")
	await physics_frames(4)
	await finish_dialogues()


func _talk(npc: String) -> void:
	var n: Npc = game.area.entities[npc]
	n.interact(game.player)
	await finish_dialogues()


func test_arrival_starts_chapter_two() -> void:
	eq(Conditions.quest_step(M), 0, "main quest started by arrival")
	check("PARTY_LYRA_001" in GameState.party, "Lyra joined")
	check(game.hud.objective_label.text.contains("Mara"), "objective shown")
	eq(game.beacon_target, "NPC_MARA_001", "beacon on Mara")


func test_full_chapter_two_main_quest() -> void:
	await _talk("NPC_MARA_001")
	check(game.area.is_exit_open("AREA_ELA_FOREST"), "forest open")
	await _talk("NPC_NIA_001")
	check("PARTY_NIA_001" in GameState.party and game.companions.has("PARTY_NIA_001"), "Nia joined")
	check(not game.area.entities["NPC_NIA_001"].visible, "Nia NPC hidden while in party")
	game.enter_area("AREA_ELA_FOREST", "AREA_ELA_TOWN")
	await physics_frames(2)
	eq(Conditions.quest_step(M), 3, "in forest")
	for i in 3:
		EventBus.enemy_defeated.emit("ENEMY_PILZLING_001")
	await _talk("NPC_ROVAN_001")
	eq(GameState.party.size(), 3, "Lyra, Nia, Rovan")
	game.enter_area("AREA_ELA_TOWER", "AREA_ELA_FOREST")
	await physics_frames(2)
	eq(Conditions.quest_step(M), 6, "at tower puzzle")
	for n in [1, 3, 2, 0]:
		PuzzleLogic.strike("PUZ_ELA_TURM_001", n)
	await finish_dialogues()
	EventBus.savepoint_used.emit("SAVEPOINT_ELA_001")
	EventBus.enemy_defeated.emit("ENEMY_WURZELKRIECHER_001")
	EventBus.enemy_defeated.emit("BOSS_WURZELKOENIGIN_001")
	eq(Conditions.quest_step(M), 10, "return to Mara")
	game.enter_area("AREA_ELA_TOWN", "AREA_ELA_FOREST")
	await physics_frames(2)
	var done := [false]
	game.chapter_complete.connect(func(): done[0] = true)
	var lun := GameState.currency
	await _talk("NPC_MARA_001")
	eq(Conditions.quest_state(M), "COMPLETED", "chapter 2 complete")
	check(done[0], "chapter end notice")
	eq(GameState.currency, lun + 200, "reward")
	check(GameState.has_flag("FLAG_ELA_CHAPTER_COMPLETE"), "chapter flag")


func test_rovan_cannot_join_early() -> void:
	game.enter_area("AREA_ELA_FOREST", "default")
	await physics_frames(2)
	await _talk("NPC_ROVAN_001")
	check(not "PARTY_ROVAN_001" in GameState.party, "no join before his quest step")
	eq(Conditions.quest_step(M), 0, "quest unchanged")


func test_sela_side_quest() -> void:
	await _talk("NPC_SELA_001")
	eq(Conditions.quest_step(S), 0, "side quest started")
	Inventory.add("ITEM_SPORE_001", 4)
	eq(Conditions.quest_step(S), 0, "4 spores are not enough")
	Inventory.add("ITEM_SPORE_001", 1)
	eq(Conditions.quest_step(S), 1, "5 spores")
	var lun := GameState.currency
	await _talk("NPC_SELA_001")
	eq(Conditions.quest_state(S), "COMPLETED", "done")
	eq(Inventory.count("ITEM_SPORE_001"), 0, "spores handed over")
	eq(Inventory.count("ITEM_HI_POTION_001"), 2, "reward potions")
	eq(GameState.currency, lun + 90, "reward Lun")


func test_main_quest_listed_before_side_quest() -> void:
	await _talk("NPC_SELA_001")
	eq(Quests.active_quests(), [M, S], "main first")
	eq(Navigator.guided_quest(), M, "beacon follows the main quest")
