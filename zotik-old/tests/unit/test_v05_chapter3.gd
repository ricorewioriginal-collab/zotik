extends TestCase

const MQ := "QUEST_MAIN_VAL_001"
const SQ := "QUEST_SIDE_VAL_001"
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
	GameState.set_flag("FLAG_ELA_CHAPTER_COMPLETE")


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _boss() -> Boss:
	for f in ["FLAG_VAL_ARRIVED", "FLAG_VAL_CANALS_OPEN", "FLAG_VAL_CANALS_DRAINED", "FLAG_VAL_ROSTGOLEM_DEFEATED", "FLAG_VAL_WAECHTER_MET"]:
		GameState.set_flag(f)
	game.enter_area("AREA_VAL_FLOODGATE", "default")
	await physics_frames(2)
	return game.area.entities["SPAWN_VAL_FLOODGATE_WAECHTER"]


func test_arrival_starts_main_quest() -> void:
	game.enter_area("AREA_VAL_MARKET", "default")
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_VAL_ARRIVAL_001", "arrival scene")
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 0, "quest active: report to Harlan")
	eq(Quests.objective(MQ), "Melde dich bei Harlan in der Gildenhalle.", "objective text")


func test_veyr_starts_quest_for_old_saves() -> void:
	GameState.set_flag("FLAG_VAL_ARRIVED")
	eq(Conditions.quest_state(MQ), "INACTIVE", "save from before V05")
	Dialogue.talk_to("NPC_VEYR_001")
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 1, "started and first step done")


func test_main_quest_flow_through_dungeon() -> void:
	GameState.set_flag("FLAG_VAL_ARRIVED")
	Quests.start(MQ)
	Dialogue.talk_to("NPC_TIBOR_001")
	eq(Dialogue.active_id, "DLG_TIBOR_CLOSED_001", "gate needs Harlan first")
	await finish_dialogues()
	eq(Conditions.quest_step(MQ), 0, "talking to Tibor early does not skip")
	Dialogue.talk_to("NPC_VEYR_001")
	await finish_dialogues()
	Dialogue.talk_to("NPC_TIBOR_001")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_VAL_CANALS_OPEN"), "gate open")
	eq(Conditions.quest_step(MQ), 2, "enter the canals")
	game.enter_area("AREA_VAL_CANALS", "AREA_VAL_CANAL_GATE")
	await physics_frames(2)
	eq(Conditions.quest_step(MQ), 3, "valves")
	PuzzleLogic.turn_valve("PUZ_VAL_VALVES_001", 1)
	PuzzleLogic.turn_valve("PUZ_VAL_VALVES_001", 2)
	eq(Conditions.quest_step(MQ), 4, "Rostgolem")
	game.enter_area("AREA_VAL_CISTERN", "AREA_VAL_CANALS")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_VAL_FLOODGATE"), "floodgate sealed while the golem stands")
	game.area.entities["SPAWN_VAL_CISTERN_GOLEM"].take_hit(99999)
	eq(Conditions.quest_step(MQ), 5, "boss")
	check(game.area.is_exit_open("AREA_VAL_FLOODGATE"), "floodgate open")
	eq(Navigator.next_hop("AREA_VAL_CISTERN", "AREA_VAL_FLOODGATE"), "AREA_VAL_FLOODGATE", "route")


func test_intro_plays_once() -> void:
	await _boss()
	GameState.flags.erase("FLAG_VAL_WAECHTER_MET")
	game.enter_area("AREA_VAL_FLOODGATE", "default")
	await physics_frames(2)
	game.player.global_position = game.area.entities["TRIGGER_VAL_WAECHTER_INTRO"].global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_VAL_WAECHTER_001", "intro")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_VAL_WAECHTER_MET"), "once flag")
	check(game.area.entities.has("SPAWN_VAL_FLOODGATE_WAECHTER"), "boss present")


func test_boss_phases_and_summons() -> void:
	var boss := await _boss()
	eq(boss.max_hp, 640, "boss hp")
	boss.take_hit(300)
	eq(boss.phase, 1, "Flutwelle below 60%")
	eq(boss.summons.size(), 2, "two Kanalschleime")
	boss.take_hit(220)
	eq(boss.phase, 2, "Tiefenzorn below 30%")
	eq(boss.summons.size(), 3, "plus a Schleusenkrabbe")
	boss.take_hit(10, 300.0)
	check(boss.is_broken(), "boss can be broken")


