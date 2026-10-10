extends TestCase
## W17: the story hands the player on from chapter to chapter, and the shard count is true.

const BOSS_SHARDS := {"BOSS_KANALWAECHTER_001": "ITEM_SHARD_VAL_001", "BOSS_KHAROS_001": "ITEM_SHARD_SOL_001", "BOSS_NERYX_001": "ITEM_SHARD_AQU_001", "BOSS_AVARN_001": "ITEM_SHARD_FRO_001", "BOSS_MAGMARION_001": "ITEM_SHARD_IGN_001", "BOSS_ERINNERUNGSHUETER_001": "ITEM_SHARD_NOC_001", "BOSS_SOLYRA_001": "ITEM_SHARD_AST_001"}


func before_each() -> void:
	GameState.reset_new_game()


func test_seven_chapter_bosses_drop_the_seven_shards() -> void:
	eq(BOSS_SHARDS.size(), 7, "seven shards")
	for b in BOSS_SHARDS:
		var drops: Array = Content.get_entry("enemies", b).drops
		var found := false
		for d in drops:
			if d.id == BOSS_SHARDS[b]:
				found = true
		check(found, b + " drops " + BOSS_SHARDS[b])
		check(Content.has_id("items", BOSS_SHARDS[b]), BOSS_SHARDS[b] + " exists")


func test_no_chapter_ends_with_a_cliffhanger_placeholder() -> void:
	for q in Content.table("quests"):
		var n: String = str(Content.get_entry("quests", q).get("completion_notice", ""))
		check(not n.contains("Fortsetzung folgt"), q + " notice names the way on")
	for c in Content.table("cutscenes"):
		for ln in Content.get_entry("cutscenes", c).lines:
			check(not str(ln[1]).contains("Fortsetzung folgt"), c + " has no placeholder line")


func test_the_guide_points_to_the_next_world_when_no_quest_is_open() -> void:
	eq(Navigator.next_world(), "", "nothing to travel to at the start")
	GameState.set_flag("FLAG_LUN_CHAPTER_COMPLETE")
	eq(Navigator.next_world(), "WORLD_ELARIS", "after chapter 1: Elaris")
	check(Navigator.world_objective().contains("Elaris"), "the objective names the world: " + Navigator.world_objective())
	eq(Navigator.world_target().area, "AREA_ELA_TOWN", "the beacon target is the hub of Elaris")
	GameState.set_flag("FLAG_ELA_ARRIVED")
	eq(Navigator.next_world(), "", "once there the hint is gone")
	GameState.set_flag("FLAG_ELA_CHAPTER_COMPLETE")
	eq(Navigator.next_world(), "WORLD_VALDORIA", "next chapter")


func test_an_open_main_quest_wins_over_the_world_hint() -> void:
	GameState.set_flag("FLAG_LUN_CHAPTER_COMPLETE")
	GameState.quests["QUEST_MAIN_ELA_001"] = {"state": "ACTIVE", "step": 0, "progress": 0}
	eq(Navigator.world_objective(), "", "no travel hint during a main quest")
	eq(Navigator.world_target(), {}, "no world target during a quest")


func test_chapter_titles_match_between_quests_and_worlds() -> void:
	for pair in [["QUEST_MAIN_NOC_001", "WORLD_NOCTARIS"], ["QUEST_MAIN_AST_001", "WORLD_ASTRALIS"], ["QUEST_MAIN_ELY_001", "WORLD_ELYNDRA"]]:
		eq(Content.get_entry("quests", pair[0]).name, Content.get_entry("worlds", pair[1]).subtitle, pair[1] + ": one title")


func test_keepsakes_and_shards_can_be_read_from_the_inventory() -> void:
	var with_lore := 0
	for id in Content.table("items"):
		var it := Content.item(id)
		if it.has("lore"):
			with_lore += 1
			check(Content.has_id("lore", it.lore), id + " points to a lore text")
	check(with_lore >= 15, "keepsakes, echo, seven shards and the last shard are readable (%d)" % with_lore)
	for id in ["ITEM_KAEL_COMPASS_001", "ITEM_ERYN_DIARY_001", "ITEM_TOREN_BAND_001", "ITEM_SELA_LEAF_001", "ITEM_MIRAEL_GEAR_001", "ITEM_PROFESSORIUM_NOTES_001", "ITEM_LAST_SHARD_001"]:
		check(Content.item(id).has("lore"), id + " can be read")


func test_the_inventory_offers_reading_and_opens_the_text() -> void:
	Inventory.add("ITEM_KAEL_COMPASS_001", 1)
	var menu := InventoryMenu.new()
	tree.root.add_child(menu)
	menu.refresh()
	var found := false
	for b in menu.find_children("*", "Button", true, false):
		if (b as Button).text == "Lesen":
			found = true
	check(found, "a Lesen button appears for the compass")
	menu.read("ITEM_KAEL_COMPASS_001")
	check(Dialogue.is_active(), "the text opens in the dialogue box")
	Dialogue.reset()
	menu.queue_free()


func test_side_characters_were_renamed_main_characters_were_not() -> void:
	eq(Content.get_entry("npcs", "NPC_VEYR_001").name, "Harlan", "guild leader")
	eq(Content.get_entry("npcs", "NPC_KAELEN_001").name, "Falk", "Frosthain guide")
	eq(Content.get_entry("npcs", "NPC_MIRAEL_001").name, "Nerea", "Aqualis guide")
	for pair in [["NPC_MIRA_001", "Mira"], ["NPC_LYRA_001", "Lyra"], ["NPC_VEYRA_001", "Veyra"], ["NPC_KAEL_001", "Kael"]]:
		eq(Content.get_entry("npcs", pair[0]).name, pair[1], pair[1] + " keeps the name")


func test_each_superboss_opens_the_dungeon_of_its_theme() -> void:
	var expect := {"AREA_END_WURZEL": "AREA_END_D1", "AREA_END_KOLOSS": "AREA_END_D2", "AREA_END_ABYSS": "AREA_END_D3", "AREA_END_FEUERKERN": "AREA_END_D4", "AREA_END_SANDKOENIG": "AREA_END_D5", "AREA_END_FROSTHERZ": "AREA_END_D6", "AREA_END_WAECHTER": "AREA_END_D7"}
	for arena in expect:
		var exits: Array = Content.get_entry("areas", arena).exits
		check(exits.has(expect[arena]), "%s leads to %s" % [arena, expect[arena]])
		check(Content.get_entry("areas", expect[arena]).exits.has(arena), expect[arena] + " leads back")
