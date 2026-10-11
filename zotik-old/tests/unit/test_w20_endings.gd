extends TestCase
## W20: the Erinnerungsbruch scene and the three endings of the main story.


func before_each() -> void:
	GameState.reset_new_game()
	Dialogue.reset()


func test_the_defeat_cutscene_shows_the_day_the_core_was_split() -> void:
	var lines: Array = Content.get_entry("cutscenes", "CUT_ELY_ELYON_DEFEAT_001").lines
	check(lines.size() >= 10, "montage plus ending lines (%d)" % lines.size())
	var text := ""
	for l in lines:
		text += str(l[1]) + " "
	for word in ["acht", "Kind", "Veyra versiegelte", "Meine Träume"]:
		check(text.contains(word), "the montage mentions: " + word)


func test_choosing_an_ending_sets_its_flags_and_plays_the_epilogue() -> void:
	for id in ["SEPARATE", "UNITE", "WEAVE"]:
		GameState.reset_new_game()
		Dialogue.reset()
		var menu := EndingMenu.new()
		tree.root.add_child(menu)
		menu.choose(id)
		check(GameState.has_flag("FLAG_ENDING_CHOSEN") and GameState.has_flag("FLAG_ENDING_" + id), id + ": flags set")
		eq(Dialogue.active_id, "CUT_ENDING_%s_001" % id, id + ": epilogue plays")
		menu.choose("UNITE" if id != "UNITE" else "WEAVE")
		check(not GameState.has_flag("FLAG_ENDING_UNITE") or id == "UNITE", id + ": the choice is final")
		menu.queue_free()


func test_veyra_asks_until_chosen_and_then_follows_the_ending() -> void:
	GameState.quests["QUEST_MAIN_ELY_001"] = {"state": "COMPLETED", "step": 6, "progress": 0}
	GameState.set_flag("FLAG_ELY_LAYERS_OPEN")
	GameState.set_flag("FLAG_ELY_CHAPTER_COMPLETE")
	eq(Dialogue.select_for_npc("NPC_VEYRA_001"), "DLG_VEYRA_ENDING_ASK_001", "asks while nothing is chosen")
	GameState.set_flag("FLAG_ENDING_CHOSEN")
	GameState.set_flag("FLAG_ENDING_WEAVE")
	eq(Dialogue.select_for_npc("NPC_VEYRA_001"), "DLG_VEYRA_AFTER_WEAVE_001", "after the Neu-knüpfen ending")
	GameState.set_flag("FLAG_ENDING_WEAVE", false)
	GameState.set_flag("FLAG_ENDING_SEPARATE")
	eq(Dialogue.select_for_npc("NPC_VEYRA_001"), "DLG_VEYRA_AFTER_SEPARATE_001", "after the Getrennt-bewahren ending")


func test_the_report_opens_the_ending_menu() -> void:
	var fx: Array = Content.get_entry("dialogues", "DLG_VEYRA_REPORT_001").effects
	var has_menu := false
	for e in fx:
		if e.type == "open_menu" and e.id == "ending":
			has_menu = true
	check(has_menu, "Veyra's report ends with the choice")
	check(Content.validate().is_empty(), "content stays valid: %s" % str(Content.validate()))
