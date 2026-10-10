extends TestCase
## Q04: chapter-5 quests and the boss Neryx.

const MQ := "QUEST_MAIN_AQU_001"
const SQ := "QUEST_SIDE_AQU_001"
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
	for f in ["FLAG_SOL_CHAPTER_COMPLETE"]:
		GameState.set_flag(f)


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _boss() -> Boss:
	for f in ["FLAG_AQU_ARRIVED", "FLAG_AQU_CAVES_OPEN", "FLAG_AQU_ARCHIVE_OPEN", "FLAG_AQU_CURRENT_DONE", "FLAG_AQU_WAECHTER_DEFEATED", "FLAG_AQU_NERYX_MET"]:
		GameState.set_flag(f)
	game.enter_area("AREA_AQU_ABYSS", "default")
	await physics_frames(2)
	return game.area.entities["SPAWN_AQU_ABYSS_NERYX"]


func test_arrival_starts_the_main_quest() -> void:
	game.enter_area("AREA_AQU_DOME", "travel")
	await physics_frames(3)
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 0, "quest active: talk to Nerea")
	eq(Quests.objective(MQ), "Sprich mit Nerea am Korallentor.", "objective")


func test_mirael_starts_the_quest_for_older_saves() -> void:
	GameState.set_flag("FLAG_AQU_ARRIVED")
	game.enter_area("AREA_AQU_DOME", "default")
	await physics_frames(2)
	eq(Conditions.quest_state(MQ), "INACTIVE", "no quest yet")
	Dialogue.talk_to("NPC_MIRAEL_001")
	await finish_dialogues()
	check(Conditions.quest_state(MQ) != "INACTIVE", "quest started")
	check(GameState.has_flag("FLAG_AQU_CAVES_OPEN"), "caves open")


func test_main_quest_flow_to_the_abyss() -> void:
	game.enter_area("AREA_AQU_DOME", "travel")
	await physics_frames(3)
	await finish_dialogues()
	Dialogue.talk_to("NPC_MIRAEL_001")
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 1, "find the archive")
	GameState.set_flag("FLAG_AQU_ARCHIVE_OPEN")
	game.enter_area("AREA_AQU_ARCHIVE", "AREA_AQU_CAVES")
	await physics_frames(2)
	eq(Conditions.quest_step(MQ), 2, "currents next")
	GameState.set_flag("FLAG_AQU_CURRENT_DONE")
	GameState.quests[MQ].step = 3
	game.enter_area("AREA_AQU_VAULT", "AREA_AQU_ARCHIVE")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_AQU_ABYSS"), "abyss closed while the guardian stands")
	game.area.entities["SPAWN_AQU_VAULT_WAECHTER"].take_hit(99999)
	eq(Conditions.quest_step(MQ), 4, "Neryx next")
	check(game.area.is_exit_open("AREA_AQU_ABYSS"), "abyss open")


func test_neryx_intro_plays_once() -> void:
	for f in ["FLAG_AQU_ARRIVED", "FLAG_AQU_WAECHTER_DEFEATED"]:
		GameState.set_flag(f)
	game.enter_area("AREA_AQU_ABYSS", "default")
	await physics_frames(2)
	var trig: Node3D = game.area.entities["TRIGGER_AQU_NERYX_INTRO"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_AQU_NERYX_001", "boss intro")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_AQU_NERYX_MET"), "remembered")


func test_boss_phases_and_summons() -> void:
	var boss := await _boss()
	eq(boss.max_hp, 860, "boss hp")
	eq(boss.data.phases.size(), 3, "three phases")
	boss.take_hit(360)
	eq(boss.phase, 1, "Strudel below 60%")
	eq(boss.summons.size(), 2, "two Leuchtquallen")
	boss.take_hit(260)
	eq(boss.phase, 2, "Tiefendruck below 30%")
	eq(boss.summons.size(), 3, "plus a Riffkrabbe")
	boss.take_hit(10, 400.0)
	check(boss.is_broken(), "boss can be broken")
	eq(boss.data.phases[1].hazard.kind, "surge", "whirl surge from phase 2")


func test_defeat_completes_the_chapter() -> void:
	var boss := await _boss()
	Quests.start(MQ)
	GameState.quests[MQ].step = 4
	boss.take_hit(360)
	var adds := boss.summons.duplicate()
	boss.take_hit(9999)
	check(GameState.has_flag("FLAG_BOSS_AQU_NERYX_DEFEATED"), "boss flag")
	eq(Conditions.quest_step(MQ), 5, "report to Nerea")
	eq(Dialogue.active_id, "CUT_AQU_NERYX_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_AQU_DOME", "back in the dome")
	check(adds.all(func(a): return not is_instance_valid(a)), "summons removed")
	eq(Guild.kills("BOSS_NERYX_001"), 1, "bestiary")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_MIRAEL_001")
	eq(Dialogue.active_id, "DLG_MIRAEL_REPORT_001", "Nerea's report")
	await finish_dialogues()
	eq(Conditions.quest_state(MQ), "COMPLETED", "chapter 5 done")
	check(GameState.has_flag("FLAG_AQU_CHAPTER_COMPLETE"), "chapter flag")
	eq(GameState.currency, lun + 450, "reward")
	eq(Dialogue.select_for_npc("NPC_MIRAEL_001"), "DLG_MIRAEL_AFTER_001", "after dialogue")


func test_boss_stays_defeated_after_reload() -> void:
	var boss := await _boss()
	boss.take_hit(9999)
	await finish_dialogues()
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "save")
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "load")
	game.enter_area("AREA_AQU_ABYSS", "AREA_AQU_VAULT")
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_AQU_ABYSS_NERYX"), "Neryx stays defeated")


func test_side_quest_perla() -> void:
	GameState.set_flag("FLAG_AQU_ARRIVED")
	game.enter_area("AREA_AQU_HARBOUR", "default")
	await physics_frames(2)
	eq(Dialogue.select_for_npc("NPC_PERLA_001"), "DLG_PERLA_QUEST_001", "offer")
	Dialogue.talk_to("NPC_PERLA_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "shop opens with the offer")
	game.shop_menu.close_menu()
	eq(Conditions.quest_step(SQ), 0, "collect pearls")
	Inventory.add("ITEM_PEARL_001", 5)
	eq(Conditions.quest_step(SQ), 1, "enough pearls: bring them to Perla")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_PERLA_001")
	eq(Dialogue.active_id, "DLG_PERLA_THANKS_001", "thanks")
	await finish_dialogues()
	eq(Conditions.quest_state(SQ), "COMPLETED", "side quest done")
	eq(Inventory.count("ITEM_PEARL_001"), 0, "pearls handed over")
	eq(GameState.currency, lun + 220, "reward")
	eq(Inventory.count("ITEM_ELIXIR_001"), 1, "elixir")
