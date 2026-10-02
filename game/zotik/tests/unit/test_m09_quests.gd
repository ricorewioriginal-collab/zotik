extends TestCase

const MAIN := "QUEST_MAIN_LUN_001"
const SIDE := "QUEST_SIDE_LUN_001"


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves/"
	GameState.reset_new_game()
	Dialogue.reset()


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _talk(npc: String) -> void:
	EventBus.npc_talked.emit(npc, "DLG_TEST")


func _area(a: String) -> void:
	GameState.player.area = a
	EventBus.area_entered.emit(a)


func _kill(id: String, n: int = 1) -> void:
	for i in n:
		EventBus.enemy_defeated.emit(id)


func test_full_main_quest_by_events() -> void:
	Quests.start(MAIN)
	_talk("NPC_MIRA_001")
	_talk("NPC_TOREN_001")
	_kill("ENEMY_TRAINING_DUMMY_001")
	check(GameState.has_flag("FLAG_LUN_FOREST_UNLOCKED"), "forest unlocked after training")
	_area("AREA_LUN_FOREST")
	_kill("ENEMY_RIFTLING_001", 3)
	EventBus.puzzle_solved.emit("PUZ_LUN_MOONGATE_001")
	EventBus.puzzle_solved.emit("PUZ_LUN_RESONANCE_BRIDGE_001")
	_kill("ENEMY_MOONWOLF_001")
	EventBus.savepoint_used.emit("SAVEPOINT_LUN_RIFT_001")
	check(GameState.has_flag("FLAG_LUN_WELTENANKER_AWAKENED"), "arena opened")
	_kill("BOSS_ORUN_001")
	check(GameState.has_flag("FLAG_BOSS_LUN_ORUN_DEFEATED"), "orun flag")
	Inventory.grant_unique("WEAPON_WORLD_BLADE_001")
	eq(Conditions.quest_step(MAIN), 11, "at return step")
	_talk("NPC_MIRA_001")
	check(GameState.has_flag("FLAG_LUN_PROFESSORIUM_ARRIVED"), "professorium arrives")
	var lun := GameState.currency
	_talk("NPC_PROFESSORIUM_001")
	eq(Conditions.quest_state(MAIN), "COMPLETED", "main quest completed")
	eq(GameState.currency, lun + 100, "reward")
	check(GameState.has_flag("FLAG_LUN_CHAPTER_COMPLETE"), "chapter flag")


func test_out_of_order_events_are_ignored() -> void:
	Quests.start(MAIN)
	_talk("NPC_TOREN_001")
	_kill("BOSS_ORUN_001")
	EventBus.puzzle_solved.emit("PUZ_LUN_MOONGATE_001")
	eq(Conditions.quest_step(MAIN), 0, "still at step 0")
	check(not GameState.has_flag("FLAG_BOSS_LUN_ORUN_DEFEATED"), "no flag from early event")


func test_kill_progress_objective_and_persistence() -> void:
	Quests.start(MAIN)
	GameState.quests[MAIN].step = 4
	_kill("ENEMY_RIFTLING_001")
	_kill("ENEMY_MOONWOLF_001")
	eq(Quests.objective(MAIN), "Vertreibe die Risslinge im Mondwald (3). (1/3)", "objective with progress")
	SaveSystem.save_slot(1)
	GameState.reset_new_game()
	SaveSystem.load_slot(1)
	_kill("ENEMY_RIFTLING_001", 2)
	eq(Conditions.quest_step(MAIN), 5, "progress survived save/load")


func test_state_condition_checked_on_step_entry() -> void:
	Quests.start(MAIN)
	GameState.quests[MAIN].step = 2
	GameState.player.area = "AREA_LUN_FOREST"
	_kill("ENEMY_TRAINING_DUMMY_001")
	eq(Conditions.quest_step(MAIN), 4, "area step completes immediately when already there")


func test_side_quest_with_item_already_owned() -> void:
	Inventory.add("ITEM_LOST_DELIVERY_001")
	Quests.start(SIDE)
	eq(Conditions.quest_step(SIDE), 1, "item step satisfied on start")
	var lun := GameState.currency
	_talk("NPC_SARI_001")
	eq(Conditions.quest_state(SIDE), "COMPLETED", "side quest done")
	eq(Inventory.count("ITEM_LOST_DELIVERY_001"), 0, "delivery handed over")
	eq(Inventory.count("ITEM_MOON_PENDANT_001"), 1, "pendant reward")
	eq(GameState.currency, lun + 60, "lun reward")
	check(GameState.has_flag("FLAG_LUN_SARI_DELIVERY_RETURNED"), "flag")


func test_quests_start_once_and_have_no_force_api() -> void:
	check(Quests.start(MAIN), "start")
	check(not Quests.start(MAIN), "second start ignored")
	for m in ["complete", "complete_quest", "set_step", "force"]:
		check(not Quests.has_method(m), "no public %s" % m)


func test_hud_objective_and_quest_log() -> void:
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	var game: GameRoot = tree.current_scene
	await finish_dialogues()
	check(game.hud.objective_label.text.contains("Sprich mit Mira"), "HUD shows main objective: %s" % game.hud.objective_label.text)
	game.toggle_quest_log()
	check(game.quest_log.visible and not game.player.control_enabled, "quest log open")
	eq(game.quest_log.list.get_child_count(), 1, "one quest listed")
	check(game.quest_log.list.find_children("*", "Button", true, false).is_empty(), "log has no buttons")
	game.toggle_quest_log()
	check(game.player.control_enabled, "closed")
