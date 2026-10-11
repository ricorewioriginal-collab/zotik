extends TestCase
## S04: chapter-4 quests and the boss Kharos.

const MQ := "QUEST_MAIN_SOL_001"
const SQ := "QUEST_SIDE_SOL_001"
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
	for f in ["FLAG_ELA_CHAPTER_COMPLETE", "FLAG_VAL_ARRIVED", "FLAG_VAL_CHAPTER_COMPLETE"]:
		GameState.set_flag(f)


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _arrive() -> void:
	game.enter_area("AREA_SOL_OASIS", "travel")
	await physics_frames(3)
	await finish_dialogues()


func _boss() -> Boss:
	for f in ["FLAG_SOL_ARRIVED", "FLAG_SOL_DUNES_OPEN", "FLAG_SOL_RUINS_OPEN", "FLAG_SOL_MIRRORS_DONE", "FLAG_SOL_WAECHTER_DEFEATED", "FLAG_SOL_KHAROS_MET"]:
		GameState.set_flag(f)
	game.enter_area("AREA_SOL_ARENA", "default")
	await physics_frames(2)
	return game.area.entities["SPAWN_SOL_ARENA_KHAROS"]


func test_arrival_starts_the_main_quest() -> void:
	await _arrive()
	eq(Conditions.quest_step(MQ), 0, "quest active: talk to Nuri")
	eq(Quests.objective(MQ), "Sprich mit Nuri in der Oase.", "objective")


func test_nuri_starts_the_quest_for_older_saves() -> void:
	GameState.set_flag("FLAG_SOL_ARRIVED")
	GameState.set_flag("FLAG_SOL_DUNES_OPEN")
	game.enter_area("AREA_SOL_OASIS", "default")
	await physics_frames(2)
	eq(Conditions.quest_state(MQ), "INACTIVE", "no quest yet")
	eq(Dialogue.select_for_npc("NPC_NURI_001"), "DLG_NURI_LEAD_001", "Nuri picks the quest up")
	Dialogue.talk_to("NPC_NURI_001")
	await finish_dialogues()
	check(Conditions.quest_state(MQ) != "INACTIVE", "quest started")


func test_main_quest_flow_through_the_ruins() -> void:
	await _arrive()
	Dialogue.talk_to("NPC_NURI_001")
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 1, "find the sunken city")
	check(game.area.is_exit_open("AREA_SOL_DUNES"), "dunes open")
	GameState.set_flag("FLAG_SOL_RUINS_OPEN")
	game.enter_area("AREA_SOL_SUNKEN", "AREA_SOL_DUNES")
	await physics_frames(2)
	eq(Conditions.quest_step(MQ), 2, "mirrors next")
	var node: PuzzleNode = game.area.entities["PUZ_SOL_MIRRORS_001"]
	for i in 4:
		for t in [1, 3, 0, 2][i]:
			node.parts[i].interact(game.player)
	node.parts[4].interact(game.player)
	eq(Conditions.quest_step(MQ), 3, "Sandwächter next")
	game.enter_area("AREA_SOL_SUN_HALL", "AREA_SOL_SUNKEN")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_SOL_ARENA"), "arena closed while the guardian stands")
	game.area.entities["SPAWN_SOL_HALL_WAECHTER"].take_hit(99999)
	eq(Conditions.quest_step(MQ), 4, "Kharos next")
	check(game.area.is_exit_open("AREA_SOL_ARENA"), "arena open")


func test_kharos_intro_plays_once() -> void:
	for f in ["FLAG_SOL_ARRIVED", "FLAG_SOL_WAECHTER_DEFEATED"]:
		GameState.set_flag(f)
	game.enter_area("AREA_SOL_ARENA", "default")
	await physics_frames(2)
	var trig: Node3D = game.area.entities["TRIGGER_SOL_KHAROS_INTRO"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_SOL_KHAROS_001", "boss intro")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_SOL_KHAROS_MET"), "remembered")


func test_boss_phases_and_summons() -> void:
	var boss := await _boss()
	eq(boss.max_hp, 780, "boss hp")
	eq(boss.data.phases.size(), 3, "three phases")
	boss.take_hit(330)
	eq(boss.phase, 1, "Sandsturm below 60%")
	eq(boss.summons.size(), 2, "two Sandgeister")
	boss.take_hit(250)
	eq(boss.phase, 2, "Sturz des Kolosses below 30%")
	eq(boss.summons.size(), 3, "plus a Sandskorpion")
	boss.take_hit(10, 400.0)
	check(boss.is_broken(), "boss can be broken")
	eq(boss.data.phases[1].hazard.kind, "surge", "sand surge from phase 2")


func test_defeat_completes_the_chapter() -> void:
	var boss := await _boss()
	Quests.start(MQ)
	GameState.quests[MQ].step = 4
	boss.take_hit(330)
	var adds := boss.summons.duplicate()
	boss.take_hit(9999)
	check(GameState.has_flag("FLAG_BOSS_SOL_KHAROS_DEFEATED"), "boss flag")
	eq(Conditions.quest_step(MQ), 5, "report to Nuri")
	eq(Dialogue.active_id, "CUT_SOL_KHAROS_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_SOL_OASIS", "back in the oasis")
	check(adds.all(func(a): return not is_instance_valid(a)), "summons removed")
	eq(Guild.kills("BOSS_KHAROS_001"), 1, "bestiary")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_NURI_001")
	eq(Dialogue.active_id, "DLG_NURI_REPORT_001", "Nuri's report")
	await finish_dialogues()
	eq(Conditions.quest_state(MQ), "COMPLETED", "chapter 4 done")
	check(GameState.has_flag("FLAG_SOL_CHAPTER_COMPLETE"), "chapter flag")
	eq(GameState.currency, lun + 400, "reward")
	eq(Dialogue.select_for_npc("NPC_NURI_001"), "DLG_NURI_AFTER_001", "after dialogue")


func test_boss_stays_defeated_after_reload() -> void:
	var boss := await _boss()
	boss.take_hit(9999)
	await finish_dialogues()
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "save")
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "load")
	game.enter_area("AREA_SOL_ARENA", "AREA_SOL_SUN_HALL")
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_SOL_ARENA_KHAROS"), "Kharos stays defeated")


func test_side_quest_jabir() -> void:
	GameState.set_flag("FLAG_SOL_ARRIVED")
	game.enter_area("AREA_SOL_BAZAAR", "default")
	await physics_frames(2)
	eq(Dialogue.select_for_npc("NPC_JABIR_001"), "DLG_JABIR_QUEST_001", "offer")
	Dialogue.talk_to("NPC_JABIR_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "shop opens with the offer")
	game.shop_menu.close_menu()
	eq(Conditions.quest_step(SQ), 0, "collect dust")
	Inventory.add("ITEM_SUN_DUST_001", 6)
	eq(Conditions.quest_step(SQ), 1, "enough dust: bring it to Jabir")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_JABIR_001")
	eq(Dialogue.active_id, "DLG_JABIR_THANKS_001", "thanks")
	await finish_dialogues()
	eq(Conditions.quest_state(SQ), "COMPLETED", "side quest done")
	eq(Inventory.count("ITEM_SUN_DUST_001"), 0, "dust handed over")
	eq(GameState.currency, lun + 200, "reward")
	eq(Inventory.count("ITEM_ELIXIR_001"), 1, "elixir")
	Dialogue.talk_to("NPC_JABIR_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "back to the plain shop")
