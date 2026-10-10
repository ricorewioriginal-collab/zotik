extends Node
## Application core: version info and scene switching.

const VERSION := "0.4.0"
const SCENE_BOOT := "res://scenes/boot/boot.tscn"
const SCENE_TITLE := "res://scenes/title/title.tscn"
const SCENE_GAME_ROOT := "res://scenes/game_root/game_root.tscn"
const SCENE_CHARACTER_CREATOR := "res://scenes/character_creator/character_creator.tscn"

signal scene_changed(path: String)
signal input_device_changed(gamepad: bool)
signal new_game_started

var current_scene_path := ""
## Set by continue_game(): the game root restores the saved position.
var pending_load := false


func _ready() -> void:
	Gamepad.install()


func _input(event: InputEvent) -> void:
	var was := Gamepad.active
	Gamepad.note_event(event)
	if Gamepad.active != was:
		input_device_changed.emit(Gamepad.active)


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


func continue_game(slot: int) -> int:
	var status: int = SaveSystem.load_slot(slot)
	if status == SaveSystem.Status.OK or status == SaveSystem.Status.RECOVERED_FROM_BACKUP:
		pending_load = true
		goto_scene(SCENE_GAME_ROOT)
	return status


func quit_game() -> void:
	get_tree().quit()
