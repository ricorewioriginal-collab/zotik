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
	check(house is StaticBody3D and house.has_node("Roof"), "house keeps collision and gets a roof")
	var floor_mesh := game.area.get_tree().get_nodes_in_group("ground")[0].get_child(1) as MeshInstance3D
	check((floor_mesh.material_override as StandardMaterial3D).albedo_texture != null, "textured floor")
	check(game.area.has_node("Boundary"), "visible boundary")
