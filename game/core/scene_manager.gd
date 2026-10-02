extends Node

signal scene_change_started(path: String)
signal scene_change_finished(path: String)

var _changing_scene := false


func change_scene(path: String, next_state: GameManager.State) -> void:
	if _changing_scene or not ResourceLoader.exists(path, "PackedScene"):
		push_error("SceneManager: Scene is unavailable: %s" % path)
		return
	_changing_scene = true
	GameManager.set_state(GameManager.State.LOADING)
	scene_change_started.emit(path)
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("SceneManager: Could not change to %s (error %d)." % [path, error])
		_changing_scene = false
		return
	GameManager.set_state(next_state)
	scene_change_finished.emit(path)
	_changing_scene = false
