extends TestCase
## W05: reliable saves with several slots: browser mirror, autosave slot, overwrite safety.

var mirror := {}


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves_w05/"
	for s in range(0, 4):
		SaveSystem.delete_slot(s)
	GameState.reset_new_game()
	Customization.ensure_valid()
	mirror = {}


func after_each() -> void:
	for s in range(0, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.mirror_override = null
	SaveSystem.autosave_ready = false
	SaveSystem.save_dir = "user://saves/"


func _state(area: String, lun: int) -> void:
	GameState.player.area = area
	GameState.currency = lun


func test_three_slots_and_the_autosave_are_independent() -> void:
	_state("AREA_LUN_VILLAGE", 111)
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "slot 1")
	_state("AREA_ELA_TOWN", 222)
	eq(SaveSystem.save_slot(2), SaveSystem.Status.OK, "slot 2")
	_state("AREA_VAL_MARKET", 333)
	eq(SaveSystem.save_slot(3), SaveSystem.Status.OK, "slot 3")
	_state("AREA_SOL_OASIS", 444)
	eq(SaveSystem.save_slot(SaveSystem.AUTO_SLOT), SaveSystem.Status.OK, "autosave")
	for pair in [[1, 111, "AREA_LUN_VILLAGE"], [2, 222, "AREA_ELA_TOWN"], [3, 333, "AREA_VAL_MARKET"], [0, 444, "AREA_SOL_OASIS"]]:
		GameState.reset_new_game()
		eq(SaveSystem.load_slot(pair[0]), SaveSystem.Status.OK, "load %d" % pair[0])
		eq(GameState.currency, pair[1], "slot %d content" % pair[0])
		eq(SaveSystem.slot_info(pair[0]).area, pair[2], "slot %d info" % pair[0])


func test_repeated_overwrites_stay_valid() -> void:
	for i in 5:
		_state("AREA_LUN_VILLAGE", 100 + i)
		eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "save %d" % i)
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "load")
	eq(GameState.currency, 104, "latest content")
	check(not FileAccess.file_exists(SaveSystem.slot_path(1) + ".tmp"), "no temp file left over")


func test_browser_mirror_restores_a_lost_file() -> void:
	SaveSystem.mirror_override = mirror
	_state("AREA_AQU_DOME", 777)
	eq(SaveSystem.save_slot(2), SaveSystem.Status.OK, "save")
	check(mirror.has(2), "mirrored")
	DirAccess.remove_absolute(SaveSystem.slot_path(2))
	check(SaveSystem.any_save_exists(), "the mirror counts as a save")
	eq(SaveSystem.slot_info(2).status, SaveSystem.Status.OK, "info from the mirror")
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(2), SaveSystem.Status.OK, "loaded from the mirror")
	eq(GameState.currency, 777, "content restored")


func test_newest_copy_wins_between_file_and_mirror() -> void:
	SaveSystem.mirror_override = mirror
	_state("AREA_LUN_VILLAGE", 1)
	SaveSystem.save_slot(1)
	var old_text: String = mirror[1]
	await tree.create_timer(1.1).timeout
	_state("AREA_LUN_VILLAGE", 2)
	SaveSystem.save_slot(1)
	mirror[1] = old_text  # the mirror is stale, the file is newer
	GameState.reset_new_game()
	SaveSystem.load_slot(1)
	eq(GameState.currency, 2, "file is newer")
	var new_text: String = JSON.stringify(JSON.parse_string(old_text))
	DirAccess.remove_absolute(SaveSystem.slot_path(1))
	GameState.reset_new_game()
	SaveSystem.load_slot(1)
	eq(GameState.currency, 1, "only the stale mirror is left")
	check(new_text != "", "sanity")


func test_a_corrupt_file_falls_back_to_the_mirror_or_backup() -> void:
	SaveSystem.mirror_override = mirror
	_state("AREA_LUN_VILLAGE", 5)
	SaveSystem.save_slot(1)
	var f := FileAccess.open(SaveSystem.slot_path(1), FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "mirror covers the corrupt file")
	eq(GameState.currency, 5, "content")
	SaveSystem.mirror_override = null
	_state("AREA_LUN_VILLAGE", 6)
	SaveSystem.save_slot(1)
	_state("AREA_LUN_VILLAGE", 7)
	SaveSystem.save_slot(1)
	f = FileAccess.open(SaveSystem.slot_path(1), FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.RECOVERED_FROM_BACKUP, "backup covers it without a mirror")
	eq(GameState.currency, 6, "previous save")


func test_autosave_only_while_a_game_runs() -> void:
	_state("AREA_LUN_VILLAGE", 9)
	SaveSystem.autosave()
	eq(SaveSystem.slot_info(SaveSystem.AUTO_SLOT).status, SaveSystem.Status.EMPTY, "nothing without a running game")
	SaveSystem.autosave_ready = true
	SaveSystem.autosave()
	eq(SaveSystem.slot_info(SaveSystem.AUTO_SLOT).status, SaveSystem.Status.OK, "autosave written")


