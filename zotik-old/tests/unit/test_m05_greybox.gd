extends TestCase

var game: GameRoot


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves/"
	GameState.reset_new_game()
	Customization.ensure_valid()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _walk_into_exit(target: String) -> void:
	await tree.create_timer(WorldArea.EXIT_GRACE_MSEC / 1000.0 + 0.05).timeout
	var trig: Area3D = game.area.exits[target].trigger
	game.player.global_position = trig.global_position - Vector3(0, 1.5, 0)
	await physics_frames(4)
	await frames(2)


func test_new_game_starts_at_home() -> void:
	eq(game.area.area_id, "AREA_LUN_HOME", "start area")
	eq(GameState.player.area, "AREA_LUN_HOME", "state area")
	check(game.player.global_position.distance_to(game.area.spawn_point("default")) < 0.5, "at default spawn")


func test_exit_transitions_and_arrival_spawn() -> void:
	await _walk_into_exit("AREA_LUN_VILLAGE")
	eq(game.area.area_id, "AREA_LUN_VILLAGE", "entered village")
	check(game.player.global_position.distance_to(game.area.spawn_point("AREA_LUN_HOME")) < 1.0, "arrived at home-side spawn")


func test_forest_gate_locked_until_flag() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var barrier: Node3D = game.area.exits["AREA_LUN_FOREST"].barrier
	check(barrier.visible, "barrier visible while locked")
	var msgs := []
	EventBus.notify.connect(func(t): msgs.append(t))
	await _walk_into_exit("AREA_LUN_FOREST")
	eq(game.area.area_id, "AREA_LUN_VILLAGE", "locked exit keeps player in village")
	check(msgs.has("Der Weg ist versperrt."), "locked notification")
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	check(not barrier.visible, "barrier removed after flag")
	game.player.global_position = game.area.spawn_point("default")
	await physics_frames(2)
	await _walk_into_exit("AREA_LUN_FOREST")
	eq(game.area.area_id, "AREA_LUN_FOREST", "unlocked exit works")


func test_bridge_appears_with_flag() -> void:
	game.enter_area("AREA_LUN_RIFT_CAVE", "default")
	await physics_frames(2)
	var bridge: Node3D = game.area.flag_props[0].node
	check(not bridge.visible, "bridge hidden")
	check(bridge.get_child(0).disabled, "bridge not walkable")
	GameState.set_flag("FLAG_LUN_BRIDGE_ACTIVE")
	check(bridge.visible and not bridge.get_child(0).disabled, "bridge active after flag")


func test_every_spawn_has_ground() -> void:
	for area_id in Content.layouts:
		game.enter_area(area_id, "default")
		await physics_frames(2)
		var space := game.area.get_world_3d().direct_space_state
		for key in Content.layout(area_id).spawns:
			var p := game.area.spawn_point(key)
			var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 2, 0), p + Vector3(0, -3, 0))
			q.exclude = [game.player.get_rid()]
			var hit := space.intersect_ray(q)
			check(not hit.is_empty() and hit.collider.is_in_group("ground"), "%s spawn %s has no ground" % [area_id, key])


func test_fall_into_void_respawns() -> void:
	game.enter_area("AREA_LUN_RIFT_CAVE", "default")
	await physics_frames(2)
	var hp := int(GameState.player.hp)
	game.player.global_position = Vector3(0, -20, 0)
	await physics_frames(3)
	check(game.player.global_position.y > -1.0, "respawned")
	check(int(GameState.player.hp) < hp, "fall damage")


func test_save_and_continue_restores_area_and_position() -> void:
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(10)
	var pos := game.player.global_position
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "save")
	GameState.reset_new_game()
	App.goto_scene(App.SCENE_TITLE)
	await frames(3)
	check(tree.current_scene.buttons.has("load_1"), "title offers slot 1")
	tree.current_scene.buttons["load_1"].pressed.emit()
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)
	eq(game.area.area_id, "AREA_LUN_FOREST", "area restored")
	check(game.player.global_position.distance_to(pos) < 0.3, "position restored (%s vs %s)" % [game.player.global_position, pos])


func test_interaction_picks_nearest() -> void:
	var a := Interactable.new()
	var b := Interactable.new()
	var used := []
	a.interacted.connect(func(): used.append("a"))
	b.interacted.connect(func(): used.append("b"))
	game.area.add_child(a)
	game.area.add_child(b)
	a.global_position = game.player.global_position + Vector3(1.0, 0, 0)
	b.global_position = game.player.global_position + Vector3(2.0, 0, 0)
	await physics_frames(2)
	eq(game.player.current_interactable, a, "nearest chosen")
	Input.action_press("interact")
	await physics_frames(2)
	Input.action_release("interact")
	eq(used, ["a"], "interact called once on nearest")
	a.queue_free()
	b.queue_free()


func test_stale_position_does_not_chain_transitions() -> void:
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	game.player.global_position = Vector3(0, 0, 29)
	game.enter_area("AREA_LUN_RIFT_CAVE", "AREA_LUN_ORUN_ARENA")
	await physics_frames(5)
	eq(game.area.area_id, "AREA_LUN_RIFT_CAVE", "no chained exit into the ruins")
