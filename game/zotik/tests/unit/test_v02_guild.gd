extends TestCase

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
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func test_bestiary_records_every_defeat() -> void:
	eq(Guild.kills("ENEMY_RIFTLING_001"), 0, "unknown at start")
	for i in 3:
		EventBus.enemy_defeated.emit("ENEMY_RIFTLING_001")
	eq(Guild.kills("ENEMY_RIFTLING_001"), 3, "three recorded")
	game.open_menu(game.bestiary_menu)
	check(game.bestiary_menu.visible, "bestiary open")
	var texts: Array = game.bestiary_menu.list.get_children().map(func(r): return r.get_child(0).text)
	check(texts.any(func(t): return t.begins_with("Rissling (Lunaris) – besiegt: 3")), "entry with name, region, kills")
	check(texts.any(func(t): return t.begins_with("???")), "unknown enemies hidden")
	check(game.bestiary_menu.info_label.text.begins_with("Erfasst: 1 /"), "progress counter")


func test_bounty_lifecycle() -> void:
	const B := "BOUNTY_RIFTLING_001"
	check(Guild.accept(B), "accept")
	check(not Guild.accept(B), "no double accept")
	EventBus.enemy_defeated.emit("ENEMY_PILZLING_001")
	eq(int(GameState.bounties[B].progress), 0, "other enemies do not count")
	for i in 5:
		EventBus.enemy_defeated.emit("ENEMY_RIFTLING_001")
	eq(Guild.state(B), "DONE", "fulfilled")
	var lun := GameState.currency
	check(Guild.claim(B), "claim")
	check(not Guild.claim(B), "claim only once")
	eq(GameState.currency, lun + 80, "Lun reward")
	eq(Inventory.count("ITEM_HEALING_POTION_001"), 2, "item reward")


func test_bounty_limits_and_flags() -> void:
	check(not Guild.is_offered("BOUNTY_SCHLEIM_001"), "canal bounty only after the canals open")
	check(not Guild.accept("BOUNTY_SCHLEIM_001"), "cannot accept hidden bounty")
	for id in ["BOUNTY_RIFTLING_001", "BOUNTY_PILZLING_001", "BOUNTY_DORNENWOLF_001"]:
		check(Guild.accept(id), "accept " + id)
	GameState.set_flag("FLAG_VAL_CANALS_OPEN")
	check(not Guild.accept("BOUNTY_SCHLEIM_001"), "max 3 active")


func test_board_in_guild_and_persistence() -> void:
	game.enter_area("AREA_VAL_GUILD", "default")
	await physics_frames(2)
	game.area.entities["BOARD_VAL_GUILD_001"].interact(game.player)
	check(game.bounty_menu.visible and not game.player.control_enabled, "bounty menu open")
	game.bounty_menu.accept("BOUNTY_DORNENWOLF_001")
	game.bounty_menu.close_menu()
	EventBus.enemy_defeated.emit("ENEMY_DORNENWOLF_001")
	SaveSystem.save_slot(1)
	GameState.reset_new_game()
	SaveSystem.load_slot(1)
	eq(int(GameState.bounties["BOUNTY_DORNENWOLF_001"].progress), 1, "bounty progress persists")
	eq(Guild.kills("ENEMY_DORNENWOLF_001"), 1, "bestiary persists")
