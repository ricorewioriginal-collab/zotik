extends TestCase
## R05: chapter-6 quests and the boss Avarn (Frosthain).

const MQ := "QUEST_MAIN_FRO_001"
const SQ := "QUEST_SIDE_FRO_001"
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
	for f in ["FLAG_FRO_CHAPTER_COMPLETE"]:
		GameState.set_flag(f)


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _boss() -> Boss:
	for f in ["FLAG_FRO_ARRIVED", "FLAG_FRO_FOREST_OPEN", "FLAG_FRO_CITY_OPEN", "FLAG_FRO_ICE_DONE", "FLAG_FRO_WAECHTER_DEFEATED", "FLAG_FRO_AVARN_MET"]:
		GameState.set_flag(f)
	game.enter_area("AREA_FRO_CORE", "default")
	await physics_frames(2)
	return game.area.entities["SPAWN_FRO_CORE_AVARN"]


func test_arrival_starts_the_main_quest() -> void:
	game.enter_area("AREA_FRO_VILLAGE", "travel")
	await physics_frames(3)
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 0, "quest active: talk to Falk")
	eq(Quests.objective(MQ), "Sprich mit Falk im Dorf Hjalm.", "objective")


func test_kaelen_starts_the_quest_for_older_saves() -> void:
	GameState.set_flag("FLAG_FRO_ARRIVED")
	game.enter_area("AREA_FRO_VILLAGE", "default")
	await physics_frames(2)
	eq(Conditions.quest_state(MQ), "INACTIVE", "no quest yet")
	Dialogue.talk_to("NPC_KAELEN_001")
	await finish_dialogues()
	check(Conditions.quest_state(MQ) != "INACTIVE", "quest started")
	check(GameState.has_flag("FLAG_FRO_FOREST_OPEN"), "caves open")


func test_main_quest_flow_to_the_core() -> void:
	game.enter_area("AREA_FRO_VILLAGE", "travel")
	await physics_frames(3)
	await finish_dialogues()
	Dialogue.talk_to("NPC_KAELEN_001")
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 1, "find the city")
	GameState.set_flag("FLAG_FRO_CITY_OPEN")
	game.enter_area("AREA_FRO_CITY", "AREA_FRO_FOREST")
	await physics_frames(2)
	eq(Conditions.quest_step(MQ), 2, "ice next")
	GameState.set_flag("FLAG_FRO_ICE_DONE")
	GameState.quests[MQ].step = 3
	game.enter_area("AREA_FRO_TEMPLE", "AREA_FRO_CITY")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_FRO_CORE"), "core closed while the guardian stands")
	game.area.entities["SPAWN_FRO_TEMPLE_WAECHTER"].take_hit(99999)
	eq(Conditions.quest_step(MQ), 4, "Avarn next")
	check(game.area.is_exit_open("AREA_FRO_CORE"), "core open")


func test_avarn_intro_plays_once() -> void:
	for f in ["FLAG_FRO_ARRIVED", "FLAG_FRO_WAECHTER_DEFEATED"]:
		GameState.set_flag(f)
	game.enter_area("AREA_FRO_CORE", "default")
	await physics_frames(2)
	var trig: Node3D = game.area.entities["TRIGGER_FRO_AVARN_INTRO"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_FRO_AVARN_001", "boss intro")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_FRO_AVARN_MET"), "remembered")


func test_boss_phases_and_summons() -> void:
	var boss := await _boss()
	eq(boss.max_hp, 980, "boss hp")
	eq(boss.data.phases.size(), 3, "three phases")
	boss.take_hit(420)
	eq(boss.phase, 1, "Schneesturm below 60%")
	eq(boss.summons.size(), 2, "two Eisgeister")
	boss.take_hit(300)
	eq(boss.phase, 2, "Erstarrung below 30%")
	eq(boss.summons.size(), 3, "plus a Frostwolf")
	boss.take_hit(10, 400.0)
	check(boss.is_broken(), "boss can be broken")
	eq(boss.data.phases[1].hazard.kind, "surge", "ice surge from phase 2")


func test_defeat_completes_the_chapter() -> void:
	var boss := await _boss()
	Quests.start(MQ)
	GameState.quests[MQ].step = 4
	boss.take_hit(420)
	var adds := boss.summons.duplicate()
	boss.take_hit(9999)
	check(GameState.has_flag("FLAG_BOSS_FRO_AVARN_DEFEATED"), "boss flag")
	eq(Conditions.quest_step(MQ), 5, "report to Falk")
	eq(Dialogue.active_id, "CUT_FRO_AVARN_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_FRO_VILLAGE", "back in the village")
	check(adds.all(func(a): return not is_instance_valid(a)), "summons removed")
	eq(Guild.kills("BOSS_AVARN_001"), 1, "bestiary")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_KAELEN_001")
	eq(Dialogue.active_id, "DLG_KAELEN_REPORT_001", "Falk's report")
	await finish_dialogues()
	eq(Conditions.quest_state(MQ), "COMPLETED", "chapter 6 done")
	check(GameState.has_flag("FLAG_FRO_CHAPTER_COMPLETE"), "chapter flag")
	eq(GameState.currency, lun + 500, "reward")
	eq(Dialogue.select_for_npc("NPC_KAELEN_001"), "DLG_KAELEN_AFTER_001", "after dialogue")


func test_boss_stays_defeated_after_reload() -> void:
	var boss := await _boss()
	boss.take_hit(9999)
	await finish_dialogues()
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "save")
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "load")
	game.enter_area("AREA_FRO_CORE", "AREA_FRO_TEMPLE")
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_FRO_CORE_AVARN"), "Avarn stays defeated")


func test_side_quest_tormund() -> void:
	GameState.set_flag("FLAG_FRO_ARRIVED")
	game.enter_area("AREA_FRO_HALL", "default")
	await physics_frames(2)
	eq(Dialogue.select_for_npc("NPC_TORMUND_001"), "DLG_TORMUND_QUEST_001", "offer")
	Dialogue.talk_to("NPC_TORMUND_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "shop opens with the offer")
	game.shop_menu.close_menu()
	eq(Conditions.quest_step(SQ), 0, "collect shards")
	Inventory.add("ITEM_FROST_SHARD_001", 5)
	eq(Conditions.quest_step(SQ), 1, "enough shards: bring them to Tormund")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_TORMUND_001")
	eq(Dialogue.active_id, "DLG_TORMUND_THANKS_001", "thanks")
	await finish_dialogues()
	eq(Conditions.quest_state(SQ), "COMPLETED", "side quest done")
	eq(Inventory.count("ITEM_FROST_SHARD_001"), 0, "shards handed over")
	eq(GameState.currency, lun + 240, "reward")
	eq(Inventory.count("ITEM_ELIXIR_001"), 1, "elixir")
