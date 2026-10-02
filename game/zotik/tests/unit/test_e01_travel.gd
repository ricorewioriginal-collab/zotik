extends TestCase

const S := preload("res://core/save_system.gd")
var game: GameRoot


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves/"
	SaveSystem.reset_migrations()
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


func test_worlds_data_and_unlock() -> void:
	check(Content.world_unlocked("WORLD_LUNARIS"), "Lunaris open")
	check(not Content.world_unlocked("WORLD_ELARIS"), "Elaris locked before chapter 1 ends")
	check(not Content.world_unlocked("WORLD_VALDORIA"), "Valdoria sealed")
	GameState.set_flag("FLAG_LUN_CHAPTER_COMPLETE")
	check(Content.world_unlocked("WORLD_ELARIS"), "Elaris unlocked by chapter flag")
	eq(Content.world_of("AREA_ELA_TOWN"), "WORLD_ELARIS", "area world")


func test_world_map_travel_to_elaris_and_back() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	game.area.entities["TRAVEL_LUN_001"].interact(game.player)
	check(game.world_map.visible and not game.player.control_enabled, "world map open")
	var rows := game.world_map.list.get_child_count()
	eq(rows, 3, "three worlds listed")
	game.world_map.travel("WORLD_ELARIS")
	await frames(3)
	eq(game.area.area_id, "AREA_LUN_VILLAGE", "locked world: no travel")
	GameState.set_flag("FLAG_LUN_CHAPTER_COMPLETE")
	game.area.entities["TRAVEL_LUN_001"].interact(game.player)
	game.world_map.travel("WORLD_ELARIS")
	await frames(3)
	await physics_frames(2)
	eq(game.area.area_id, "AREA_ELA_TOWN", "arrived in Elaris")
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_ELA_ARRIVAL_001", "arrival scene plays")
	await finish_dialogues()
	check(not game.world_map.visible and game.player.control_enabled, "map closed, control back")
	game.area.entities["TRAVEL_ELA_001"].interact(game.player)
	game.world_map.travel("WORLD_LUNARIS")
	await frames(3)
	await physics_frames(2)
	eq(game.area.area_id, "AREA_LUN_VILLAGE", "back in Lunaris")
	check(game.player.global_position.distance_to(game.area.spawn_point("travel")) < 1.0, "at travel spawn")


func test_v1_save_migrates_to_v2() -> void:
	GameState.set_flag("FLAG_LUN_CHAPTER_COMPLETE")
	GameState.currency = 77
	SaveSystem.save_slot(1)
	var env = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(1)))
	env.schema_version = 1
	env.data.erase("party")
	env.checksum = SaveSystem._checksum(env.data)
	var f := FileAccess.open(SaveSystem.slot_path(1), FileAccess.WRITE)
	f.store_string(JSON.stringify(env))
	f.close()
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), S.Status.OK, "v1 save loads")
	eq(GameState.currency, 77, "data kept")
	eq(GameState.party, [] as Array[String], "party added by migration")
	check(GameState.has_flag("FLAG_LUN_CHAPTER_COMPLETE"), "flags kept")


func test_party_persists() -> void:
	GameState.party.append("PARTY_LYRA_001")
	var d := GameState.to_dict()
	GameState.reset_new_game()
	GameState.from_dict(d)
	eq(GameState.party, ["PARTY_LYRA_001"] as Array[String], "party round trip")


func test_beacon_routes_across_worlds() -> void:
	eq(Navigator.route("AREA_LUN_FOREST", "AREA_ELA_TOWN"), {"exit": "AREA_LUN_VILLAGE"}, "first walk to the Lunaris hub")
	eq(Navigator.route("AREA_LUN_VILLAGE", "AREA_ELA_TOWN"), {"travel": true}, "then use the Weltenstein")
	eq(Navigator.route("AREA_ELA_TOWN", "AREA_LUN_HOME"), {"travel": true}, "and back")
