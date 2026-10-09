extends TestCase
## Q01: Aqualis hub (chapter 5). World unlocked by the end of chapter 4,
## dome city and harbour, shops, steles, arrival scene, underwater look.

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


func test_unlocked_by_chapter_four_and_travel_both_ways() -> void:
	check(not Content.world_unlocked("WORLD_AQUALIS"), "locked before Solmera is finished")
	GameState.set_flag("FLAG_SOL_CHAPTER_COMPLETE")
	check(Content.world_unlocked("WORLD_AQUALIS"), "unlocked")
	for f in ["FLAG_VAL_CHAPTER_COMPLETE", "FLAG_ELA_CHAPTER_COMPLETE", "FLAG_SOL_ARRIVED"]:
		GameState.set_flag(f)
	game.enter_area("AREA_SOL_OASIS", "default")
	await physics_frames(2)
	game.open_world_map()
	game.world_map.travel("WORLD_AQUALIS")
	await frames(3)
	await physics_frames(4)
	eq(game.area.area_id, "AREA_AQU_DOME", "arrived in the dome city")
	eq(Dialogue.active_id, "CUT_AQU_ARRIVAL_001", "arrival scene")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_AQU_ARRIVED"), "arrival remembered")
	check(game.area.entities.has("TRAVEL_AQU_001"), "Weltenstein in the dome city")
	game.open_world_map()
	game.world_map.travel("WORLD_SOLMERA")
	await frames(3)
	await physics_frames(4)
	eq(game.area.area_id, "AREA_SOL_OASIS", "back in Solmera")
	await finish_dialogues()


func test_arrival_plays_once() -> void:
	GameState.set_flag("FLAG_AQU_ARRIVED")
	game.enter_area("AREA_AQU_DOME", "travel")
	await physics_frames(4)
	check(not Dialogue.is_active(), "no second arrival scene")


func test_districts_connect_and_caves_stay_closed() -> void:
	GameState.set_flag("FLAG_AQU_ARRIVED")
	game.enter_area("AREA_AQU_DOME", "default")
	await physics_frames(2)
	check(game.area.is_exit_open("AREA_AQU_HARBOUR"), "dome -> harbour")
	eq(Navigator.next_hop("AREA_AQU_HARBOUR", "AREA_AQU_DOME"), "AREA_AQU_DOME", "harbour -> dome")
	var gate := game.area.find_child("PLACEHOLDER_cave_gate", true, false)
	check(gate != null and gate.visible, "coral gate is closed until Mirael opens it (Q02)")


func test_steles_readable() -> void:
	GameState.set_flag("FLAG_AQU_ARRIVED")
	game.enter_area("AREA_AQU_DOME", "default")
	await physics_frames(2)
	var book: LoreBook = game.area.entities["LORE_AQU_002"]
	check(book.prompt.contains("Neryx"), "stele title in prompt")
	var shown := []
	Dialogue.line_shown.connect(func(s, t): shown.append(t))
	book.interact(game.player)
	check(Dialogue.is_active() and shown.size() == 1 and shown[0].contains("Strömung"), "lore text shown")
	await finish_dialogues()


func test_shops() -> void:
	GameState.set_flag("FLAG_AQU_ARRIVED")
	game.enter_area("AREA_AQU_HARBOUR", "default")
	await physics_frames(2)
	GameState.currency = 3000
	Dialogue.talk_to("NPC_DORAN_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "smithy open")
	game.shop_menu.buy("ARMOR_CORAL_PLATE_001")
	game.shop_menu.buy("WEAPON_TRIDENT_001")
	game.shop_menu.close_menu()
	var atk := Stats.attack()
	check(Inventory.equip("WEAPON_TRIDENT_001"), "trident equips")
	check(Stats.attack() > atk, "trident is stronger than the training sword")
	var d := Stats.defense()
	check(Inventory.equip("ARMOR_CORAL_PLATE_001"), "coral plate equips")
	eq(Stats.defense(), d + 9, "coral plate defense")
	Dialogue.talk_to("NPC_PERLA_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "alchemist open")
	game.shop_menu.buy("ITEM_KELP_WRAP_001")
	eq(Inventory.count("ITEM_KELP_WRAP_001"), 1, "kelp wrap bought")


func test_underwater_look() -> void:
	check(Look.WORLDS.has("WORLD_AQUALIS"), "underwater sky/fog style")
	check(float(Look.WORLDS.WORLD_AQUALIS.fog_density) > 0.01, "dense underwater fog")
	game.enter_area("AREA_AQU_DOME", "default")
	await physics_frames(2)
	var we := game.area.find_child("WorldEnvironment", true, false) as WorldEnvironment
	check(we != null and we.environment.fog_density > 0.012, "fog applied in the dome city")
