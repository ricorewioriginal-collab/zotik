extends TestCase

const MAIN := "QUEST_MAIN_LUN_001"
const BLADE := "WEAPON_WORLD_BLADE_001"
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
	GameState.set_flag("FLAG_LUN_ORUN_MET")


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _to_blade_step() -> void:
	GameState.quests[MAIN].step = 9
	GameState.defeated["SPAWN_LUN_ARENA_ORUN"] = true
	EventBus.enemy_defeated.emit("BOSS_ORUN_001")
	GameState.set_flag("FLAG_BOSS_LUN_ORUN_DEFEATED")
	game.enter_area("AREA_LUN_ORUN_ARENA", "default")
	await physics_frames(2)


func test_pedestal_hidden_until_orun_defeated() -> void:
	game.enter_area("AREA_LUN_ORUN_ARENA", "default")
	await physics_frames(2)
	var ped: UniquePedestal = game.area.entities[BLADE]
	check(not ped.visible and not ped.can_interact(), "hidden before victory")


func test_take_blade_vision_and_return_home() -> void:
	await _to_blade_step()
	eq(Conditions.quest_step(MAIN), 10, "at blade step")
	var ped: UniquePedestal = game.area.entities[BLADE]
	check(ped.can_interact(), "pedestal available")
	ped.interact(game.player)
	eq(Inventory.count(BLADE), 1, "blade granted")
	eq(GameState.equipment.weapon, BLADE, "blade equipped")
	check(game.player.visual.is_weapon_glowing(), "blade reacts to Zotik")
	eq(Conditions.quest_step(MAIN), 11, "quest advanced by item")
	eq(Dialogue.active_id, "CUT_LUN_RIFT_VISION_001", "vision plays")
	check(not ped.can_interact(), "cannot take twice")
	await finish_dialogues()
	await frames(2)
	await physics_frames(2)
	eq(game.area.area_id, "AREA_LUN_VILLAGE", "travelled home after vision")
	check(game.player.global_position.distance_to(game.area.spawn_point("return")) < 1.0, "at return spawn")


func test_blade_cannot_be_duplicated_after_reload() -> void:
	await _to_blade_step()
	game.area.entities[BLADE].interact(game.player)
	await finish_dialogues()
	await physics_frames(2)
	SaveSystem.save_slot(1)
	GameState.reset_new_game()
	App.continue_game(1)
	await frames(3)
	game = tree.current_scene
	game.enter_area("AREA_LUN_ORUN_ARENA", "default")
	await physics_frames(2)
	check(not game.area.entities[BLADE].can_interact(), "pedestal empty after reload")
	Effects.apply({"type": "give_item", "id": BLADE})
	eq(Inventory.count(BLADE), 1, "still exactly one blade")


func test_ending_mira_professorium_lyra() -> void:
	await _to_blade_step()
	game.area.entities[BLADE].interact(game.player)
	await finish_dialogues()
	await physics_frames(3)
	var mira: Npc = game.area.entities["NPC_MIRA_001"]
	var prof: Npc = game.area.entities["NPC_PROFESSORIUM_001"]
	var lyra: Npc = game.area.entities["NPC_LYRA_001"]
	check(not prof.visible and not lyra.visible, "professorium and lyra not yet present")
	mira.interact(game.player)
	eq(Dialogue.active_id, "DLG_MIRA_RETURN_001", "mira return dialogue")
	await finish_dialogues()
	check(prof.visible, "professorium arrived")
	check(not lyra.visible, "lyra not yet")
	var done := [false]
	game.chapter_complete.connect(func(): done[0] = true)
	prof.interact(game.player)
	eq(Dialogue.active_id, "DLG_PROFESSORIUM_ARRIVAL_001", "professorium recognises the blade")
	Dialogue.advance()
	Dialogue.advance()
	Dialogue.advance()
	eq(Dialogue.active_id, "CUT_LUN_LYRA_BRIDGE_001", "lyra bridge scene follows")
	check(done[0], "chapter complete signalled")
	eq(Conditions.quest_state(MAIN), "COMPLETED", "main quest complete")
	await finish_dialogues()
	check(lyra.visible and GameState.has_flag("FLAG_LUN_LYRA_MET"), "lyra present afterwards")
	check(mira.visible, "mira stays a separate character")
	eq(Dialogue.select_for_npc("NPC_MIRA_001"), "DLG_MIRA_AFTER_001", "mira post-chapter line")
	eq(Dialogue.select_for_npc("NPC_LYRA_001"), "DLG_LYRA_IDLE_001", "lyra own dialogue")