func test_delete_clears_file_and_mirror() -> void:
	SaveSystem.mirror_override = mirror
	SaveSystem.save_slot(3)
	SaveSystem.delete_slot(3)
	check(not mirror.has(3) and not FileAccess.file_exists(SaveSystem.slot_path(3)), "gone everywhere")
	eq(SaveSystem.slot_info(3).status, SaveSystem.Status.EMPTY, "empty")


func test_save_menu_asks_before_overwriting() -> void:
	var menu := SaveMenu.new()
	tree.root.add_child(menu)
	_state("AREA_LUN_VILLAGE", 10)
	menu.save(1)
	eq(SaveSystem.slot_info(1).status, SaveSystem.Status.OK, "empty slot saves at once")
	_state("AREA_LUN_VILLAGE", 20)
	menu.save(1)
	GameState.reset_new_game()
	SaveSystem.load_slot(1)
	eq(GameState.currency, 10, "first press only asks")
	_state("AREA_LUN_VILLAGE", 20)
	menu.save(1)
	GameState.reset_new_game()
	SaveSystem.load_slot(1)
	eq(GameState.currency, 20, "second press overwrites")
	menu.queue_free()


func test_export_code_roundtrip_to_another_slot() -> void:
	_state("AREA_AQU_DOME", 4242)
	GameState.inventory["ITEM_HI_POTION_001"] = 7
	SaveSystem.save_slot(1)
	var code := SaveSystem.export_code(1)
	check(code.begins_with("ZOTIK1:") and code.length() > 50, "code looks right")
	check(not code.contains("\n") and not code.contains(" "), "code is one clean line")
	eq(SaveSystem.import_code(code, 3), SaveSystem.Status.OK, "import into slot 3")
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(3), SaveSystem.Status.OK, "load the imported slot")
	eq(GameState.currency, 4242, "Lun")
	eq(GameState.inventory.get("ITEM_HI_POTION_001"), 7, "items")
	eq(GameState.player.area, "AREA_AQU_DOME", "area")
	eq(SaveSystem.import_code("  " + code.insert(20, "\n") + "\n", 2), SaveSystem.Status.OK, "pasted with line breaks and spaces")
	eq(SaveSystem.export_code(2) != "", true, "slot 2 now exports too")


func test_autosave_can_be_exported() -> void:
	_state("AREA_LUN_VILLAGE", 31)
	SaveSystem.save_slot(SaveSystem.AUTO_SLOT)
	eq(SaveSystem.import_code(SaveSystem.export_code(SaveSystem.AUTO_SLOT), 1), SaveSystem.Status.OK, "autosave -> slot 1")


func test_bad_codes_are_refused() -> void:
	_state("AREA_LUN_VILLAGE", 1)
	SaveSystem.save_slot(1)
	var code := SaveSystem.export_code(1)
	eq(SaveSystem.import_code("", 2), SaveSystem.Status.CORRUPT, "empty")
	eq(SaveSystem.import_code("hello", 2), SaveSystem.Status.CORRUPT, "no prefix")
	eq(SaveSystem.import_code(code.substr(0, code.length() - 40), 2), SaveSystem.Status.CORRUPT, "truncated")
	eq(SaveSystem.import_code("ZOTIK1:abc:AAAA", 2), SaveSystem.Status.CORRUPT, "bad size")
	eq(SaveSystem.import_code("ZOTIK1:99999999999:AAAA", 2), SaveSystem.Status.CORRUPT, "absurd size")
	eq(SaveSystem.import_code(code, 0), SaveSystem.Status.IO_ERROR, "the autosave slot is not an import target")
	eq(SaveSystem.import_code(code, 4), SaveSystem.Status.IO_ERROR, "no such slot")
	# a valid envelope whose content was changed (checksum no longer fits)
	var env = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(1)))
	env.data.currency = 999999
	var bytes := JSON.stringify(env).to_utf8_buffer()
	var forged := "ZOTIK1:%d:%s" % [bytes.size(), Marshalls.raw_to_base64(bytes.compress(FileAccess.COMPRESSION_DEFLATE))]
	eq(SaveSystem.import_code(forged, 2), SaveSystem.Status.CORRUPT, "tampered content")
	eq(SaveSystem.slot_info(2).status, SaveSystem.Status.EMPTY, "nothing was written")


func test_transfer_menu_imports_with_confirmation() -> void:
	_state("AREA_LUN_VILLAGE", 55)
	SaveSystem.save_slot(1)
	var code := SaveSystem.export_code(1)
	var menu := TransferMenu.new()
	tree.root.add_child(menu)
	menu.open()
	menu._import_text = code
	menu._import(2)
	eq(SaveSystem.slot_info(2).status, SaveSystem.Status.OK, "empty slot imports at once")
	menu._import_text = code
	menu._import(2)
	eq(menu._confirm, 2, "a used slot asks first")
	menu._import(2)
	eq(menu._confirm, -1, "the second press imports and resets the question")
	menu._import_text = "kaputt"
	menu._import(3)
	check(menu._result.contains("beschädigt"), "bad code reports an error")
	menu._make_code(1)
	check(menu._export_code == code, "export code shown in the menu")
	menu.queue_free()
