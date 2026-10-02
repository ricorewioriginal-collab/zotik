extends TestCase

var game: GameRoot
var touch: TouchControls


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()
	touch = game.touch
	touch.force = true
	await frames(2)


func after_each() -> void:
	if is_instance_valid(touch):
		touch._release_all()


func _drag(index: int, pos: Vector2, rel: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	ev.relative = rel
	touch._input(ev)


func test_visible_only_when_wanted_and_free() -> void:
	check(touch.visible, "shown when forced (Android/touch screen)")
	game.open_menu(game.inventory_menu)
	await frames(1)
	check(not touch.visible, "hidden while a menu is open")
	game.inventory_menu.close_menu()
	await frames(1)
	check(touch.visible, "back after closing")


func test_buttons_emit_actions() -> void:
	var size_v := touch.get_viewport_rect().size
	var attack_pos := size_v - Vector2(150, 150)
	eq(touch.action_at(attack_pos), "attack", "attack button under the thumb")
	touch._on_press(0, attack_pos)
	await frames(1)
	check(Input.is_action_pressed("attack"), "attack pressed")
	touch._on_release(0)
	await frames(1)
	check(not Input.is_action_pressed("attack"), "attack released")
	eq(touch.action_at(Vector2(20 + 70, 96 + 28)), "menu", "menu button where the keyboard help was")
	check(not game.hud.help_label.visible, "keyboard help hidden in touch mode")


func test_taps_do_not_attack_in_touch_mode() -> void:
	check(not InputMap.action_get_events("attack").any(func(e): return e is InputEventMouseButton), "no LMB attack while touch controls are on")
	touch.force = false
	touch._set_touch_bindings(false)
	check(InputMap.action_get_events("attack").any(func(e): return e is InputEventMouseButton), "LMB attack restored for mouse players")


func test_quick_stick_flick_releases() -> void:
	var size_v := touch.get_viewport_rect().size
	var origin := Vector2(200, size_v.y - 200)
	touch._on_press(1, origin)
	_drag(1, origin + Vector2(0, -110), Vector2(0, -110))
	touch._on_release(1)  # released in the same frame, before the input flush
	await frames(2)
	eq(Input.get_action_strength("move_forward"), 0.0, "no stuck movement after a quick flick")


func test_stick_moves_and_swipe_turns_camera() -> void:
	var size_v := touch.get_viewport_rect().size
	var origin := Vector2(200, size_v.y - 200)
	touch._on_press(1, origin)
	_drag(1, origin + Vector2(110, 0), Vector2(110, 0))
	await frames(1)
	check(Input.get_action_strength("move_right") > 0.9, "stick right = move right")
	check(Input.get_action_strength("move_left") == 0.0, "no left")
	touch._on_release(1)
	await frames(1)
	check(Input.get_action_strength("move_right") == 0.0, "stick released")
	var yaw: float = game.player.camera_pivot.rotation.y
	touch._on_press(2, Vector2(size_v.x * 0.6, size_v.y * 0.4))
	_drag(2, Vector2(size_v.x * 0.6 + 50, size_v.y * 0.4), Vector2(50, 0))
	check(game.player.camera_pivot.rotation.y < yaw, "swipe turns the camera")
	touch._on_release(2)
