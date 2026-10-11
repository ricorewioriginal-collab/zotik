extends TestCase

const SIDE := "QUEST_SIDE_LUN_001"
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


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _props(name: String) -> Array:
	return game.area.flag_props.filter(func(fp): return fp.node.name == "PLACEHOLDER_" + name)


func test_side_quest_in_world() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var sari: Npc = game.area.entities["NPC_SARI_001"]
	sari.interact(game.player)
	await finish_dialogues()
	eq(Conditions.quest_step(SIDE), 0, "side quest started by Sari")
	eq(Dialogue.select_for_npc("NPC_SARI_001"), "DLG_SARI_WAITING_001", "waiting line")
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	game.enter_area("AREA_LUN_FOREST", "AREA_LUN_VILLAGE")
	await physics_frames(2)
	game.area.entities["CHEST_LUN_002"].interact(game.player)
	eq(Conditions.quest_step(SIDE), 1, "delivery found")
	game.enter_area("AREA_LUN_VILLAGE", "AREA_LUN_FOREST")
	await physics_frames(2)
	var crates: Node3D = _props("sari_crates")[0].node
	check(not crates.visible, "no crates yet")
	game.area.entities["NPC_SARI_001"].interact(game.player)
	eq(Dialogue.active_id, "DLG_SARI_THANKS_001", "thanks dialogue")
	await finish_dialogues()
	eq(Conditions.quest_state(SIDE), "COMPLETED", "side quest complete")
	check(crates.visible, "world reacts: Sari's crates in the village")
	eq(Dialogue.select_for_npc("NPC_SARI_001"), "DLG_SARI_AFTER_001", "after line")


func test_npcs_react_to_orun() -> void:
	var before := {}
	for npc in ["NPC_TOREN_001", "NPC_BORO_001", "NPC_ELWEN_001", "NPC_FINN_001"]:
		before[npc] = Dialogue.select_for_npc(npc)
	GameState.set_flag("FLAG_BOSS_LUN_ORUN_DEFEATED")
	for npc in before:
		var now := Dialogue.select_for_npc(npc)
		check(now != before[npc] and now.contains("REACTION"), "%s reacts (%s)" % [npc, now])


func test_visual_world_reactions_persist() -> void:
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	var glow: Node3D = _props("rift_glow")[0].node
	check(glow.visible, "rift glow while Orun lives")
	GameState.set_flag("FLAG_BOSS_LUN_ORUN_DEFEATED")
	check(not glow.visible, "rift calms after victory")
	SaveSystem.save_slot(1)
	GameState.reset_new_game()
	App.continue_game(1)
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)
	check(not _props("rift_glow")[0].node.visible, "still calm after reload")
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	check(_props("celebration_banner").all(func(fp): return fp.node.visible), "village celebrates")
	check(not _props("professorium_machine")[0].node.visible, "machine only after arrival")
