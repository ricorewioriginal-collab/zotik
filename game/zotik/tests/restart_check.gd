extends SceneTree
## Stage 2 of the golden path: runs in a NEW process after the game was
## quit. Loads slot 1 through the title flow and compares the persistent
## world state with the state written before quitting. Exit 0 = identical.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var save_system = root.get_node("SaveSystem")
	var game_state = root.get_node("GameState")
	save_system.save_dir = "user://golden_saves/"
	var expected = JSON.parse_string(FileAccess.get_file_as_string("user://golden_expected.json"))
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
	print("RESTART_CHECK ", "PASS" if ok else "FAIL")
	for s in range(1, 4):
		save_system.delete_slot(s)
	DirAccess.remove_absolute("user://golden_expected.json")
	quit(0 if ok else 1)
