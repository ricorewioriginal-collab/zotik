extends TestCase

var game: GameRoot


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves/"
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	Settings.set_value("casino_enabled", true)
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"
	Settings.set_value("casino_enabled", true)


func _clear_wave() -> void:
	for e in game.arena_run.alive.duplicate():
		e.take_hit(99999)
	await frames(2)


func test_arena_waves_and_first_clear_reward() -> void:
	game.enter_area("AREA_VAL_ARENA", "default")
	await physics_frames(2)
	check(not ArenaRun.unlocked("ARENA_SILVER_001"), "silver locked before bronze")
	check(not game.start_arena("ARENA_SILVER_001"), "locked challenge cannot start")
	check(game.start_arena("ARENA_BRONZE_001"), "bronze starts")
	eq(game.arena_run.wave, 0, "first wave")
	eq(game.arena_run.alive.size(), 3, "three Risslinge")
	await _clear_wave()
	eq(game.arena_run.wave, 1, "second wave")
	eq(game.arena_run.alive.size(), 4, "mixed second wave")
	var lun := GameState.currency
	await _clear_wave()
	check(not game.arena_run.active(), "challenge finished")
	eq(int(GameState.arena.get("ARENA_BRONZE_001", 0)), 1, "win counted")
	check(GameState.currency >= lun + 120, "Lun reward paid")
	var potions := Inventory.count("ITEM_HI_POTION_001")
	check(potions >= 2, "first-clear items")
	check(GameState.has_flag("FLAG_VAL_ARENA_BRONZE"), "silver unlocked")
	check(game.start_arena("ARENA_BRONZE_001"), "repeatable")
	await _clear_wave()
	await _clear_wave()
	eq(int(GameState.arena.ARENA_BRONZE_001), 2, "second win counted")
	eq(Inventory.count("ITEM_HI_POTION_001"), potions, "items only once")


func test_arena_defeat_is_safe() -> void:
	game.enter_area("AREA_VAL_ARENA", "default")
	await physics_frames(2)
	var lun := GameState.currency
	check(game.start_arena("ARENA_BRONZE_001"), "start")
	game.player.take_damage(99999)
	await tree.create_timer(1.3).timeout
	check(not game.arena_run.active(), "run ended")
	eq(int(GameState.player.hp), Stats.max_hp(), "healed")
	eq(GameState.currency, lun, "nothing lost")
	eq(tree.get_nodes_in_group("enemy").filter(func(n): return not n.is_queued_for_deletion()).size(), 0, "arena enemies removed")
	check(not GameState.arena.has("ARENA_BRONZE_001"), "no win recorded")


func test_leaving_arena_aborts_run() -> void:
	game.enter_area("AREA_VAL_ARENA", "default")
	await physics_frames(2)
	game.start_arena("ARENA_BRONZE_001")
	game.enter_area("AREA_VAL_GUILD", "AREA_VAL_ARENA")
	await physics_frames(2)
	check(not game.arena_run.active(), "aborted on area change")


func test_kasimir_opens_arena_menu() -> void:
	game.enter_area("AREA_VAL_ARENA", "default")
	await physics_frames(2)
	Dialogue.talk_to("NPC_KASIMIR_001")
	await finish_dialogues()
	await frames(2)
	check(game.arena_menu.visible, "arena menu open after Kasimir")
	game.arena_menu.close_menu()


func test_casino_spin_is_deterministic_and_virtual() -> void:
	GameState.currency = 100
	Casino.rng.seed = 12345
	var r1 := Casino.spin(10)
	check(r1.has("reels") and r1.reels.size() == 3, "spin result")
	eq(GameState.currency, 90 + int(r1.win), "bet deducted, win paid")
	eq(int(GameState.casino.spins), 1, "spin counted")
	var after := GameState.currency
	Casino.rng.seed = 12345
	GameState.currency = 100
	var r2 := Casino.spin(10)
	eq(r2.reels, r1.reels, "same seed, same reels")
	GameState.currency = after
	eq(Casino.payout(["Stern", "Stern", "Stern"], 10), 250, "jackpot")
	eq(Casino.payout(["Mond", "Mond", "Blatt"], 10), 10, "pair returns bet")
	eq(Casino.payout(["Mond", "Blatt", "Stern"], 10), 0, "no match")
	var er := Casino.expected_return()
	check(er > 0.85 and er < 1.0, "house edge, return %.3f" % er)


func test_casino_guards() -> void:
	GameState.currency = 5
	eq(Casino.spin(10), {}, "not enough Lun")
	eq(GameState.currency, 5, "unchanged")
	GameState.currency = 500
	eq(Casino.spin(7), {}, "invalid bet")
	Settings.set_value("casino_enabled", false)
	eq(Casino.spin(10), {}, "family toggle blocks spinning")
	eq(GameState.currency, 500, "unchanged when blocked")


func test_casino_entrance_and_persistence() -> void:
	game.enter_area("AREA_VAL_MARKET", "default")
	await physics_frames(2)
	await finish_dialogues()
	var ent = game.area.entities["CASINO_VAL_001"]
	ent.interact(game.player)
	await frames(1)
	check(game.casino_menu.visible, "casino menu opens")
	game.casino_menu.close_menu()
	GameState.currency = 100
	Casino.spin(50)
	GameState.arena["ARENA_BRONZE_001"] = 3
	SaveSystem.save_slot(1)
	GameState.reset_new_game()
	SaveSystem.load_slot(1)
	eq(int(GameState.casino.spins), 1, "casino stats persist")
	eq(int(GameState.arena.ARENA_BRONZE_001), 3, "arena wins persist")
