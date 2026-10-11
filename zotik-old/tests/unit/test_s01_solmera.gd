extends TestCase
## S01: Solmera hub (chapter 4). World unlocked by the end of chapter 3,
## oasis and bazaar, shops, lore steles, arrival scene, desert look.

var game: GameRoot


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()


func test_unlocked_by_chapter_three_and_travel() -> void:
	check(not Content.world_unlocked("WORLD_SOLMERA"), "locked before Valdoria is finished")
	GameState.set_flag("FLAG_VAL_CHAPTER_COMPLETE")
	check(Content.world_unlocked("WORLD_SOLMERA"), "unlocked")
	GameState.set_flag("FLAG_ELA_CHAPTER_COMPLETE")
	GameState.set_flag("FLAG_VAL_ARRIVED")
	game.enter_area("AREA_VAL_MARKET", "default")
	await physics_frames(2)
	game.open_world_map()
	game.world_map.travel("WORLD_SOLMERA")
	await frames(3)
	await physics_frames(4)
	eq(game.area.area_id, "AREA_SOL_OASIS", "arrived at the oasis")
	eq(Dialogue.active_id, "CUT_SOL_ARRIVAL_001", "arrival scene")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_SOL_ARRIVED"), "arrival remembered")
	# the way back: the oasis has its own Weltenstein
	check(game.area.entities.has("TRAVEL_SOL_001"), "Weltenstein in the oasis")
	game.open_world_map()
	game.world_map.travel("WORLD_VALDORIA")
	await frames(3)
	await physics_frames(4)
	eq(game.area.area_id, "AREA_VAL_MARKET", "back in Valdoria")
	await finish_dialogues()


func test_arrival_plays_once() -> void:
	GameState.set_flag("FLAG_SOL_ARRIVED")
	game.enter_area("AREA_SOL_OASIS", "travel")
	await physics_frames(4)
	check(not Dialogue.is_active(), "no second arrival scene")


func test_districts_connect_and_dunes_stay_closed() -> void:
	GameState.set_flag("FLAG_SOL_ARRIVED")
	game.enter_area("AREA_SOL_OASIS", "default")
	await physics_frames(2)
	check(game.area.is_exit_open("AREA_SOL_BAZAAR"), "oasis -> bazaar")
	eq(Navigator.next_hop("AREA_SOL_BAZAAR", "AREA_SOL_OASIS"), "AREA_SOL_OASIS", "bazaar -> oasis")
	var gate := game.area.find_child("PLACEHOLDER_dune_gate", true, false)
	check(gate != null and gate.visible, "dune gate is closed until the guide opens it (S02)")


func test_steles_readable() -> void:
	GameState.set_flag("FLAG_SOL_ARRIVED")
	game.enter_area("AREA_SOL_OASIS", "default")
	await physics_frames(2)
	var book: LoreBook = game.area.entities["LORE_SOL_002"]
	check(book.prompt.contains("Kharos"), "stele title in prompt")
	var shown := []
	Dialogue.line_shown.connect(func(s, t): shown.append(t))
	book.interact(game.player)
	check(Dialogue.is_active() and shown.size() == 1 and shown[0].contains("Wächter"), "lore text shown")
	await finish_dialogues()


func test_shops() -> void:
	GameState.set_flag("FLAG_SOL_ARRIVED")
	game.enter_area("AREA_SOL_BAZAAR", "default")
	await physics_frames(2)
	GameState.currency = 2000
	Dialogue.talk_to("NPC_AMANI_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "smithy open")
	game.shop_menu.buy("ARMOR_SAND_VEIL_001")
	game.shop_menu.buy("WEAPON_SUN_SABER_001")
	game.shop_menu.close_menu()
	var atk := Stats.attack()
	check(Inventory.equip("WEAPON_SUN_SABER_001"), "sabre equips")
	check(Stats.attack() > atk, "sabre is stronger than the training sword")
	var d := Stats.defense()
	check(Inventory.equip("ARMOR_SAND_VEIL_001"), "veil equips")
	eq(Stats.defense(), d + 7, "veil defense")
	Dialogue.talk_to("NPC_JABIR_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "alchemist open")
	game.shop_menu.buy("ITEM_DATE_CAKE_001")
	eq(Inventory.count("ITEM_DATE_CAKE_001"), 1, "date cake bought")


func test_desert_look() -> void:
	check(Look.WORLDS.has("WORLD_SOLMERA"), "desert sky/fog style")
	eq(Look.floor_texture("AREA_SOL_OASIS", {}), "sand", "sand floor in the oasis")
	check(ResourceLoader.exists("res://assets/textures/sand_albedo.jpg") and ResourceLoader.exists("res://assets/textures/sand_normal.jpg"), "sand texture present")
	game.enter_area("AREA_SOL_BAZAAR", "default")
	await physics_frames(2)
	check(game.area.find_children("*", "WorldEnvironment", true, false).size() >= 1, "environment built")
