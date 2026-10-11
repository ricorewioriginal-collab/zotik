extends TestCase

const DIR := "user://test_saves/"
const S := preload("res://core/save_system.gd")


func before_each() -> void:
	SaveSystem.save_dir = DIR
	SaveSystem.reset_migrations()
	for slot in range(1, S.SLOT_COUNT + 1):
		SaveSystem.delete_slot(slot)
	GameState.reset_new_game()


func after_each() -> void:
	before_each()
	SaveSystem.save_dir = "user://saves/"


func _fill_state() -> void:
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	GameState.inventory = {"ITEM_HEALING_POTION_001": 3}
	GameState.equipment = {"weapon": "WEAPON_WORLD_BLADE_001"}
	GameState.currency = 137
	GameState.quests = {"QUEST_MAIN_LUN_001": {"state": "ACTIVE", "step": 4, "progress": 2}}
	GameState.chests_opened = {"CHEST_LUN_001": true}
	GameState.puzzles = {"PUZ_LUN_MOONGATE_001": {"state": "IN_PROGRESS", "current": [1, 0, 2] as Array[int], "hints": 1}}
	GameState.unique_rewards = {"WEAPON_WORLD_BLADE_001": true}
	GameState.customization = {"scarf_color": "blue"}
	GameState.player = {"area": "AREA_LUN_FOREST", "position": [1.5, 0.0, -3.25], "hp": 77, "max_hp": 100}


func test_round_trip_preserves_values_and_types() -> void:
	_fill_state()
	var before := GameState.to_dict()
	eq(SaveSystem.save_slot(1), S.Status.OK, "save")
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), S.Status.OK, "load")
	eq(GameState.to_dict(), before, "state after round trip")
	eq(GameState.currency, 137, "currency int")
	eq(GameState.inventory["ITEM_HEALING_POTION_001"], 3, "item count int")
	eq(GameState.quests["QUEST_MAIN_LUN_001"]["step"], 4, "quest step int")
	eq(GameState.quests["QUEST_MAIN_LUN_001"]["progress"], 2, "quest progress int")


func test_envelope_has_schema_and_checksum() -> void:
	SaveSystem.save_slot(1)
	var env = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(1)))
	eq(int(env.schema_version), S.SCHEMA_VERSION, "schema_version")
	check(str(env.checksum).length() == 64, "sha256 checksum")
	check(not FileAccess.file_exists(SaveSystem.slot_path(1) + ".tmp"), "no tmp left behind")


func test_second_save_creates_backup_of_previous() -> void:
	GameState.currency = 10
	SaveSystem.save_slot(1)
	GameState.currency = 20
	SaveSystem.save_slot(1)
	var bak = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(1) + ".bak"))
	eq(int(bak.data.currency), 10, "backup holds previous save")


func test_corrupt_save_recovers_from_backup() -> void:
	GameState.currency = 10
	SaveSystem.save_slot(1)
	GameState.currency = 20
	SaveSystem.save_slot(1)
	var f := FileAccess.open(SaveSystem.slot_path(1), FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	GameState.reset_new_game()
	eq(SaveSystem.slot_info(1).status, S.Status.RECOVERED_FROM_BACKUP, "slot info reports recoverable slot")
	eq(SaveSystem.load_slot(1), S.Status.RECOVERED_FROM_BACKUP, "status")
	eq(GameState.currency, 10, "state from backup")
	check(FileAccess.file_exists(SaveSystem.slot_path(1) + ".corrupt"), "corrupt file kept")


func test_tampered_save_is_detected() -> void:
	GameState.currency = 10
	SaveSystem.save_slot(1)
	var text := FileAccess.get_file_as_string(SaveSystem.slot_path(1)).replace("\"currency\": 10", "\"currency\": 99999")
	var f := FileAccess.open(SaveSystem.slot_path(1), FileAccess.WRITE)
	f.store_string(text)
	f.close()
	GameState.currency = 5
	eq(SaveSystem.load_slot(1), S.Status.CORRUPT, "tampered without backup")
	eq(GameState.currency, 5, "state untouched on failed load")


func test_newer_schema_rejected() -> void:
	SaveSystem.save_slot(1)
	var env = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(1)))
	env.schema_version = S.SCHEMA_VERSION + 1
	var f := FileAccess.open(SaveSystem.slot_path(1), FileAccess.WRITE)
	f.store_string(JSON.stringify(env))
	f.close()
	eq(SaveSystem.load_slot(1), S.Status.UNSUPPORTED_VERSION, "newer schema")


func test_older_schema_is_migrated() -> void:
	GameState.currency = 40
	SaveSystem.save_slot(1)
	var env = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(1)))
	env.schema_version = 0
	var f := FileAccess.open(SaveSystem.slot_path(1), FileAccess.WRITE)
	f.store_string(JSON.stringify(env))
	f.close()
	eq(SaveSystem.load_slot(1), S.Status.UNSUPPORTED_VERSION, "no migration registered for v0")
	SaveSystem.migrations[0] = func(d: Dictionary) -> Dictionary:
		d.currency = int(d.currency) + 1
		return d
	eq(SaveSystem.load_slot(1), S.Status.OK, "migrated load")
	eq(GameState.currency, 41, "migration applied")


func test_slots_are_independent() -> void:
	GameState.currency = 1
	SaveSystem.save_slot(1)
	GameState.currency = 2
	SaveSystem.save_slot(2)
	SaveSystem.load_slot(1)
	eq(GameState.currency, 1, "slot 1")
	SaveSystem.load_slot(2)
	eq(GameState.currency, 2, "slot 2")
	eq(SaveSystem.load_slot(3), S.Status.EMPTY, "slot 3 empty")
	eq(SaveSystem.save_slot(4), S.Status.IO_ERROR, "slot out of range")
	eq(SaveSystem.slot_info(2).area, "AREA_LUN_HOME", "slot info")


func test_settings_persist() -> void:
	var old_path: String = Settings.path
	Settings.path = "user://test_settings.cfg"
	Settings.set_value("music_volume", 0.25)
	Settings.set_value("camera_invert", true)
	Settings.set_value("text_speed", "fast")
	eq(Settings.save_settings(), OK, "save settings")
	Settings.values = Settings.DEFAULTS.duplicate()
	Settings.load_settings()
	eq(Settings.get_value("music_volume"), 0.25, "volume")
	eq(Settings.get_value("camera_invert"), true, "invert")
	eq(Settings.get_value("text_speed"), 1.0, "wrong type rejected")
	DirAccess.remove_absolute(Settings.path)
	Settings.path = old_path
	Settings.load_settings()
