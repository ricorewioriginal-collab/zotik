extends TestCase

const REQUIRED_ACTIONS := ["move_forward", "move_back", "move_left", "move_right", "attack", "dodge", "block", "lock_on", "jump", "interact", "camera_left", "camera_right", "use_item", "menu", "inventory", "quest_log", "puzzle_reset", "puzzle_hint"]


func test_autoloads_present() -> void:
	check(tree.root.has_node("EventBus"), "EventBus autoload missing")
	check(tree.root.has_node("App"), "App autoload missing")


func test_input_actions_defined() -> void:
	for a in REQUIRED_ACTIONS:
		check(InputMap.has_action(a), "missing input action " + a)
		if InputMap.has_action(a):
			check(InputMap.action_get_events(a).size() > 0, "no binding for " + a)


func test_core_scenes_load() -> void:
	for p in [App.SCENE_BOOT, App.SCENE_TITLE, App.SCENE_GAME_ROOT]:
		var ps: PackedScene = load(p)
		check(ps != null and ps.can_instantiate(), "cannot instantiate " + p)


func test_boot_reaches_title_then_game_root() -> void:
	var err := App.goto_scene(App.SCENE_BOOT)
	eq(err, OK, "goto boot")
	await frames(4)
	eq(tree.current_scene.name, &"Title", "boot must open title")
	tree.current_scene.buttons["new_game"].pressed.emit()
	await frames(3)
	eq(tree.current_scene.name, &"CharacterCreator", "new game must open character creator")
	tree.current_scene.confirm()
	await frames(3)
	eq(tree.current_scene.name, &"GameRoot", "creator must open game root")
	check(tree.current_scene.has_node("World") and tree.current_scene.has_node("UI"), "game root structure")


func test_missing_scene_is_rejected() -> void:
	eq(App.goto_scene("res://does/not/exist.tscn"), ERR_FILE_NOT_FOUND, "missing scene")
