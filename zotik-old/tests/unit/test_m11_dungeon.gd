extends TestCase

var game: GameRoot


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves/"
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()
	game.enter_area("AREA_LUN_RIFT_CAVE", "default")
	await physics_frames(3)


func after_each() -> void:
	Input.action_release("move_forward")
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _walk_north(frames_n: int) -> void:
	game.player.camera_pivot.rotation.y = 0.0
	Input.action_press("move_forward")
	await physics_frames(frames_n)
	Input.action_release("move_forward")


func test_chasm_blocks_until_bridge_active() -> void:
	game.player.global_position = Vector3(0, 0, 6)
	await physics_frames(2)
	var hp := int(GameState.player.hp)
	await _walk_north(120)
	await physics_frames(60)
	check(game.player.global_position.z > 20.0, "fell and respawned at entry (z=%.1f)" % game.player.global_position.z)
	check(int(GameState.player.hp) < hp, "fall damage")
	GameState.set_flag("FLAG_LUN_BRIDGE_ACTIVE")
	game.area.entities["SPAWN_LUN_CAVE_MOONWOLF_1"].queue_free()  # the wolf would block the bridge
	game.player.global_position = Vector3(0, 0, 6)
	await physics_frames(2)
	await _walk_north(150)
	check(game.player.global_position.z < -6.0 and game.player.global_position.y > -0.5, "crossed bridge (pos %s)" % game.player.global_position)


func test_weltenanker_heals_saves_and_progresses_quest() -> void:
	Quests.start("QUEST_MAIN_LUN_001")
	GameState.quests.QUEST_MAIN_LUN_001.step = 8
	GameState.player.hp = 20
	var sp: Savepoint = game.area.entities["SAVEPOINT_LUN_RIFT_001"]
	sp.interact(game.player)
	eq(int(GameState.player.hp), Stats.max_hp(), "healed")
	check(GameState.has_flag("FLAG_LUN_WELTENANKER_AWAKENED"), "quest step 8 completed")
	check(game.save_menu.visible and not game.player.control_enabled, "save menu open")
	game.save_menu.save(2)
	eq(SaveSystem.slot_info(2).status, SaveSystem.Status.OK, "saved slot 2")
	eq(SaveSystem.slot_info(2).area, "AREA_LUN_RIFT_CAVE", "slot area")
	game.save_menu.close_menu()
	check(game.player.control_enabled, "control back")
	check(game.area.is_exit_open("AREA_LUN_ORUN_ARENA"), "arena exit open")


func test_cave_chest_and_wolf_present() -> void:
	check(game.area.entities.has("CHEST_LUN_003"), "cave chest")
	check(game.area.entities.has("SPAWN_LUN_CAVE_MOONWOLF_1"), "moonwolf")
	check(game.area.entities.has("PUZ_LUN_RESONANCE_BRIDGE_001"), "bridge puzzle")
	eq(game.area.skipped.size(), 0, "no unbuilt entities in cave")


func test_pause_menu_and_back_to_title() -> void:
	var ev := InputEventAction.new()
	ev.action = "menu"
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(2)
	check(game.pause_menu.visible and not game.player.control_enabled, "pause open")
	game.pause_menu._to_title()
	await frames(3)
	eq(tree.current_scene.name, &"Title", "back to title")
