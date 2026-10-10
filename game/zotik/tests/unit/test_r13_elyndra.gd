extends TestCase
## R09: chapter-8 quests and the boss Elyon (Elyndra).

const MQ := "QUEST_MAIN_ELY_001"
const SQ := "QUEST_SIDE_ELY_001"
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
	for f in ["FLAG_AST_CHAPTER_COMPLETE"]:
		GameState.set_flag(f)


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _boss() -> Boss:
	for f in ["FLAG_ELY_ARRIVED", "FLAG_ELY_LAYERS_OPEN", "FLAG_ELY_VOID_OPEN", "FLAG_ELY_ECHO_DONE", "FLAG_ELY_WAECHTER_DEFEATED", "FLAG_ELY_ELYON_MET"]:
		GameState.set_flag(f)
	game.enter_area("AREA_ELY_CORE", "default")
	await physics_frames(2)
	return game.area.entities["SPAWN_ELY_CORE_ELYON"]


func test_arrival_starts_the_main_quest() -> void:
	game.enter_area("AREA_ELY_CITY", "travel")
	await physics_frames(3)
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 0, "quest active: talk to Veyra")
	eq(Quests.objective(MQ), "Sprich mit Veyra in Elyndra.", "objective")


func test_eryn_starts_the_quest_for_older_saves() -> void:
	GameState.set_flag("FLAG_ELY_ARRIVED")
	game.enter_area("AREA_ELY_CITY", "default")
	await physics_frames(2)
	eq(Conditions.quest_state(MQ), "INACTIVE", "no quest yet")
	Dialogue.talk_to("NPC_VEYRA_001")
	await finish_dialogues()
	check(Conditions.quest_state(MQ) != "INACTIVE", "quest started")
	check(GameState.has_flag("FLAG_ELY_LAYERS_OPEN"), "lanes open")


func test_main_quest_flow_to_the_heart() -> void:
	game.enter_area("AREA_ELY_CITY", "travel")
	await physics_frames(3)
	await finish_dialogues()
	Dialogue.talk_to("NPC_VEYRA_001")
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 1, "find the ruins")
	GameState.set_flag("FLAG_ELY_VOID_OPEN")
	game.enter_area("AREA_ELY_VOID", "AREA_ELY_LAYERS")
	await physics_frames(2)
	eq(Conditions.quest_step(MQ), 2, "dials next")
	GameState.set_flag("FLAG_ELY_ECHO_DONE")
	GameState.quests[MQ].step = 3
	game.enter_area("AREA_ELY_GATE", "AREA_ELY_VOID")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_ELY_CORE"), "core closed while the guardian stands")
	game.area.entities["SPAWN_ELY_GATE_WAECHTER"].take_hit(99999)
	eq(Conditions.quest_step(MQ), 4, "Elyon next")
	check(game.area.is_exit_open("AREA_ELY_CORE"), "core open")


func test_solyra_intro_plays_once() -> void:
	for f in ["FLAG_ELY_ARRIVED", "FLAG_ELY_WAECHTER_DEFEATED"]:
		GameState.set_flag(f)
	game.enter_area("AREA_ELY_CORE", "default")
	await physics_frames(2)
	var trig: Node3D = game.area.entities["TRIGGER_ELY_ELYON_INTRO"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_ELY_ELYON_001", "boss intro")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_ELY_ELYON_MET"), "remembered")


func test_boss_phases_and_summons() -> void:
	var boss := await _boss()
	eq(boss.max_hp, 1450, "boss hp")
	eq(boss.data.phases.size(), 4, "four phases")
	boss.take_hit(460)
	eq(boss.phase, 1, "Erinnerungsbruch below 70%")
	eq(boss.summons.size(), 2, "two Echokrieger")
	boss.take_hit(380)
	eq(boss.phase, 2, "Teilung below 45%")
	eq(boss.summons.size(), 4, "plus two Spiegelspinnen")
	boss.take_hit(380)
	eq(boss.phase, 3, "Weltenkern below 20%")
	eq(boss.summons.size(), 5, "plus an Echokrieger")
	boss.take_hit(10, 400.0)
	check(boss.is_broken(), "boss can be broken")
	eq(boss.data.phases[1].hazard.kind, "surge", "memory surge from phase 2")


func test_defeat_completes_the_chapter() -> void:
	var boss := await _boss()
	Quests.start(MQ)
	GameState.quests[MQ].step = 4
	boss.take_hit(460)
	var adds := boss.summons.duplicate()
	boss.take_hit(9999)
	check(GameState.has_flag("FLAG_BOSS_ELY_ELYON_DEFEATED"), "boss flag")
	eq(Conditions.quest_step(MQ), 5, "report to Veyra")
	eq(Dialogue.active_id, "CUT_ELY_ELYON_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_ELY_CITY", "back in the village")
	check(adds.all(func(a): return not is_instance_valid(a)), "summons removed")
	eq(Guild.kills("BOSS_ELYON_001"), 1, "bestiary")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_VEYRA_001")
	eq(Dialogue.active_id, "DLG_VEYRA_REPORT_001", "Veyra's report")
	await finish_dialogues()
	eq(Conditions.quest_state(MQ), "COMPLETED", "chapter 10 done")
	check(GameState.has_flag("FLAG_ELY_CHAPTER_COMPLETE"), "chapter flag")
	check(GameState.has_flag("FLAG_GAME_COMPLETE"), "story complete")
	eq(GameState.currency, lun + 900, "reward")
	eq(Dialogue.select_for_npc("NPC_VEYRA_001"), "DLG_VEYRA_ENDING_ASK_001", "after the report Veyra asks for the ending until it is chosen (W20)")
	GameState.set_flag("FLAG_ENDING_CHOSEN")
	GameState.set_flag("FLAG_ENDING_SEPARATE")
	eq(Dialogue.select_for_npc("NPC_VEYRA_001"), "DLG_VEYRA_AFTER_SEPARATE_001", "then she follows the chosen ending")


func test_boss_stays_defeated_after_reload() -> void:
	var boss := await _boss()
	boss.take_hit(9999)
	await finish_dialogues()
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "save")
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "load")
	game.enter_area("AREA_ELY_CORE", "AREA_ELY_GATE")
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_ELY_CORE_ELYON"), "Elyon stays defeated")


func test_side_quest_nyx() -> void:
	GameState.set_flag("FLAG_ELY_ARRIVED")
	game.enter_area("AREA_ELY_QUARTER", "default")
	await physics_frames(2)
	eq(Dialogue.select_for_npc("NPC_KAEL_001"), "DLG_KAEL_QUEST_001", "offer")
	Dialogue.talk_to("NPC_KAEL_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "shop opens with the offer")
	game.shop_menu.close_menu()
	eq(Conditions.quest_step(SQ), 0, "collect splitters")
	Inventory.add("ITEM_ECHO_001", 5)
	eq(Conditions.quest_step(SQ), 1, "enough splitters: bring them to Kael")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_KAEL_001")
	eq(Dialogue.active_id, "DLG_KAEL_THANKS_001", "thanks")
	await finish_dialogues()
	eq(Conditions.quest_state(SQ), "COMPLETED", "side quest done")
	eq(Inventory.count("ITEM_ECHO_001"), 0, "splitters handed over")
	eq(GameState.currency, lun + 350, "reward")
	eq(Inventory.count("ITEM_ELIXIR_001"), 2, "elixirs")
