extends TestCase
## E02: character end quests (Kael, Eryn, Toren, Sela, Nerea, Professorium) after the finale.

var game: GameRoot
const CASES := [
	["KAEL", "NPC_KAEL_001", "AREA_ELY_QUARTER", 1500, "ITEM_KAEL_COMPASS_001"],
	["ERYN", "NPC_ERYN_001", "AREA_NOC_CITY", 1500, "ITEM_ERYN_DIARY_001"],
	["TOREN", "NPC_TOREN_001", "AREA_LUN_VILLAGE", 1200, "ITEM_TOREN_BAND_001"],
	["SELA", "NPC_SELA_001", "AREA_ELA_TOWN", 1300, "ITEM_SELA_LEAF_001"],
	["MIRAEL", "NPC_MIRAEL_001", "AREA_AQU_DOME", 1400, "ITEM_MIRAEL_GEAR_001"],
	["PROFESSORIUM", "NPC_PROFESSORIUM_001", "AREA_LUN_VILLAGE", 2500, "ITEM_PROFESSORIUM_NOTES_001"],
]


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


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func test_end_quests_wait_for_the_finale() -> void:
	for c in CASES:
		check(Dialogue.select_for_npc(c[1]) != "DLG_%s_END_OFFER_001" % c[0], c[0] + " offers nothing before the finale")
	GameState.set_flag("FLAG_GAME_COMPLETE")
	for c in CASES:
		eq(Dialogue.select_for_npc(c[1]), "DLG_%s_END_OFFER_001" % c[0], c[0] + " offers the end quest after the finale")


func test_every_end_quest_can_be_completed_once() -> void:
	GameState.set_flag("FLAG_GAME_COMPLETE")
	for c in CASES:
		var qid := "QUEST_END_%s_001" % c[0]
		game.enter_area(c[2], "default")
		await physics_frames(2)
		Dialogue.talk_to(c[1])
		await finish_dialogues()
		eq(Conditions.quest_step(qid), 0, c[0] + " quest started")
		var cond: Dictionary = Content.get_entry("quests", qid).steps[0].condition
		if cond.type == "defeat":
			for i in int(cond.count):
				EventBus.enemy_defeated.emit(cond.enemy)
		else:
			Inventory.add(cond.item, int(cond.count))
		eq(Conditions.quest_step(qid), 1, c[0] + " goal reached")
		var lun := GameState.currency
		Dialogue.talk_to(c[1])
		await finish_dialogues()
		eq(Conditions.quest_state(qid), "COMPLETED", c[0] + " completed")
		eq(GameState.currency, lun + int(c[3]), c[0] + " reward")
		eq(Inventory.count(c[4]), 1, c[0] + " keepsake")
		check(Dialogue.select_for_npc(c[1]) != "DLG_%s_END_OFFER_001" % c[0], c[0] + " offers nothing twice")
