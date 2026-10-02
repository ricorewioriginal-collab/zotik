extends Node

signal state_changed(previous_state: int, current_state: int)

enum State {
	BOOT,
	MAIN_MENU,
	PROFILE_SELECTION,
	LOADING,
	WORLD,
	TOWN,
	DUNGEON,
	COMBAT,
	PAUSE,
	DIALOGUE,
	CUTSCENE,
	VEHICLE,
	HOUSING,
	MULTIPLAYER,
	CASINO,
	GAME_OVER,
}

var current_state: State = State.BOOT
var pending_save: Dictionary = {}


func start_new_game() -> void:
	pending_save = {}
	SceneManager.change_scene("res://scenes/world/start_area.tscn", State.WORLD)


func continue_game() -> void:
	pending_save = SaveManager.load_slot(1)
	if not pending_save.is_empty():
		var destination := "res://scenes/world/forest.tscn" if pending_save.get("region", "start") == "forest" else "res://scenes/world/start_area.tscn"
		SceneManager.change_scene(destination, State.WORLD)


func set_state(next_state: State) -> void:
	if current_state == next_state:
		return
	var previous_state := current_state
	current_state = next_state
	state_changed.emit(previous_state, current_state)
