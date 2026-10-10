extends SceneTree
## Renders every rigged enemy model in a row (needs a display, e.g. xvfb-run).
## godot --path game/zotik -s res://tools/enemy_preview.gd -- <out_dir>

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://shots"
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var app := root.get_node("App")
	app.start_new_game()
	app.goto_scene(app.SCENE_GAME_ROOT)
	for i in 4:
		await process_frame
	var dlg := root.get_node("Dialogue")
	while dlg.is_active():
		dlg.advance()
	var game = current_scene
	game.enter_area("AREA_LUN_RUINS", "default")
	game.player.global_position = Vector3(0, 0, 30)
	var ids := ["ENEMY_MONDFLEDERMAUS_001", "ENEMY_GRUENSCHLEIM_001", "ENEMY_WALDSPINNE_001", "ENEMY_SUMPFFROSCH_001", "ENEMY_KANALRATTE_001", "ENEMY_DUENENSCHLANGE_001", "ENEMY_WUESTENSKELETT_001", "ENEMY_RIFFFROSCH_001", "ENEMY_ERTRUNKENER_001", "ENEMY_EISFLEDERMAUS_001", "ENEMY_FROSTSPINNE_001", "ENEMY_GLUEHWESPE_001", "ENEMY_GLUTDRACHE_001", "ENEMY_SANDSKORPION_001", "ENEMY_ASCHEKAEFER_001", "ENEMY_KANALSCHLEIM_001"]
	var enemies := []
	for i in ids.size():
		var e = load("res://scenes/world/enemy.gd").create({"enemy": ids[i], "spawn": "SPAWN_PV_%d" % i, "pos": [0, 0, 0]})
		e.position = Vector3(-7.0 + (i % 8) * 2.0, 0, -3.0 + (i / 8) * 4.0)
		game.area.add_child(e)
		e.set_physics_process(false)
		e.label.hide()
		e.body_mesh.rotation.y = PI
		enemies.append(e)
	var cam := Camera3D.new()
	game.area.add_child(cam)
	cam.global_position = Vector3(0, 3.2, 6.2)
	cam.look_at(Vector3(0, 0.5, 0.0))
	cam.current = true
	game.player.hide()
	game.ui.hide()
	for f in 3:
		for e in enemies:
			e.body_mesh.animate(0, 0.0 if f == 0 else 3.0, 0.1)
		for i in 10:
			await process_frame
	root.get_texture().get_image().save_png(out.path_join("enemies.png"))
	print("SHOT enemies")
	quit()
