extends TestCase

const MAIN := "QUEST_MAIN_LUN_001"
var game: GameRoot


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()
	await frames(2)


func _beacon() -> String:
	game.update_beacon()
	return game.beacon_target if game.beacon.visible else ""


func test_next_hop_bfs() -> void:
	eq(Navigator.next_hop("AREA_LUN_HOME", "AREA_LUN_ORUN_ARENA"), "AREA_LUN_VILLAGE", "home -> village first")
	eq(Navigator.next_hop("AREA_LUN_RUINS", "AREA_LUN_VILLAGE"), "AREA_LUN_FOREST", "ruins -> forest")
	eq(Navigator.next_hop("AREA_LUN_FOREST", "AREA_LUN_FOREST"), "", "same area")


func test_beacon_guides_through_main_quest() -> void:
	eq(_beacon(), "exit:AREA_LUN_VILLAGE", "home: points to the village exit")
	game.enter_area("AREA_LUN_VILLAGE", "AREA_LUN_HOME")
	await physics_frames(2)
	eq(_beacon(), "NPC_MIRA_001", "village: points to Mira")
	check(game.beacon.global_position.distance_to(game.area.entities["NPC_MIRA_001"].global_position) < 0.1, "beacon at Mira")
	GameState.quests[MAIN].step = 2
	eq(_beacon(), "enemy:ENEMY_TRAINING_DUMMY_001", "training dummy")
	GameState.quests[MAIN].step = 4
	eq(_beacon(), "exit:AREA_LUN_FOREST", "to the forest for riftlings")
	GameState.quests[MAIN].step = 6
	eq(_beacon(), "exit:AREA_LUN_FOREST", "bridge puzzle is beyond the forest")
	game.enter_area("AREA_LUN_RIFT_CAVE", "default")
	await physics_frames(2)
	eq(_beacon(), "PUZ_LUN_RESONANCE_BRIDGE_001", "bridge crystals")
	GameState.quests[MAIN].step = 8
	eq(_beacon(), "SAVEPOINT_LUN_RIFT_001", "Weltenanker")
	GameState.quests[MAIN].step = 10
	eq(_beacon(), "exit:AREA_LUN_ORUN_ARENA", "blade is in the arena")
	GameState.quests[MAIN].step = 12
	eq(_beacon(), "exit:AREA_LUN_RUINS", "professorium: back towards the village")


func test_beacon_follows_side_quest_after_main() -> void:
	GameState.quests[MAIN] = {"state": "COMPLETED", "step": 13, "progress": 0}
	Quests.start("QUEST_SIDE_LUN_001")
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	eq(_beacon(), "CHEST_LUN_002", "side quest delivery chest")
	game.area.entities["CHEST_LUN_002"].interact(game.player)
	await frames(2)
	eq(_beacon(), "exit:AREA_LUN_VILLAGE", "back to Sari")


func test_no_beacon_without_active_quest() -> void:
	GameState.quests[MAIN] = {"state": "COMPLETED", "step": 13, "progress": 0}
	eq(_beacon(), "", "hidden when nothing to do")


func test_controls_bound_and_help_toggles() -> void:
	var keys := InputMap.action_get_events("camera_left").map(func(e): return e.as_text())
	check(keys.any(func(k): return k.contains("Z")), "camera left on Z: %s" % [keys])
	check(InputMap.action_get_events("camera_right").any(func(e): return e.as_text().contains("C")), "camera right on C")
	# arrow keys walk (A02b); WASD still works
	for pair in [["move_forward", "Up"], ["move_back", "Down"], ["move_left", "Left"], ["move_right", "Right"]]:
		var texts := InputMap.action_get_events(pair[0]).map(func(e): return e.as_text())
		check(texts.has(pair[1]), "%s on the %s arrow: %s" % [pair[0], pair[1], texts])
	for pair in [["move_forward", "W"], ["move_back", "S"], ["move_left", "A"], ["move_right", "D"]]:
		check(InputMap.action_get_events(pair[0]).any(func(e): return e is InputEventKey and e.physical_keycode == OS.find_keycode_from_string(pair[1])), pair[0] + " still on " + pair[1])
	check(InputMap.action_get_events("help")[0].as_text().contains("F1"), "help on F1")
	check(game.hud.HELP_TEXT.contains("Pfeiltasten"), "help text mentions the arrow keys")
	var shown: bool = game.hud.help_label.visible
	game.hud.toggle_help()
	eq(game.hud.help_label.visible, not shown, "help toggled")
	game.hud.toggle_help()


func test_feedback_sfx_and_hit() -> void:
	for n in Sfx.SOUNDS:
		check(Sfx.streams[n] is AudioStreamWAV and Sfx.streams[n].data.size() > 100, "sound %s synthesised" % n)
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var dummy: Enemy = game.area.entities["SPAWN_LUN_DUMMY_001"]
	var before := game.area.get_child_count()
	dummy.take_hit(5)
	check(game.area.get_child_count() == before + 1, "damage number spawned")
	var hp := int(GameState.player.hp)
	game.player.take_damage(10)
	check(game.hud.hurt_flash.color.a > 0.0, "hurt flash")
	check(int(GameState.player.hp) < hp, "damage applied")


func test_hud_fills_screen_and_centres_notifications() -> void:
	var vp := game.get_viewport().get_visible_rect().size
	eq(game.hud.size, vp, "HUD covers the viewport")
	check(game.hud.notify_label.size.x >= vp.x - 1.0, "notification row spans the width")
	eq(game.hud.notify_label.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER, "centred")


func test_hurt_flash_covers_screen() -> void:
	var vp := game.get_viewport().get_visible_rect().size
	eq(game.hud.hurt_flash.size, vp, "hurt flash is full screen")
