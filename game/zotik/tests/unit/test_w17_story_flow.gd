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
