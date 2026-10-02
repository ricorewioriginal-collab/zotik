extends Node
## Application core: version info and scene switching.

const VERSION := "0.1.0"
const SCENE_BOOT := "res://scenes/boot/boot.tscn"
const SCENE_TITLE := "res://scenes/title/title.tscn"
const SCENE_GAME_ROOT := "res://scenes/game_root/game_root.tscn"
const SCENE_CHARACTER_CREATOR := "res://scenes/character_creator/character_creator.tscn"

signal scene_changed(path: String)

var current_scene_path := ""


func goto_scene(path: String) -> Error:
	if not ResourceLoader.exists(path):
		push_error("App.goto_scene: missing scene %s" % path)
		return ERR_FILE_NOT_FOUND
	var err := get_tree().change_scene_to_file(path)
	if err == OK:
		current_scene_path = path
		scene_changed.emit(path)
	return err


func start_new_game() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	goto_scene(SCENE_CHARACTER_CREATOR)


func quit_game() -> void:
	get_tree().quit()
