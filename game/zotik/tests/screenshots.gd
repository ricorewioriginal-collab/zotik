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
	game.player.global_position = Vector3(8, 0, 26)
	game.player.camera_pivot.rotation.y = 0.5
	await _shot("04a_village_house")
	game.player.global_position = Vector3(-2, 0, 2)
	game.player.camera_pivot.rotation.y = PI
	game.update_beacon()
	await _shot("04b_village_beacon_on_mira")
	game.pause_menu.open()
	await _shot("04c_help_and_settings")
	game.pause_menu._open_guide()
	await _shot("04d_guide")
	game.ui.get_node("GuideMenu").close_menu()
	game.pause_menu.close_menu()
	gs.set_flag("FLAG_LUN_BRIDGE_ACTIVE")
	game.enter_area("AREA_LUN_RIFT_CAVE", "default")
	game.player.camera_pivot.rotation.y = 0.0
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
	for f in ["FLAG_ELA_CHAPTER_COMPLETE", "FLAG_VAL_ARRIVED", "FLAG_VAL_CANALS_OPEN", "FLAG_VAL_WAECHTER_MET"]:
		gs.set_flag(f)
	game.enter_area("AREA_VAL_MARKET", "default")
	game.player.global_position = Vector3(-10, 0, 18)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("11_valdoria_market_casino")
	game.enter_area("AREA_VAL_CANALS", "default")
	game.player.global_position = Vector3(0, 0, 4)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("12_canals_valves")
	game.enter_area("AREA_VAL_FLOODGATE", "default")
	game.player.global_position = Vector3(0, 0, 7)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("13_kanalwaechter")
	gs.set_flag("FLAG_SOL_ARRIVED")
	game.enter_area("AREA_SOL_OASIS", "default")
	game.player.global_position = Vector3(-2, 0, 12)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("15_solmera_oasis")
	game.enter_area("AREA_SOL_BAZAAR", "default")
	game.player.global_position = Vector3(2, 0, 4)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("16_solmera_bazaar")
	gs.set_flag("FLAG_SOL_DUNES_OPEN")
	game.enter_area("AREA_SOL_DUNES", "default")
	game.player.global_position = Vector3(0, 0, 16)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("17_solmera_dunes")
	gs.set_flag("FLAG_SOL_RUINS_OPEN")
	game.enter_area("AREA_SOL_SUNKEN", "default")
	game.player.global_position = Vector3(0, 0, -2)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("18_solmera_sunken_city")
	for f in ["FLAG_SOL_MIRRORS_DONE", "FLAG_SOL_WAECHTER_DEFEATED"]:
		gs.set_flag(f)
	game.enter_area("AREA_SOL_ARENA", "default")
	game.player.global_position = Vector3(0, 0, 8)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("19_kharos_arena")
	while dlg.is_active():
		dlg.advance()
	gs.set_flag("FLAG_AQU_ARRIVED")
	game.enter_area("AREA_AQU_DOME", "default")
	game.player.global_position = Vector3(-2, 0, 12)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("20_aqualis_dome")
	game.enter_area("AREA_AQU_HARBOUR", "default")
	game.player.global_position = Vector3(2, 0, 4)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("21_aqualis_harbour")
	gs.set_flag("FLAG_AQU_CAVES_OPEN")
	game.enter_area("AREA_AQU_CAVES", "default")
	game.player.global_position = Vector3(0, 0, 16)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("22_aqualis_caves")
	gs.set_flag("FLAG_AQU_ARCHIVE_OPEN")
	game.enter_area("AREA_AQU_ARCHIVE", "default")
	game.player.global_position = Vector3(0, 0, -2)
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("23_aqualis_archive")
	gs.set_flag("FLAG_AQU_WAECHTER_DEFEATED")
	gs.set_flag("FLAG_AQU_NERYX_MET")
	game.enter_area("AREA_AQU_ABYSS", "default")
	game.player.global_position = Vector3(0, 0, 6)
	game.player.camera_pivot.rotation.y = 0.0
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("24_aqualis_neryx")
	for f in ["FLAG_FRO_FOREST_OPEN", "FLAG_FRO_CITY_OPEN", "FLAG_FRO_ICE_DONE", "FLAG_FRO_WAECHTER_DEFEATED", "FLAG_FRO_AVARN_MET", "FLAG_FRO_ARRIVED"]:
		gs.set_flag(f)
	for pair in [["AREA_FRO_VILLAGE", "25_frosthain_village", Vector3(0, 0, 14)], ["AREA_FRO_FOREST", "26_frosthain_forest", Vector3(0, 0, 16)], ["AREA_FRO_CITY", "27_frosthain_city", Vector3(0, 0, 8)], ["AREA_FRO_CORE", "28_frosthain_avarn", Vector3(0, 0, 6)]]:
		game.enter_area(pair[0], "default")
		game.player.global_position = pair[2]
		game.player.camera_pivot.rotation.y = 0.0
		for c in game.companions.values():
			c.snap_to_player()
		await _shot(pair[1])
	for f in ["FLAG_IGN_ASH_OPEN", "FLAG_IGN_MINES_OPEN", "FLAG_IGN_VALVES_DONE", "FLAG_IGN_WAECHTER_DEFEATED", "FLAG_IGN_MAGMARION_MET", "FLAG_IGN_ARRIVED"]:
		gs.set_flag(f)
	for pair in [["AREA_IGN_VILLAGE", "29_ignara_village", Vector3(0, 0, 14)], ["AREA_IGN_ASH", "30_ignara_ash", Vector3(0, 0, 16)], ["AREA_IGN_MINES", "31_ignara_mines", Vector3(0, 0, 8)], ["AREA_IGN_HEART", "32_ignara_magmarion", Vector3(0, 0, 6)]]:
		game.enter_area(pair[0], "default")
		game.player.global_position = pair[2]
		game.player.camera_pivot.rotation.y = 0.0
		for c in game.companions.values():
			c.snap_to_player()
		await _shot(pair[1])
	for f in ["FLAG_NOC_LANES_OPEN", "FLAG_NOC_NULL_OPEN", "FLAG_NOC_MEMORY_DONE", "FLAG_NOC_WAECHTER_DEFEATED", "FLAG_NOC_HUETER_MET", "FLAG_NOC_ARRIVED"]:
		gs.set_flag(f)
	for pair in [["AREA_NOC_CITY", "33_noctaris_city", Vector3(0, 0, 14)], ["AREA_NOC_LANES", "34_noctaris_lanes", Vector3(0, 0, 16)], ["AREA_NOC_NULL", "35_noctaris_null", Vector3(0, 0, 8)], ["AREA_NOC_CORE", "36_noctaris_core", Vector3(0, 0, 6)]]:
		game.enter_area(pair[0], "default")
		game.player.global_position = pair[2]
		game.player.camera_pivot.rotation.y = 0.0
		for c in game.companions.values():
			c.snap_to_player()
		await _shot(pair[1])
	for f in ["FLAG_AST_ISLES_OPEN", "FLAG_AST_RUINS_OPEN", "FLAG_AST_DIALS_DONE", "FLAG_AST_WAECHTER_DEFEATED", "FLAG_AST_SOLYRA_MET", "FLAG_AST_ARRIVED"]:
		gs.set_flag(f)
	for pair in [["AREA_AST_PORT", "37_astralis_port", Vector3(0, 0, 14)], ["AREA_AST_ISLES", "38_astralis_isles", Vector3(0, 0, 16)], ["AREA_AST_RUINS", "39_astralis_ruins", Vector3(0, 0, 8)], ["AREA_AST_SUMMIT", "40_astralis_summit", Vector3(0, 0, 6)]]:
		game.enter_area(pair[0], "default")
		game.player.global_position = pair[2]
		game.player.camera_pivot.rotation.y = 0.0
		for c in game.companions.values():
			c.snap_to_player()
		await _shot(pair[1])
	for f in ["FLAG_ELY_LAYERS_OPEN", "FLAG_ELY_VOID_OPEN", "FLAG_ELY_ECHO_DONE", "FLAG_ELY_WAECHTER_DEFEATED", "FLAG_ELY_ELYON_MET", "FLAG_ELY_ARRIVED"]:
		gs.set_flag(f)
	for pair in [["AREA_ELY_CITY", "41_elyndra_city", Vector3(0, 0, 14)], ["AREA_ELY_LAYERS", "42_elyndra_layers", Vector3(0, 0, 16)], ["AREA_ELY_VOID", "43_elyndra_void", Vector3(0, 0, 8)], ["AREA_ELY_CORE", "44_elyndra_core", Vector3(0, 0, 6)]]:
		game.enter_area(pair[0], "default")
		game.player.global_position = pair[2]
		game.player.camera_pivot.rotation.y = 0.0
		for c in game.companions.values():
			c.snap_to_player()
		await _shot(pair[1])
	gs.set_flag("FLAG_GAME_COMPLETE")
	gs.set_flag("FLAG_END_WAECHTER_DEFEATED")
	for pair in [["AREA_END_HUB", "45_weltenriss_hub", Vector3(0, 0, 18)], ["AREA_END_WAECHTER", "46_weltenriss_superboss", Vector3(0, 0, 8)], ["AREA_END_D1", "47_endgame_dungeon", Vector3(0, 0, 24)]]:
		game.enter_area(pair[0], "default")
		game.player.global_position = pair[2]
		game.player.camera_pivot.rotation.y = 0.0
		for c in game.companions.values():
			c.snap_to_player()
		await _shot(pair[1])
	game.enter_area("AREA_VAL_MARKET", "default")
	game.player.global_position = Vector3(0, 0, 12)
	for _i in 20:
		if dlg.is_active():
			dlg.advance()
	game.player.spring_arm.rotation.x = deg_to_rad(-20.0)
	game.touch.force = true
	for c in game.companions.values():
		c.snap_to_player()
	await _shot("14_android_touch_controls")
	quit()
