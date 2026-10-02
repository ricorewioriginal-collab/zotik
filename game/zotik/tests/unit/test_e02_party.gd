extends TestCase

const LYRA := "PARTY_LYRA_001"
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


func _join() -> Companion:
	Effects.apply({"type": "join_party", "id": LYRA})
	await physics_frames(2)
	return game.companions.get(LYRA)


func test_arrival_in_elaris_joins_lyra_once() -> void:
	GameState.set_flag("FLAG_LUN_CHAPTER_COMPLETE")
	GameState.set_flag("FLAG_LUN_LYRA_MET")
	game.enter_area("AREA_ELA_TOWN", "travel")
	await physics_frames(4)
	eq(Dialogue.active_id, "CUT_ELA_ARRIVAL_001", "arrival scene")
	await finish_dialogues()
	eq(GameState.party, [LYRA] as Array[String], "Lyra joined")
	check(game.companions.has(LYRA), "companion spawned")
	Effects.apply({"type": "join_party", "id": LYRA})
	eq(GameState.party.size(), 1, "no duplicate member")
	game.enter_area("AREA_ELA_TOWN", "travel")
	await physics_frames(4)
	check(not Dialogue.is_active(), "arrival scene only once")
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	check(not game.area.entities["NPC_LYRA_001"].visible, "Lyra NPC hidden while she travels with Zotik")


func test_follows_player_and_survives_area_change() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var lyra := await _join()
	check(lyra != null, "spawned")
	game.player.global_position = Vector3(0, 0, -10)
	await physics_frames(120)
	check(lyra.global_position.distance_to(game.player.global_position) < 5.0, "follows (%.1f m)" % lyra.global_position.distance_to(game.player.global_position))
	game.enter_area("AREA_LUN_FOREST", "AREA_LUN_VILLAGE")
	await physics_frames(3)
	check(is_instance_valid(lyra) and lyra.global_position.distance_to(game.player.global_position) < 5.0, "came along into the forest")


func test_attacks_enemies_near_player() -> void:
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	var lyra := await _join()
	var r: Enemy = game.area.entities["SPAWN_LUN_FOREST_RIFTLING_3"]
	game.player.global_position = r.global_position + Vector3(0, 0, 4)
	game.player.invulnerable_time = 999.0
	lyra.snap_to_player()
	var hits := []
	lyra.attacked.connect(func(t): hits.append(t))
	await physics_frames(180)
	check(hits.size() >= 2, "Lyra attacked (%d)" % hits.size())
	check(r.hp < r.max_hp or r.is_dead(), "damage dealt")


func test_heals_player_when_low_with_cooldown() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var lyra := await _join()
	var heals := []
	lyra.healed_player.connect(func(a): heals.append(a))
	GameState.player.hp = 30
	await physics_frames(3)
	eq(heals, [25], "healed 25")
	eq(int(GameState.player.hp), 55, "hp after heal")
	GameState.player.hp = 20
	await physics_frames(30)
	eq(heals.size(), 1, "cooldown prevents a second heal")


func test_passive_during_dialogue_and_persists() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var lyra := await _join()
	Dialogue.talk_to("NPC_FINN_001")
	GameState.player.hp = 10
	var heals := []
	lyra.healed_player.connect(func(a): heals.append(a))
	await physics_frames(10)
	eq(heals.size(), 0, "no actions during dialogue")
	await finish_dialogues()
	SaveSystem.save_slot(1)
	GameState.reset_new_game()
	App.continue_game(1)
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)
	check(game.companions.has(LYRA), "Lyra back after loading")
