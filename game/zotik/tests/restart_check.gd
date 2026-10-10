extends SceneTree
## Stage 2 of the golden path: runs in a NEW process after the game was
## quit. Loads slot 1 through the title flow and compares the persistent
## world state with the state written before quitting. Exit 0 = identical.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var all_ok := true
	var ran := 0
	var cases := {"user://golden_expected.json": "user://golden_saves/", "user://golden_expected_ela.json": "user://golden_saves_ela/", "user://golden_expected_val.json": "user://golden_saves_val/", "user://golden_expected_sol.json": "user://golden_saves_sol/", "user://golden_expected_aqu.json": "user://golden_saves_aqu/", "user://golden_expected_fro.json": "user://golden_saves_fro/", "user://golden_expected_ign.json": "user://golden_saves_ign/", "user://golden_expected_noc.json": "user://golden_saves_noc/", "user://golden_expected_ast.json": "user://golden_saves_ast/"}
	for exp_path in cases:
		if FileAccess.file_exists(exp_path):
			ran += 1
			var ok: bool = await _check(exp_path, cases[exp_path])
			print("RESTART_CHECK %s %s" % [exp_path.get_file(), "PASS" if ok else "FAIL"])
			all_ok = all_ok and ok
			DirAccess.remove_absolute(exp_path)
	all_ok = all_ok and ran > 0
	print("RESTART_CHECK ", "PASS" if all_ok else "FAIL")
	var save_system = root.get_node("SaveSystem")
	for dir in cases.values():
		save_system.save_dir = dir
		for s in range(1, 4):
			save_system.delete_slot(s)
	quit(0 if all_ok else 1)


func _check(exp_path: String, save_dir: String) -> bool:
	var save_system = root.get_node("SaveSystem")
	var game_state = root.get_node("GameState")
	save_system.save_dir = save_dir
	var expected = JSON.parse_string(FileAccess.get_file_as_string(exp_path))
	var ok := expected is Dictionary
	root.get_node("App").goto_scene("res://scenes/title/title.tscn")
	for i in 3:
		await process_frame
	ok = ok and current_scene.buttons.has("load_1")
	if ok:
		current_scene.buttons["load_1"].pressed.emit()
		for i in 4:
			await process_frame
		for i in 2:
			await physics_frame
		var actual = JSON.parse_string(JSON.stringify(game_state.to_dict()))
		# play_time keeps running after the load: it must continue from the
		# saved value, everything else must be identical.
		var dt := float(actual.play_time) - float(expected.play_time)
		ok = dt >= 0.0 and dt < 2.0
		if not ok:
			print("DIFF play_time: expected ", expected.play_time, " got ", actual.play_time)
		actual.erase("play_time")
		expected.erase("play_time")
		ok = ok and actual == expected
		if not ok:
			for k in expected:
				if actual.get(k) != expected[k]:
					print("DIFF ", k, ": expected ", expected[k], " got ", actual.get(k))
		ok = ok and current_scene.name == &"GameRoot" and current_scene.area.area_id == expected.player.area
	return ok
