extends TestCase
## E04: New Game+ keeps what the player owns, restarts the story and toughens enemies.

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


func after_each() -> void:
	GameState.ng_plus = 0
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func test_new_game_plus_keeps_belongings_and_resets_the_story() -> void:
	GameState.set_flag("FLAG_GAME_COMPLETE")
	GameState.set_flag("FLAG_LUN_CHAPTER_COMPLETE")
	GameState.quests["QUEST_MAIN_LUN_001"] = {"state": "COMPLETED", "step": 13, "progress": 0}
	GameState.chests_opened["CHEST_LUN_001"] = true
	GameState.defeated["SPAWN_LUN_ARENA_ORUN"] = true
	GameState.party = ["PARTY_LYRA_001"] as Array[String]
	GameState.inventory["ITEM_HI_POTION_001"] = 4
	GameState.unique_rewards["WEAPON_WORLD_BLADE_EX_001"] = true
	GameState.equipment = {"weapon": "WEAPON_WORLD_BLADE_001"}
	GameState.currency = 777
	GameState.bestiary["ENEMY_RIFTLING_001"] = 3
	GameState.arena["ARENA_HALL_001"] = 2
	GameState.begin_new_game_plus()
	eq(GameState.ng_plus, 1, "level 1")
	check(GameState.has_flag("FLAG_GAME_COMPLETE"), "the finale flag stays")
	check(not GameState.has_flag("FLAG_LUN_CHAPTER_COMPLETE"), "story flags reset")
	check(GameState.quests.is_empty() and GameState.chests_opened.is_empty() and GameState.defeated.is_empty(), "quests, chests and defeats reset")
	check(GameState.party.is_empty(), "party leaves")
	eq(GameState.inventory.get("ITEM_HI_POTION_001", 0), 4, "items kept")
	check(GameState.unique_rewards.has("WEAPON_WORLD_BLADE_EX_001"), "keepsakes kept")
	eq(GameState.equipment.get("weapon"), "WEAPON_WORLD_BLADE_001", "gear kept")
	eq(GameState.currency, 777, "Lun kept")
	eq(GameState.bestiary.get("ENEMY_RIFTLING_001"), 3, "bestiary kept")
	eq(GameState.arena.get("ARENA_HALL_001"), 2, "arena records kept")
	eq(GameState.player.area, GameState.START_AREA, "back at the start")
	GameState.begin_new_game_plus()
	eq(GameState.ng_plus, 2, "level 2")


func test_ng_plus_survives_save_and_load() -> void:
	GameState.ng_plus = 2
	var d := GameState.to_dict()
	GameState.reset_new_game()
	eq(GameState.ng_plus, 0, "reset clears")
	check(GameState.from_dict(d), "restores")
	eq(GameState.ng_plus, 2, "level restored")


func test_enemies_scale_and_bosses_get_a_rage_phase() -> void:
	var base := Content.enemy("BOSS_ORUN_001")
	var e0 := Enemy.create({"enemy": "ENEMY_RIFTLING_001", "spawn": "SPAWN_TEST_NG_0", "pos": [0, 0, 0]})
	eq(e0.max_hp, int(Content.enemy("ENEMY_RIFTLING_001").hp), "no scaling on the first playthrough")
	e0.free()
	GameState.ng_plus = 1
	var e1 := Enemy.create({"enemy": "ENEMY_RIFTLING_001", "spawn": "SPAWN_TEST_NG_1", "pos": [0, 0, 0]})
	eq(e1.max_hp, int(round(float(Content.enemy("ENEMY_RIFTLING_001").hp) * 1.5)), "+50% hp")
	eq(int(e1.data.attack), int(round(float(Content.enemy("ENEMY_RIFTLING_001").attack) * 1.35)), "+35% attack")
	e1.free()
	var boss: Boss = Enemy.create({"enemy": "BOSS_ORUN_001", "spawn": "SPAWN_TEST_NG_B", "pos": [0, 0, 0]})
	eq(boss.data.phases.size(), base.phases.size() + 1, "extra phase")
	eq(boss.data.phases[-1].name, "Raserei (NG+)", "rage phase")
	eq(Content.enemy("BOSS_ORUN_001").phases.size(), base.phases.size(), "shared content untouched")
	boss.free()


func test_ysolde_offers_new_game_plus() -> void:
	GameState.set_flag("FLAG_GAME_COMPLETE")
	game.enter_area("AREA_END_HUB", "travel")
	await physics_frames(3)
	await finish_dialogues()
	Dialogue.talk_to("NPC_YSOLDE_001")
	await finish_dialogues()
	check(game.ngplus_menu.visible, "the New Game+ menu opens")
	check(game.ngplus_menu.title_label.text.contains("Stufe 1"), "shows the level")
	game.ngplus_menu.close_menu()
