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
	var attack_pos := size_v - Vector2(190, 150)
	eq(touch.action_at(attack_pos), "attack", "attack button under the thumb")
	touch._on_press(0, attack_pos)
	await frames(1)
	check(Input.is_action_pressed("attack"), "attack pressed")
	touch._on_release(0)
	await frames(1)
	check(not Input.is_action_pressed("attack"), "attack released")
	var menu_btn: Control = game.hud.gear
	check(game.hud.is_ui_at(menu_btn.get_global_rect().get_center()), "the gear tile counts as HUD")
	touch._on_press(5, menu_btn.get_global_rect().get_center())
	check(touch._camera_index == -1 and touch._stick_index == -1, "tap on the icon bar is not a stick or camera touch")
	check(game.hud.gear.visible and not game.hud.has_node("HelpLabel"), "gear tile instead of keyboard hints")


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


# --- A02: calmer layout, contextual "Benutzen", tap the world ----------------

func _screen_of(node: Node3D) -> Vector2:
	return game.player.camera.unproject_position(node.global_position + Vector3(0, 1.0, 0))


func test_interact_button_only_when_something_is_usable() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	game.player.global_position = Vector3(30, 0, 30)
	await physics_frames(3)
	await frames(2)
	var size_v := touch.get_viewport_rect().size
	var spot := size_v - Vector2(120, 80)
	check(game.player.current_interactable == null, "nothing in reach")
	var dim: float = touch._panels["interact"].modulate.a
	eq(touch.action_at(spot), "interact", "A button is always there")
	var mira: Npc = game.area.entities["NPC_MIRA_001"]
	game.player.global_position = mira.global_position + Vector3(0, 0, 1.5)
	await physics_frames(3)
	await frames(2)
	check(game.player.current_interactable != null, "Mira in reach")
	check(touch._panels["interact"].modulate.a > dim, "A glows next to her")


func test_buttons_are_calm_and_scale_with_settings() -> void:
	var main_r := 0.0
	var minor_r := 0.0
	for a in TouchControls.ACTIONS:
		if a[0] == "attack":
			main_r = a[3]
		if a[0] == "block":
			minor_r = a[3]
	check(minor_r < main_r * 0.7, "secondary buttons are smaller than attack")
	for a in TouchControls.ACTIONS:
		check(a[3] <= 40.0, "%s is a small button" % a[0])
	check(touch.ui_opacity() <= 0.65, "translucent at rest")
	var before: float = touch._panels["attack"].scale.x
	Settings.set_value("touch_scale", 1.4)
	Settings.set_value("touch_opacity", 0.85)
	await frames(2)
	check(touch._panels["attack"].scale.x > before, "larger buttons")
	check(touch._panels["attack"].modulate.a > 0.8, "more opaque")
	Settings.set_value("touch_scale", 1.0)
	Settings.set_value("touch_opacity", 0.6)
	await frames(2)
	eq(PauseMenu._next_of(PauseMenu.TOUCH_SCALES, 1.0), 1.2, "next size")
	eq(PauseMenu._next_of(PauseMenu.TOUCH_SCALES, 1.4), 0.8, "wraps around")


func test_tap_a_person_uses_them() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	var mira: Npc = game.area.entities["NPC_MIRA_001"]
	game.player.global_position = mira.global_position + Vector3(0, 0, 3.0)
	await physics_frames(3)
	await frames(2)
	eq(touch.tap_world(_screen_of(mira)), "interact", "tap on Mira")
	check(Dialogue.is_active(), "dialogue started")
	await finish_dialogues()
	check(["", "ground"].has(touch.tap_world(Vector2(5, 5))), "tap in the corner")


func test_tap_far_person_asks_to_come_closer() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	var mira: Npc = game.area.entities["NPC_MIRA_001"]
	game.player.global_position = mira.global_position + Vector3(0, 0, 9.0)
	await physics_frames(3)
	await frames(2)
	var pos := _screen_of(mira)
	var res := touch.tap_world(pos)
	eq(res, "walk_use", "too far to talk: walk over first (%s)" % res)
	check(not Dialogue.is_active(), "no dialogue from far away")


func test_tap_enemy_locks_on() -> void:
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	var e: Enemy = game.area.entities["SPAWN_LUN_FOREST_RIFTLING_1"]
	game.player.global_position = e.global_position + Vector3(0, 0, 5.0)
	game.player.rotation = Vector3.ZERO
	await physics_frames(3)
	await frames(2)
	eq(touch.tap_world(_screen_of(e)), "attack", "tap on an enemy")
	check(game.player.lock_target == e, "locked on")


func test_short_tap_in_world_is_detected_but_drag_is_not() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	var mira: Npc = game.area.entities["NPC_MIRA_001"]
	game.player.global_position = mira.global_position + Vector3(0, 0, 3.0)
	await physics_frames(3)
	await frames(2)
	var pos := _screen_of(mira)
	touch._on_press(7, pos)
	touch._on_release(7, pos + Vector2(60, 0))  # moved: that was a swipe
	check(not Dialogue.is_active(), "a swipe is not a tap")
	touch._on_press(8, pos)
	touch._on_release(8, pos)
	check(Dialogue.is_active(), "a quick tap uses the person")
	await finish_dialogues()


