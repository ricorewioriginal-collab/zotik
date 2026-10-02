extends SceneTree
## Renders reference screenshots (needs a display, e.g. xvfb-run).
## godot --path game/zotik -s res://tests/screenshots.gd -- <out_dir>

var out := "user://shots"


func _initialize() -> void:
	_run.call_deferred()


func _shot(name: String) -> void:
	for i in 8:
		await process_frame
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("SHOT ", name)


func _run() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var app := root.get_node("App")
	var gs := root.get_node("GameState")
	var dlg := root.get_node("Dialogue")
	app.goto_scene(app.SCENE_TITLE)
	await _shot("01_title")
	app.start_new_game()
	await _shot("02_character_creator")
	app.goto_scene(app.SCENE_GAME_ROOT)
	await _shot("03_intro_cutscene")
	while dlg.is_active():
		dlg.advance()
	var game = current_scene
	game.enter_area("AREA_LUN_VILLAGE", "default")
	game.player.global_position = Vector3(0, 0, 8)
	await _shot("04_village")
	game.player.global_position = Vector3(-2, 0, 2)
	game.player.camera_pivot.rotation.y = PI
	game.update_beacon()
	await _shot("04b_village_beacon_on_mira")
	gs.set_flag("FLAG_LUN_BRIDGE_ACTIVE")
	game.enter_area("AREA_LUN_RIFT_CAVE", "default")
	game.player.global_position = Vector3(0, 0, 14)
	await _shot("05_rift_cave_bridge")
	game.enter_area("AREA_LUN_ORUN_ARENA", "default")
	gs.set_flag("FLAG_LUN_ORUN_MET")
	game.player.global_position = Vector3(0, 0, 4)
	await _shot("06_orun_arena")
	for f in ["FLAG_LUN_CHAPTER_COMPLETE", "FLAG_ELA_ARRIVED", "FLAG_ELA_FOREST_OPEN", "FLAG_ELA_ROOTS_PARTED", "FLAG_ELA_QUEEN_MET"]:
		gs.set_flag(f)
	for m in ["PARTY_LYRA_001", "PARTY_NIA_001", "PARTY_ROVAN_001"]:
		gs.party.append(m)
	game.player.camera_pivot.rotation.y = 0.0
	game.enter_area("AREA_ELA_TOWN", "default")
	game.player.global_position = Vector3(0, 0, 16)
	await _shot("07_elaris_town_party")
	game.enter_area("AREA_ELA_FOREST", "default")
	game.player.global_position = Vector3(0, 0, 11)
	await _shot("08_elaris_moving_paths")
	game.enter_area("AREA_ELA_TOWER", "default")
	game.player.global_position = Vector3(0, 0, 3)
	await _shot("09_elaris_tower_pillars")
	game.enter_area("AREA_ELA_ROOT_ARENA", "default")
	game.player.global_position = Vector3(0, 0, 7)
	await _shot("10_wurzelkoenigin")
	quit()
