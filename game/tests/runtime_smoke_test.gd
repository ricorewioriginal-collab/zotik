extends SceneTree

const TEST_SLOT := 3

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var saves: Node = root.get_node("SaveManager")
	var active_save := _snapshot("user://saves/slot_1.json")
	var active_backup := _snapshot("user://saves/slot_1.json.bak")
	var save_path := "user://saves/slot_%d.json" % TEST_SLOT
	var backup_path := save_path + ".bak"
	var original_save := _snapshot(save_path)
	var original_backup := _snapshot(backup_path)
	var payload := {
		"region": "test",
		"position": [17, 23],
		"collected_items": ["zotik:item:test"],
	}
	_check(saves.save_slot(TEST_SLOT, payload), "Saving a valid slot should succeed.")
	var loaded: Dictionary = saves.load_slot(TEST_SLOT)
	_check(loaded.get("region") == "test", "Save/load should preserve the region.")
	_check(loaded.get("position") == [17.0, 23.0], "Save/load should preserve numeric positions.")
	_check(loaded.get("collected_items") == ["zotik:item:test"], "Save/load should preserve item IDs.")
	_check(saves.save_slot(TEST_SLOT, {"region": "updated"}), "Overwriting a slot should succeed.")
	_check(FileAccess.file_exists(backup_path), "Overwriting a slot should create a backup.")
	var corrupt_file := FileAccess.open(save_path, FileAccess.WRITE)
	if corrupt_file == null:
		_check(false, "The test save should be writable.")
	else:
		corrupt_file.store_string("not-json")
		corrupt_file.close()
		_check(saves.load_slot(TEST_SLOT).is_empty(), "Malformed save files should be rejected.")

	var region_scene: PackedScene = load("res://scenes/world/start_area.tscn")
	var region: Node = region_scene.instantiate()
	root.add_child(region)
	current_scene = region
	await process_frame
	var player: Node = region.get_node("Zotik")
	region.get_node("Keeper").interact(player)
	_check(region.message_label.text.contains("Willkommen"), "The NPC should display its greeting.")
	var enemy: Node = region.get_node("ForestWisp")
	enemy.take_damage(3)
	await process_frame
	_check(not is_instance_valid(enemy), "The enemy should be removed when defeated.")
	region.get_node("HealingFruit").interact(player)
	_check("zotik:item:healing_fruit" in region.collected_items, "The pickup should record its stable item ID.")
	region.get_node("ResonanceSwitch").interact(player)
	region.get_node("SealedGate").interact(player)
	_check(region.gate_open, "The solved resonance puzzle should open the gate.")
	region.get_node("ForestPortal").interact(player)
	await process_frame
	var forest := current_scene
	_check(forest != null and forest.scene_file_path.ends_with("forest.tscn"), "The portal should load the forest region.")
	if forest != null:
		_check("zotik:item:healing_fruit" in forest.collected_items, "Items should persist through a region transition.")
		forest.get_node("ReturnPortal").interact(forest.get_node("Zotik"))
		await process_frame
		var returned_region := current_scene
		_check(returned_region != null and returned_region.scene_file_path.ends_with("start_area.tscn"), "The return portal should restore the start region.")
		if returned_region != null:
			_check(returned_region.gate_open, "Puzzle progress should persist through a region transition.")
			_check(returned_region.get_node_or_null("HealingFruit") == null, "Collected items should remain absent after returning.")

	_restore("user://saves/slot_1.json", active_save)
	_restore("user://saves/slot_1.json.bak", active_backup)
	_restore(save_path, original_save)
	_restore(backup_path, original_backup)
	if failed:
		quit(1)
	else:
		print("ZOTIK_RUNTIME_SMOKE_TESTS_PASSED")
		quit()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _snapshot(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"exists": false, "bytes": PackedByteArray()}
	return {"exists": true, "bytes": FileAccess.get_file_as_bytes(path)}


func _restore(path: String, snapshot: Dictionary) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not snapshot["exists"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(absolute_path)
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "Could not restore the pre-test save file.")
		return
	file.store_buffer(snapshot["bytes"])
	file.close()
