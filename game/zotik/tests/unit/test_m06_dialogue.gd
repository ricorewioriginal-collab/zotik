extends TestCase

var game: GameRoot


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false


func _start_game() -> void:
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)


func _finish_dialogue() -> void:
	var guard := 0
	while Dialogue.is_active() and guard < 50:
		Dialogue.advance()
		guard += 1


func test_dialogue_selection_follows_state() -> void:
	eq(Dialogue.select_for_npc("NPC_MIRA_001"), "DLG_MIRA_IDLE_001", "fallback before quest")
	Quests.start("QUEST_MAIN_LUN_001")
	eq(Dialogue.select_for_npc("NPC_MIRA_001"), "DLG_MIRA_INTRO_001", "intro at step 0")
	GameState.quests.QUEST_MAIN_LUN_001.step = 5
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	eq(Dialogue.select_for_npc("NPC_MIRA_001"), "DLG_MIRA_FOREST_001", "forest variant")
	eq(Dialogue.select_for_npc("NPC_SARI_001"), "DLG_SARI_QUEST_001", "sari offers quest")


func test_lines_effects_and_talk_event() -> void:
	Quests.start("QUEST_MAIN_LUN_001")
	GameState.quests.QUEST_MAIN_LUN_001.step = 1
	var shown := []
	var talked := []
	Dialogue.line_shown.connect(func(s, t): shown.append(s))
	EventBus.npc_talked.connect(func(n, d): talked.append([n, d]))
	Dialogue.talk_to("NPC_TOREN_001")
	check(Dialogue.is_active(), "dialogue active")
	eq(Inventory.count("WEAPON_TRAINING_SWORD_001"), 0, "effects not before end")
	_finish_dialogue()
	eq(shown, ["Toren", "Toren"], "two lines with speaker names")
	eq(Inventory.count("WEAPON_TRAINING_SWORD_001"), 1, "sword given")
	eq(GameState.equipment.get("weapon", ""), "WEAPON_TRAINING_SWORD_001", "sword equipped")
	eq(talked, [["NPC_TOREN_001", "DLG_TOREN_TRAINING_001"]], "npc_talked emitted once")


func test_cutscene_queued_behind_dialogue() -> void:
	var order := []
	Dialogue.started.connect(func(id): order.append(id))
	Dialogue.talk_to("NPC_FINN_001")
	EventBus.cutscene_requested.emit("CUT_LUN_RIFT_VISION_001")
	eq(Dialogue.active_id, "DLG_FINN_EXPLORE_001", "dialogue keeps running")
	_finish_dialogue()
	eq(order, ["DLG_FINN_EXPLORE_001", "CUT_LUN_RIFT_VISION_001"], "cutscene played afterwards")


func test_new_game_plays_dream_and_starts_quest() -> void:
	await _start_game()
	eq(Dialogue.active_id, "CUT_LUN_DREAM_001", "intro cutscene")
	check(not game.player.control_enabled, "control locked during cutscene")
	check(game.dialogue_box.panel.visible, "dialogue box visible")
	_finish_dialogue()
	await physics_frames(3)
	check(game.player.control_enabled, "control restored")
	check(GameState.has_flag("FLAG_LUN_INTRO_SEEN"), "intro flag")
	eq(Conditions.quest_step("QUEST_MAIN_LUN_001"), 0, "main quest started at step 0")


func test_talk_to_npc_with_input_without_retrigger() -> void:
	await _start_game()
	_finish_dialogue()
	await physics_frames(3)
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var mira: Npc = game.area.entities["NPC_MIRA_001"]
	game.player.global_position = mira.global_position + Vector3(0, 0, 1.5)
	await physics_frames(2)
	eq(game.player.current_interactable, mira, "mira in range")
	var talks := []
	EventBus.npc_talked.connect(func(n, d): talks.append(d))
	Input.action_press("interact")
	await physics_frames(2)
	Input.action_release("interact")
	eq(Dialogue.active_id, "DLG_MIRA_INTRO_001", "intro dialogue via input")
	for i in 3:
		var ev := InputEventAction.new()
		ev.action = "interact"
		ev.pressed = true
		Input.parse_input_event(ev)
		Input.action_press("interact")
		await physics_frames(2)
		Input.action_release("interact")
		await physics_frames(1)
	check(not Dialogue.is_active(), "dialogue closed by input")
	await physics_frames(5)
	eq(talks, ["DLG_MIRA_INTRO_001"], "no immediate re-trigger")


func test_npc_appears_only_with_flag() -> void:
	await _start_game()
	_finish_dialogue()
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var prof: Npc = game.area.entities["NPC_PROFESSORIUM_001"]
	check(not prof.visible and not prof.can_interact(), "hidden before arrival")
	GameState.set_flag("FLAG_LUN_PROFESSORIUM_ARRIVED")
	check(prof.visible and prof.can_interact(), "present after flag")


func test_unique_effect_is_idempotent() -> void:
	for i in 3:
		Effects.apply({"type": "give_item", "id": "WEAPON_WORLD_BLADE_001"})
	eq(Inventory.count("WEAPON_WORLD_BLADE_001"), 1, "unique granted once")
