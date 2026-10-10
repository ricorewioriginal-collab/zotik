extends TestCase
## W08: the quest log lets the player choose which quest the beacon and objective list follow.


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()


func _two_active() -> Array:
	var ids := []
	for id in Content.table("quests"):
		if ids.size() < 2:
			ids.append(id)
	for id in ids:
		GameState.quests[id] = {"state": "ACTIVE", "step": 0, "progress": 0}
	return ids


func test_tracking_moves_a_quest_to_the_front() -> void:
	var ids := _two_active()
	var first: String = Quests.active_quests()[0]
	var other: String = ids[1] if ids[0] == first else ids[0]
	eq(Quests.tracked_quest(), "", "nothing tracked at first")
	Quests.track(other)
	eq(Quests.tracked_quest(), other, "tracked")
	eq(Quests.active_quests()[0], other, "tracked quest first")
	eq(Navigator.guided_quest(), other, "beacon follows it")
	Quests.track(first)
	eq(Quests.tracked_quest(), first, "only one tracked at a time")


func test_tracking_ends_with_the_quest_and_ignores_inactive() -> void:
	var ids := _two_active()
	Quests.track(ids[1])
	GameState.quests[ids[1]].state = "COMPLETED"
	eq(Quests.tracked_quest(), "", "completed quest is no longer tracked")
	Quests.track("QUEST_DOES_NOT_EXIST")
	eq(Quests.tracked_quest(), "", "unknown id is ignored")


func test_tracking_survives_a_save() -> void:
	var ids := _two_active()
	Quests.track(ids[1])
	var d := GameState.to_dict()
	GameState.reset_new_game()
	check(GameState.from_dict(d), "load")
	eq(Quests.tracked_quest(), ids[1], "still tracked after load")
