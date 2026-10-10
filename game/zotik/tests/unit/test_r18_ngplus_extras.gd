extends TestCase
## E05: New Game+ extras: NG+-only enemies, chests, shop and dialogue lines.

var game: GameRoot


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves/"
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	WorldArea.roamers_force = true
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()


func after_each() -> void:
	GameState.ng_plus = 0
	WorldArea.roamers_force = false
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func test_ng_condition() -> void:
	check(not Conditions.check({"type": "ng_plus", "level": 1}), "off in the first playthrough")
	GameState.ng_plus = 1
	check(Conditions.check({"type": "ng_plus", "level": 1}), "on in NG+")
	check(not Conditions.check({"type": "ng_plus", "level": 2}), "level 2 needs two restarts")


func test_extra_chests_only_in_new_game_plus() -> void:
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	check(not game.area.entities.has("CHEST_NG_001"), "no NG+ chest in the first playthrough")
	GameState.ng_plus = 1
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	check(game.area.entities.has("CHEST_NG_001"), "NG+ chest present")
	var lun := GameState.currency
	game.area.entities["CHEST_NG_001"].interact(game.player)
	eq(GameState.currency, lun + 600, "chest Lun +50% per level")
	eq(Inventory.count("ITEM_CHRONICLE_001"), 3, "Chronikfragmente")


func test_ng_enemies_join_the_roamers() -> void:
	GameState.ng_plus = 1
	var seen := {}
	for round in 6:
		game.enter_area("AREA_IGN_ASH", "default")
		await physics_frames(2)
		for r in game.area.roamers:
			seen[r.enemy_id] = true
	check(seen.has("ENEMY_NG_DRACHE_001") or seen.has("ENEMY_GLUEHWESPE_001") or seen.has("ENEMY_GLUTDRACHE_001"), "roamers spawn")
	var pool: Array = game.area.layout.roamers.pool + game.area.layout.roamers.ng_pool
	check("ENEMY_NG_DRACHE_001" in pool, "NG+ dragon is in the pool")
	GameState.ng_plus = 0
	game.enter_area("AREA_IGN_ASH", "default")
	await physics_frames(2)
	for r in game.area.roamers:
		check(not str(r.enemy_id).begins_with("ENEMY_NG_"), "no NG+ enemies in the first playthrough")


func test_corvin_sells_chronicle_gear_only_in_new_game_plus() -> void:
	eq(Dialogue.select_for_npc("NPC_CORVIN_001"), "DLG_CORVIN_LOCKED_001", "locked at first")
	GameState.ng_plus = 1
	eq(Dialogue.select_for_npc("NPC_CORVIN_001"), "DLG_CORVIN_SHOP_001", "open in NG+")
	check("WEAPON_CHRONICLE_BLADE_001" in Content.get_entry("shops", "SHOP_END_CORVIN_001").stock, "sells the Chronikklinge")


func test_story_npcs_comment_on_the_second_run() -> void:
	GameState.set_flag("FLAG_LUN_CHAPTER_COMPLETE")
	var before := Dialogue.select_for_npc("NPC_MIRA_001")
	GameState.ng_plus = 1
	GameState.quests["QUEST_MAIN_LUN_001"] = {"state": "COMPLETED", "step": 13, "progress": 0}
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED", false)
	GameState.set_flag("FLAG_LUN_CHAPTER_COMPLETE", false)
	eq(Dialogue.select_for_npc("NPC_MIRA_001"), "DLG_MIRA_NGPLUS_001", "Mira notices (when nothing else applies)")
	check(before != "", "baseline dialogue exists")
