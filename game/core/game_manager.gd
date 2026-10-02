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


func set_state(next_state: State) -> void:
	if current_state == next_state:
		return
	var previous_state := current_state
	current_state = next_state
	state_changed.emit(previous_state, current_state)