func test_water_surge_spans_arena_and_can_be_sidestepped() -> void:
	var boss := await _boss()
	var hz: Dictionary = boss.data.phases[1].hazard
	eq(hz.kind, "surge", "phase 2 uses the surge")
	game.player.global_position = Vector3(-14, 0, 6)
	var hp := int(GameState.player.hp)
	var h := boss.spawn_hazard(game.player.global_position, hz)
	eq(str(h.name), "PLACEHOLDER_water_surge", "surge placeholder")
	game.player.global_position = Vector3(14, 0, 6)  # far sideways is still inside the band
	await tree.create_timer(float(hz.delay) + 0.15).timeout
	eq(hp - int(GameState.player.hp), int(hz.damage), "surge hits across the whole width")
	hp = int(GameState.player.hp)
	boss.spawn_hazard(game.player.global_position, hz)
	game.player.global_position = Vector3(14, 0, 6 + float(hz.width))
	await tree.create_timer(float(hz.delay) + 0.15).timeout
	eq(int(GameState.player.hp), hp, "stepping out of the band avoids it")
	eq(boss.hazards.size(), 0, "hazards cleaned up")


func test_validator_rejects_bad_hazard() -> void:
	var ph: Dictionary = Content.tables.enemies.BOSS_KANALWAECHTER_001.phases[1]
	ph.hazard.erase("width")
	var errors := Content.validate()
	Content.load_all()
	check(errors.any(func(x): return x.contains("BOSS_KANALWAECHTER_001") and x.contains("hazard")), "missing width detected")


func test_defeat_completes_chapter() -> void:
	var boss := await _boss()
	Quests.start(MQ)
	GameState.quests[MQ].step = 5
	boss.take_hit(300)
	var adds := boss.summons.duplicate()
	boss.take_hit(9999)
	check(GameState.has_flag("FLAG_BOSS_VAL_WAECHTER_DEFEATED"), "boss flag")
	eq(Conditions.quest_step(MQ), 6, "report to Harlan")
	eq(Dialogue.active_id, "CUT_VAL_WAECHTER_DEFEAT_001", "defeat scene")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_VAL_CANAL_GATE", "back at the canal gate")
	check(adds.all(func(a): return not is_instance_valid(a)), "summons removed")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_VEYR_001")
	eq(Dialogue.active_id, "DLG_VEYR_RETURN_001", "Harlan's report")
	await finish_dialogues()
	eq(Conditions.quest_state(MQ), "COMPLETED", "chapter 3 done")
	check(GameState.has_flag("FLAG_VAL_CHAPTER_COMPLETE"), "chapter flag")
	eq(GameState.currency, lun + 300, "reward")
	eq(Dialogue.select_for_npc("NPC_VEYR_001"), "DLG_VEYR_AFTER_001", "after dialogue")
	game.enter_area("AREA_VAL_FLOODGATE", "default")
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_VAL_FLOODGATE_WAECHTER"), "boss stays defeated")


func test_side_quest_lotte() -> void:
	GameState.set_flag("FLAG_VAL_ARRIVED")
	Dialogue.talk_to("NPC_LOTTE_001")
	await finish_dialogues()
	eq(Conditions.quest_step(SQ), 0, "collect scrap")
	Inventory.add("ITEM_SCRAP_001", 4)
	eq(Conditions.quest_step(SQ), 1, "bring it to Lotte")
	var lun := GameState.currency
	Dialogue.talk_to("NPC_LOTTE_001")
	eq(Dialogue.active_id, "DLG_LOTTE_THANKS_001", "thanks")
	await finish_dialogues()
	eq(Conditions.quest_state(SQ), "COMPLETED", "done")
	eq(Inventory.count("ITEM_SCRAP_001"), 0, "scrap handed over")
	eq(GameState.currency, lun + 150, "reward")
	eq(Dialogue.select_for_npc("NPC_LOTTE_001"), "DLG_LOTTE_AFTER_001", "after dialogue")
