extends TestCase
## R09: chapter-8 quests and the boss Solyra (Astralis).

const MQ := "QUEST_MAIN_AST_001"
const SQ := "QUEST_SIDE_AST_001"
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
	for f in ["FLAG_NOC_CHAPTER_COMPLETE"]:
		GameState.set_flag(f)


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _boss() -> Boss:
	for f in ["FLAG_AST_ARRIVED", "FLAG_AST_ISLES_OPEN", "FLAG_AST_RUINS_OPEN", "FLAG_AST_DIALS_DONE", "FLAG_AST_WAECHTER_DEFEATED", "FLAG_AST_SOLYRA_MET"]:
		GameState.set_flag(f)
	game.enter_area("AREA_AST_SUMMIT", "default")
	await physics_frames(2)
	return game.area.entities["SPAWN_AST_SUMMIT_SOLYRA"]


func test_arrival_starts_the_main_quest() -> void:
	game.enter_area("AREA_AST_PORT", "travel")
	await physics_frames(3)
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 0, "quest active: talk to Aera")
	eq(Quests.objective(MQ), "Sprich mit Aera im Wolkenhafen.", "objective")


func test_eryn_starts_the_quest_for_older_saves() -> void:
	GameState.set_flag("FLAG_AST_ARRIVED")
	game.enter_area("AREA_AST_PORT", "default")
	await physics_frames(2)
	eq(Conditions.quest_state(MQ), "INACTIVE", "no quest yet")
	Dialogue.talk_to("NPC_AERA_001")
	await finish_dialogues()
	check(Conditions.quest_state(MQ) != "INACTIVE", "quest started")
	check(GameState.has_flag("FLAG_AST_ISLES_OPEN"), "lanes open")


func test_main_quest_flow_to_the_heart() -> void:
	game.enter_area("AREA_AST_PORT", "travel")
	await physics_frames(3)
	await finish_dialogues()
	Dialogue.talk_to("NPC_AERA_001")
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 1, "find the ruins")
	GameState.set_flag("FLAG_AST_RUINS_OPEN")
	game.enter_area("AREA_AST_RUINS", "AREA_AST_ISLES")
	await physics_frames(2)
	eq(Conditions.quest_step(MQ), 2, "dials next")
	GameState.set_flag("FLAG_AST_DIALS_DONE")
	GameState.quests[MQ].step = 3
	game.enter_area("AREA_AST_TEMPLE", "AREA_AST_RUINS")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_AST_SUMMIT"), "core closed while the guardian stands")
	game.area.entities["SPAWN_AST_TEMPLE_WAECHTER"].take_hit(99999)
	eq(Conditions.quest_step(MQ), 4, "Solyra next")
	check(game.area.is_exit_open("AREA_AST_SUMMIT"), "core open")


func test_solyra_intro_plays_once() -> void:
	for f in ["FLAG_AST_ARRIVED", "FLAG_AST_WAECHTER_DEFEATED"]:
		GameState.set_flag(f)
	game.enter_area("AREA_AST_SUMMIT", "default")
	await physics_frames(2)
	var trig: Node3D = game.area.entities["TRIGGER_AST_SOLYRA_INTRO"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_AST_SOLYRA_001", "boss intro")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_AST_SOLYRA_MET"), "remembered")


func test_boss_phases_and_summons() -> void:
	var boss := await _boss()
	eq(boss.max_hp, 1250, "boss hp")
	eq(boss.data.phases.size(), 3, "three phases")
	boss.take_hit(520)
	eq(boss.phase, 1, "Sternschnuppenregen below 60%")
	eq(boss.summons.size(), 2, "two Wolkenschwingen")
	boss.take_hit(400)
	eq(boss.phase, 2, "Verschobene Sterne below 30%")
	eq(boss.summons.size(), 3, "plus a Sternenwächter")
	boss.take_hit(10, 400.0)
	check(boss.is_broken(), "boss can be broken")
	eq(boss.data.phases[1].hazard.kind, "surge", "memory surge from phase 2")


func test_defeat_completes_the_chapter() -> void:
	var boss := await _boss()
	Quests.start(MQ)
	GameState.quests[MQ].step = 4
	boss.take_hit(520)
	var adds := boss.summons.duplicate()
	boss.take_hit(9999)
	check(GameState.has_flag("FLAG_BOSS_AST_SOLYRA_DEFEATED"), "boss flag")
	eq(Conditions.quest_step(MQ), 5, "report to Aera")
	eq(Dialogue.active_id, "CUT_AST_SOLYRA_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_AST_PORT", "back in the village")
	check(adds.all(func(a): return not is_instance_valid(a)), "summons removed")
	eq(Guild.kills("BOSS_SOLYRA_001"), 1, "bestiary")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_AERA_001")
	eq(Dialogue.active_id, "DLG_AERA_REPORT_001", "Aera's report")
	await finish_dialogues()
	eq(Conditions.quest_state(MQ), "COMPLETED", "chapter 9 done")
	check(GameState.has_flag("FLAG_AST_CHAPTER_COMPLETE"), "chapter flag")
	eq(GameState.currency, lun + 650, "reward")
	eq(Dialogue.select_for_npc("NPC_AERA_001"), "DLG_AERA_AFTER_001", "after dialogue")


func test_boss_stays_defeated_after_reload() -> void:
	var boss := await _boss()
	boss.take_hit(9999)
	await finish_dialogues()
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "save")
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "load")
	game.enter_area("AREA_AST_SUMMIT", "AREA_AST_TEMPLE")
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_AST_SUMMIT_SOLYRA"), "Solyra stays defeated")


func test_side_quest_nyx() -> void:
	GameState.set_flag("FLAG_AST_ARRIVED")
	game.enter_area("AREA_AST_GARDEN", "default")
	await physics_frames(2)
	eq(Dialogue.select_for_npc("NPC_SORA_001"), "DLG_SORA_QUEST_001", "offer")
	Dialogue.talk_to("NPC_SORA_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "shop opens with the offer")
	game.shop_menu.close_menu()
	eq(Conditions.quest_step(SQ), 0, "collect splitters")
	Inventory.add("ITEM_STARDUST_001", 5)
	eq(Conditions.quest_step(SQ), 1, "enough splitters: bring them to Sora")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_SORA_001")
	eq(Dialogue.active_id, "DLG_SORA_THANKS_001", "thanks")
	await finish_dialogues()
	eq(Conditions.quest_state(SQ), "COMPLETED", "side quest done")
	eq(Inventory.count("ITEM_STARDUST_001"), 0, "splitters handed over")
	eq(GameState.currency, lun + 320, "reward")
	eq(Inventory.count("ITEM_ELIXIR_001"), 1, "elixir")
