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


func test_prop_kinds_and_indoor() -> void:
	eq(Look.prop_kind("house_mira"), "house", "house")
	eq(Look.prop_kind("tree"), "tree", "tree")
	eq(Look.prop_kind("flooded_channel"), "water", "water")
	eq(Look.prop_kind("great_rift"), "glow", "rift glows")
	eq(Look.prop_kind("gate_wall_l"), "stone", "default stone")
	check(Look.is_indoor("AREA_VAL_CANALS", {}), "canals indoor")
	check(not Look.is_indoor("AREA_VAL_MARKET", {}), "market outdoor")
	check(Look.is_indoor("AREA_VAL_MARKET", {"indoor": true}), "layout override")


## W01: the browser and Android builds must stay light (owner: the web version
## hangs). The cheaper settings live in project.godot as feature overrides.
func test_web_and_mobile_stay_light() -> void:
	var text := FileAccess.get_file_as_string("res://project.godot")
	for key in ["msaa_3d.web=0", "msaa_3d.mobile=0", "directional_shadow/size.web=2048", "directional_shadow/size.mobile=2048"]:
		check(text.contains(key), "project.godot keeps " + key)
	var exports := FileAccess.get_file_as_string("res://export_presets.cfg")
	check(exports.contains("assets/characters/kaykit/*.glb"), "the big KayKit models stay out of the exports")
	# own icon and loading image instead of the default Godot ones
	var icon := str(ProjectSettings.get_setting("application/config/icon", ""))
	check(icon.contains("assets/icons/icon.png") and ResourceLoader.exists(icon), "project icon is Zotik")
	var splash := str(ProjectSettings.get_setting("application/boot_splash/image", ""))
	check(splash.contains("title_bg") and ResourceLoader.exists(splash), "loading image is the title art")
	for f in ["icon.ico", "android_main_192.png", "android_foreground_432.png", "android_background_432.png"]:
		check(FileAccess.file_exists("res://assets/icons/" + f), "icon file " + f)
	for key in CharacterRig.HUMAN_WEAPONS:
		check(ResourceLoader.exists(CharacterRig.WEAPON_DIR % CharacterRig.HUMAN_WEAPONS[key][0]), "baked weapon mesh for " + key)


func test_wall_segments_leave_exit_gaps() -> void:
	eq(Look.wall_segments(-10.0, 10.0, [], 6.0), [[-10.0, 10.0]], "no exits: one wall")
	eq(Look.wall_segments(-10.0, 10.0, [0.0], 6.0), [[-10.0, -3.0], [3.0, 10.0]], "gap in the middle")
	eq(Look.wall_segments(-10.0, 10.0, [-9.0], 6.0), [[-6.0, 10.0]], "gap at the corner")


func test_outdoor_sky_and_indoor_dark() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(1)
	var env: Environment = (game.area.get_node("WorldEnvironment") as WorldEnvironment).environment
	eq(env.background_mode, Environment.BG_SKY, "outdoor sky")
	check(env.glow_enabled, "glow")
	check((game.area.get_node("Sun") as DirectionalLight3D).shadow_enabled, "sun shadows")
	game.enter_area("AREA_LUN_RIFT_CAVE", "default")
	await physics_frames(1)
	env = (game.area.get_node("WorldEnvironment") as WorldEnvironment).environment
	eq(env.background_mode, Environment.BG_COLOR, "cave without sky")


func test_props_keep_names_collision_and_textures() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(1)
	var house: Node3D = game.area.find_children("PLACEHOLDER_house_mira", "", true, false)[0]
	check(house is StaticBody3D and (house.has_node("Building") or house.has_node("Roof")), "house keeps collision and gets a building")
	var floor_mesh := game.area.get_tree().get_nodes_in_group("ground")[0].get_child(1) as MeshInstance3D
	check((floor_mesh.material_override as StandardMaterial3D).albedo_texture != null, "textured floor")
	check(game.area.has_node("Boundary"), "visible boundary")
