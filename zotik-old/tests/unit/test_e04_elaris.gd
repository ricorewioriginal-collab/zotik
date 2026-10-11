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
	for f in ["FLAG_LUN_CHAPTER_COMPLETE", "FLAG_ELA_ARRIVED", "FLAG_ELA_FOREST_OPEN"]:
		GameState.set_flag(f)


func test_all_elaris_areas_build_completely() -> void:
	for a in ["AREA_ELA_TOWN", "AREA_ELA_FOREST", "AREA_ELA_TOWER", "AREA_ELA_DUNGEON", "AREA_ELA_ROOT_ARENA"]:
		game.enter_area(a, "default")
		await physics_frames(2)
		eq(game.area.area_id, a, "built " + a)
		eq(game.area.skipped.size(), 0, "%s: no unbuilt entities" % a)
		eq(Content.world_of(a), "WORLD_ELARIS", "%s in Elaris" % a)


func test_ride_moving_path_across_ravine() -> void:
	game.enter_area("AREA_ELA_FOREST", "default")
	await physics_frames(2)
	var plat: MovingPlatform = game.area.entities["PLATFORM_ELA_PATH_1"]
	plat.t = 0.0
	await physics_frames(1)
	game.player.global_position = plat.global_position + Vector3(0, 0.6, 0)
	game.player.velocity = Vector3.ZERO
	await physics_frames(int(plat.period * 0.5 * 60) + 10)
	check(game.player.global_position.z < -5.0 and game.player.global_position.y > -1.0, "carried to the north side (pos %s)" % game.player.global_position)


func test_falling_into_ravine_respawns() -> void:
	game.enter_area("AREA_ELA_FOREST", "default")
	await physics_frames(2)
	game.player.global_position = Vector3(20, 2, 0)
	await physics_frames(90)
	check(game.player.global_position.z > 30.0, "respawned at entry after falling")


func test_forest_gate_and_shop() -> void:
	GameState.flags.erase("FLAG_ELA_FOREST_OPEN")
	game.enter_area("AREA_ELA_TOWN", "default")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_ELA_FOREST"), "forest closed before Mara opens it")
	Dialogue.talk_to("NPC_ELIO_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "Elio's shop")
	GameState.currency = 200
	game.shop_menu.buy("ITEM_LEAF_CHARM_001")
	eq(Inventory.count("ITEM_LEAF_CHARM_001"), 1, "charm bought")
	Inventory.equip("ITEM_LEAF_CHARM_001")
	eq(Stats.defense(), 4, "charm defense")
	game.shop_menu.close_menu()


func test_elaris_enemies_and_miniboss_flag() -> void:
	Inventory.grant_unique("WEAPON_WORLD_BLADE_001")
	Inventory.equip("WEAPON_WORLD_BLADE_001")
	game.enter_area("AREA_ELA_DUNGEON", "default")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_ELA_ROOT_ARENA"), "arena closed")
	var k: Enemy = game.area.entities["SPAWN_ELA_DUNGEON_KRIECHER"]
	var guard := 0
	while not k.is_dead() and guard < 100:
		k.take_hit(Stats.attack(), 8.0)
		guard += 1
	check(k.is_dead(), "Wurzelkriecher defeated")
	check(GameState.has_flag("FLAG_ELA_ROOTS_PARTED"), "roots parted")
	check(game.area.is_exit_open("AREA_ELA_ROOT_ARENA"), "arena open")
	check(GameState.defeated.has("SPAWN_ELA_DUNGEON_KRIECHER"), "miniboss persistent")


func test_rovan_fights_in_melee() -> void:
	game.enter_area("AREA_ELA_FOREST", "default")
	await physics_frames(2)
	Effects.apply({"type": "join_party", "id": "PARTY_ROVAN_001"})
	await physics_frames(2)
	var rovan: Companion = game.companions["PARTY_ROVAN_001"]
	var p: Enemy = game.area.entities["SPAWN_ELA_FOREST_PILZ_3"]
	game.player.invulnerable_time = 999.0
	game.player.global_position = p.global_position + Vector3(0, 0, 3)
	rovan.snap_to_player()
	var hits := []
	rovan.attacked.connect(func(t): hits.append(t))
	await physics_frames(240)
	check(hits.size() >= 1, "Rovan hit in melee (%d)" % hits.size())
	check(p.hp < p.max_hp or p.is_dead(), "damage")
