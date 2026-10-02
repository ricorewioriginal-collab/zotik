extends TestCase

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


func test_unlocked_by_chapter_two_and_travel() -> void:
	check(not Content.world_unlocked("WORLD_VALDORIA"), "locked before Elaris is finished")
	GameState.set_flag("FLAG_ELA_CHAPTER_COMPLETE")
	check(Content.world_unlocked("WORLD_VALDORIA"), "unlocked")
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	game.open_world_map()
	game.world_map.travel("WORLD_VALDORIA")
	await frames(3)
	await physics_frames(4)
	eq(game.area.area_id, "AREA_VAL_MARKET", "arrived at the Valdoria market")
	eq(Dialogue.active_id, "CUT_VAL_ARRIVAL_001", "arrival scene")
	await finish_dialogues()


func test_districts_connect() -> void:
	GameState.set_flag("FLAG_VAL_ARRIVED")
	game.enter_area("AREA_VAL_MARKET", "default")
	await physics_frames(2)
	for a in ["AREA_VAL_GUILD", "AREA_VAL_CANAL_GATE"]:
		check(game.area.is_exit_open(a), "market -> " + a)
	eq(Navigator.next_hop("AREA_VAL_GUILD", "AREA_VAL_CANAL_GATE"), "AREA_VAL_MARKET", "via the market")
	check(game.area.find_children("PLACEHOLDER_casino_closed", "", true, false).size() == 1, "closed casino building (C-20)")


func test_library_books_readable() -> void:
	game.enter_area("AREA_VAL_GUILD", "default")
	await physics_frames(2)
	var book: LoreBook = game.area.entities["LORE_VAL_LIB_002"]
	check(book.prompt.contains("Der Große Bruch"), "book title in prompt")
	var shown := []
	Dialogue.line_shown.connect(func(s, t): shown.append(t))
	book.interact(game.player)
	check(Dialogue.is_active() and shown.size() == 1 and shown[0].contains("Großen Bruch"), "lore text shown")
	await finish_dialogues()


func test_smithy_armor_slot() -> void:
	GameState.set_flag("FLAG_VAL_ARRIVED")
	game.enter_area("AREA_VAL_MARKET", "default")
	await physics_frames(2)
	Dialogue.talk_to("NPC_HALDOR_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "smithy open")
	GameState.currency = 1000
	game.shop_menu.buy("ARMOR_CANAL_COAT_001")
	game.shop_menu.close_menu()
	var d := Stats.defense()
	check(Inventory.equip("ARMOR_CANAL_COAT_001"), "armour equips")
	eq(Stats.defense(), d + 5, "armour defense")
	eq(Stats.max_hp(), 115, "armour max hp")
	Inventory.unequip("armor")
	eq(Stats.defense(), d, "armour can be taken off")
	Dialogue.talk_to("NPC_YSME_001")
	await finish_dialogues()
	game.shop_menu.buy("ITEM_ELIXIR_001")
	eq(Inventory.count("ITEM_ELIXIR_001"), 1, "alchemist sells elixirs")
