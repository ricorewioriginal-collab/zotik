extends Node
class_name SaveManager

const SLOT_DIR := "user://saves/"

func save_game(slot: int, state: Dictionary) -> bool:
    DirAccess.make_dir_absolute(SLOT_DIR)
    var file := FileAccess.open(SLOT_DIR + "slot_%02d.json" % slot, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(state))
    return true

func load_game(slot: int) -> Dictionary:
    var path := SLOT_DIR + "slot_%02d.json" % slot
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Dictionary else {}