# --- A03: the world is the control -------------------------------------------

func _frames_until(cond: Callable, max_frames: int) -> int:
	var n := 0
	while not cond.call() and n < max_frames:
		await physics_frames(1)
		n += 1
	return n


func test_tap_ground_walks_there() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(3)
	await frames(2)
	var size_v := touch.get_viewport_rect().size
	var res := touch.tap_world(Vector2(size_v.x * 0.5, size_v.y * 0.8))
	eq(res, "ground", "tap on the ground in front of Zotik")
	eq(game.player.goal, Player.Goal.POINT, "goal set")
	var target: Vector3 = game.player.goal_point
	var start: Vector3 = game.player.global_position
	await _frames_until(func(): return game.player.goal == Player.Goal.NONE, 240)
	eq(game.player.goal, Player.Goal.NONE, "goal reached or given up")
	var closer: bool = game.player.global_position.distance_to(target) < start.distance_to(target) - 0.5
	check(closer or start.distance_to(target) < 1.0, "Zotik walked toward the tapped point")
	check(game.area.find_child("TapMarker", false, false) != null, "marker shown")


func test_tap_far_person_walks_over_and_talks() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	var mira: Npc = game.area.entities["NPC_MIRA_001"]
	game.player.global_position = mira.global_position + Vector3(0, 0, 8.0)
	await physics_frames(3)
	await frames(2)
	eq(touch.tap_world(_screen_of(mira)), "walk_use", "tap on Mira from far away")
	check(not Dialogue.is_active(), "not yet")
	await _frames_until(func(): return Dialogue.is_active(), 360)
	check(Dialogue.is_active(), "arrived and talked")
	eq(game.player.goal, Player.Goal.NONE, "goal consumed")
	await finish_dialogues()


func test_tap_enemy_runs_up_and_fights() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var dummy: Enemy = game.area.entities["SPAWN_LUN_DUMMY_001"]
	game.player.global_position = dummy.global_position + Vector3(0, 0, 7.0)
	game.player.invulnerable_time = 999.0
	await physics_frames(3)
	await frames(2)
	eq(touch.tap_world(_screen_of(dummy)), "attack", "tap on the dummy")
	check(game.player.lock_target == dummy, "locked on")
	var hp0 := dummy.hp
	await _frames_until(func(): return dummy.hp < hp0, 420)
	check(dummy.hp < hp0, "walked up and hit it without any button")
	game.player.clear_goal()


func test_manual_input_cancels_the_autopilot() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(3)
	game.player.set_goal(Player.Goal.POINT, game.player.global_position + Vector3(10, 0, 0))
	Input.action_press("move_left")
	await physics_frames(3)
	Input.action_release("move_left")
	eq(game.player.goal, Player.Goal.NONE, "stick or keys take over")
	game.player.set_goal(Player.Goal.POINT, game.player.global_position + Vector3(10, 0, 0))
	game.player.control_enabled = false
	await physics_frames(2)
	eq(game.player.goal, Player.Goal.NONE, "dialogue or menu stops it")
	game.player.control_enabled = true


func test_blocked_way_gives_up() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(3)
	game.player.set_goal(Player.Goal.POINT, game.player.global_position + Vector3(500, 0, 0))
	game.player.global_position = game.player.global_position  # stays put: nothing moves it
	game.player.velocity = Vector3.ZERO
	game.player._stuck_ref = game.player.global_position
	# pretend the body cannot move: pin it every frame for the stuck window
	var pin: Vector3 = game.player.global_position
	for i in 100:
		game.player.global_position = pin
		await physics_frames(1)
		if game.player.goal == Player.Goal.NONE:
			break
	eq(game.player.goal, Player.Goal.NONE, "gives up when it makes no progress")


func test_double_tap_dodges() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(3)
	await frames(2)
	var size_v := touch.get_viewport_rect().size
	var pos := Vector2(size_v.x * 0.5, size_v.y * 0.8)
	touch._on_press(3, pos)
	touch._on_release(3, pos)
	touch._on_press(4, pos + Vector2(10, 0))
	touch._on_release(4, pos + Vector2(10, 0))
	await physics_frames(3)
	check(game.player.is_dodging, "second tap dodged")


func test_buttons_can_be_switched_off() -> void:
	var attack_pos := touch.get_viewport_rect().size - Vector2(190, 150)
	eq(touch.action_at(attack_pos), "attack", "buttons on by default")
	Settings.set_value("touch_buttons", false)
	await frames(2)
	eq(touch.action_at(attack_pos), "", "no button in the way when switched off")
	check(not touch._panels["attack"].visible, "button hidden")
	Settings.set_value("touch_buttons", true)
	await frames(2)
	eq(touch.action_at(attack_pos), "attack", "and back")
