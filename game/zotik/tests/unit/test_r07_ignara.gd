extends TestCase
## R07: chapter-7 quests and the boss Magmarion (Ignara).

const MQ := "QUEST_MAIN_IGN_001"
const SQ := "QUEST_SIDE_IGN_001"
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
	for f in ["FLAG_IGN_CHAPTER_COMPLETE"]:
		GameState.set_flag(f)


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _boss() -> Boss:
	for f in ["FLAG_IGN_ARRIVED", "FLAG_IGN_ASH_OPEN", "FLAG_IGN_MINES_OPEN", "FLAG_IGN_VALVES_DONE", "FLAG_IGN_WAECHTER_DEFEATED", "FLAG_IGN_MAGMARION_MET"]:
		GameState.set_flag(f)
	game.enter_area("AREA_IGN_HEART", "default")
	await physics_frames(2)
	return game.area.entities["SPAWN_IGN_HEART_MAGMARION"]


func test_arrival_starts_the_main_quest() -> void:
	game.enter_area("AREA_IGN_VILLAGE", "travel")
	await physics_frames(3)
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 0, "quest active: talk to Brenna")
	eq(Quests.objective(MQ), "Sprich mit Brenna in Kaldera.", "objective")


func test_brenna_starts_the_quest_for_older_saves() -> void:
	GameState.set_flag("FLAG_IGN_ARRIVED")
	game.enter_area("AREA_IGN_VILLAGE", "default")
	await physics_frames(2)
	eq(Conditions.quest_state(MQ), "INACTIVE", "no quest yet")
	Dialogue.talk_to("NPC_BRENNA_001")
	await finish_dialogues()
	check(Conditions.quest_state(MQ) != "INACTIVE", "quest started")
	check(GameState.has_flag("FLAG_IGN_ASH_OPEN"), "caves open")


func test_main_quest_flow_to_the_heart() -> void:
	game.enter_area("AREA_IGN_VILLAGE", "travel")
	await physics_frames(3)
	await finish_dialogues()
	Dialogue.talk_to("NPC_BRENNA_001")
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 1, "find the mines")
	GameState.set_flag("FLAG_IGN_MINES_OPEN")
	game.enter_area("AREA_IGN_MINES", "AREA_IGN_ASH")
	await physics_frames(2)
	eq(Conditions.quest_step(MQ), 2, "valves next")
	GameState.set_flag("FLAG_IGN_VALVES_DONE")
	GameState.quests[MQ].step = 3
	game.enter_area("AREA_IGN_CHAMBER", "AREA_IGN_MINES")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_IGN_HEART"), "core closed while the guardian stands")
	game.area.entities["SPAWN_IGN_CHAMBER_WAECHTER"].take_hit(99999)
	eq(Conditions.quest_step(MQ), 4, "Magmarion next")
	check(game.area.is_exit_open("AREA_IGN_HEART"), "core open")


func test_magmarion_intro_plays_once() -> void:
	for f in ["FLAG_IGN_ARRIVED", "FLAG_IGN_WAECHTER_DEFEATED"]:
		GameState.set_flag(f)
	game.enter_area("AREA_IGN_HEART", "default")
	await physics_frames(2)
	var trig: Node3D = game.area.entities["TRIGGER_IGN_MAGMARION_INTRO"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_IGN_MAGMARION_001", "boss intro")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_IGN_MAGMARION_MET"), "remembered")


func test_boss_phases_and_summons() -> void:
	var boss := await _boss()
	eq(boss.max_hp, 1060, "boss hp")
	eq(boss.data.phases.size(), 3, "three phases")
	boss.take_hit(450)
	eq(boss.phase, 1, "Lavawelle below 60%")
	eq(boss.summons.size(), 2, "two Funkengeister")
	boss.take_hit(320)
	eq(boss.phase, 2, "Vulkanausbruch below 30%")
	eq(boss.summons.size(), 3, "plus an Aschekäfer")
	boss.take_hit(10, 400.0)
	check(boss.is_broken(), "boss can be broken")
	eq(boss.data.phases[1].hazard.kind, "surge", "lava surge from phase 2")


func test_defeat_completes_the_chapter() -> void:
	var boss := await _boss()
	Quests.start(MQ)
	GameState.quests[MQ].step = 4
	boss.take_hit(450)
	var adds := boss.summons.duplicate()
	boss.take_hit(9999)
	check(GameState.has_flag("FLAG_BOSS_IGN_MAGMARION_DEFEATED"), "boss flag")
	eq(Conditions.quest_step(MQ), 5, "report to Brenna")
	eq(Dialogue.active_id, "CUT_IGN_MAGMARION_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_IGN_VILLAGE", "back in the village")
	check(adds.all(func(a): return not is_instance_valid(a)), "summons removed")
	eq(Guild.kills("BOSS_MAGMARION_001"), 1, "bestiary")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_BRENNA_001")
	eq(Dialogue.active_id, "DLG_BRENNA_REPORT_001", "Brenna's report")
	await finish_dialogues()
	eq(Conditions.quest_state(MQ), "COMPLETED", "chapter 6 done")
	check(GameState.has_flag("FLAG_IGN_CHAPTER_COMPLETE"), "chapter flag")
	eq(GameState.currency, lun + 550, "reward")
	eq(Dialogue.select_for_npc("NPC_BRENNA_001"), "DLG_BRENNA_AFTER_001", "after dialogue")


func test_boss_stays_defeated_after_reload() -> void:
	var boss := await _boss()
	boss.take_hit(9999)
	await finish_dialogues()
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "save")
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "load")
	game.enter_area("AREA_IGN_HEART", "AREA_IGN_CHAMBER")
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_IGN_HEART_MAGMARION"), "Magmarion stays defeated")


func test_side_quest_varek() -> void:
	GameState.set_flag("FLAG_IGN_ARRIVED")
	game.enter_area("AREA_IGN_FORGE", "default")
	await physics_frames(2)
	eq(Dialogue.select_for_npc("NPC_VAREK_001"), "DLG_VAREK_QUEST_001", "offer")
	Dialogue.talk_to("NPC_VAREK_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "shop opens with the offer")
	game.shop_menu.close_menu()
	eq(Conditions.quest_step(SQ), 0, "collect embers")
	Inventory.add("ITEM_EMBER_001", 5)
	eq(Conditions.quest_step(SQ), 1, "enough embers: bring them to Varek")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_VAREK_001")
	eq(Dialogue.active_id, "DLG_VAREK_THANKS_001", "thanks")
	await finish_dialogues()
	eq(Conditions.quest_state(SQ), "COMPLETED", "side quest done")
	eq(Inventory.count("ITEM_EMBER_001"), 0, "embers handed over")
	eq(GameState.currency, lun + 260, "reward")
	eq(Inventory.count("ITEM_ELIXIR_001"), 1, "elixir")
