extends SceneTree
## Comparison renders: current Zotik (ZotikVisual) next to the Hunyuan3D test
## model (static + rigged). PLACEHOLDER art. Needs a display (xvfb-run).
## godot --path game/zotik -s res://tests/screenshots_zotik_test.gd -- <out_dir>

var out := "user://shots"


func _initialize() -> void:
	_run.call_deferred()


func _shot(name: String, frames: int = 8) -> void:
	for i in frames:
		await process_frame
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("SHOT ", name)


func _run() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	# loaded at runtime: the classes use autoloads, unknown while this script compiles
	var visual_script: GDScript = load("res://scenes/player/zotik_visual.gd")
	var test_script: GDScript = load("res://scenes/player/zotik_test_model.gd")
	# neutral studio: current Zotik, static test model, rigged test model
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.32, 0.36, 0.42)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.75, 0.8)
	env.environment.ambient_light_energy = 0.6
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	stage.add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	floor_mi.mesh = pm
	stage.add_child(floor_mi)
	var current: Node3D = visual_script.new()
	stage.add_child(current)
	current.position = Vector3(-1.0, 0, 0)
	var stat: Node3D = test_script.create_static()
	stage.add_child(stat)
	var rigged: Node3D = test_script.create_rigged()
	stage.add_child(rigged)
	rigged.position = Vector3(1.0, 0, 0)
	for n in [current, stat, rigged]:
		n.rotation.y = PI  # face the camera (+Z)
	var labels := ["aktuell (ZotikVisual)", "Hunyuan3D statisch", "Hunyuan3D geriggt"]
	for i in 3:
		var l := Label3D.new()
		l.text = labels[i] + "\nPLACEHOLDER"
		l.font_size = 20
		l.pixel_size = 0.004
		l.position = Vector3(-1.0 + i, 1.55, 0)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stage.add_child(l)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.fov = 40
	cam.look_at_from_position(Vector3(0, 0.95, 4.6), Vector3(0, 0.62, 0))
	cam.current = true
	await _shot("zt_01_front")
	for n in [current, stat, rigged]:
		n.rotation.y = PI * 0.5
	await _shot("zt_02_side")
	for n in [current, stat, rigged]:
		n.rotation.y = 0.0
	await _shot("zt_03_back")
	for n in [current, stat, rigged]:
		n.rotation.y = PI * 0.8
	# animations on the rigged model (current Zotik plays the same states)
	for st in [["walk", 0.45], ["run", 0.3], ["attack", 0.45], ["cheer", 0.6]]:
		current.rig.play(st[0])
		rigged.rig.play(st[0])
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < int(st[1] * 1000.0):
			await process_frame
		await _shot("zt_anim_" + st[0], 1)
	# in game: village, next to Zotik
	var app := root.get_node("App")
	stage.queue_free()
	app.start_new_game()
	app.goto_scene(app.SCENE_GAME_ROOT)
	await process_frame
	var dlg := root.get_node("Dialogue")
	while dlg.is_active():
		dlg.advance()
	var game = current_scene
	game.enter_area("AREA_LUN_VILLAGE", "default")
	game.player.camera_pivot.rotation.y = 0.0
	await _shot("zt_04_ingame_village", 30)
	quit()
