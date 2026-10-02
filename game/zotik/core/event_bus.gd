extends Node
## Global gameplay events. Systems emit facts here; quests, UI and world
## reactions listen. UI never completes quests directly (docs/03).

signal flag_changed(flag_id: String, value: bool)
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)
signal currency_changed(amount: int)
signal enemy_defeated(enemy_id: String)
signal npc_talked(npc_id: String, dialogue_id: String)
signal chest_opened(chest_id: String)
signal puzzle_solved(puzzle_id: String)
signal area_entered(area_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
signal savepoint_used(savepoint_id: String)
signal player_died
signal notify(text: String)
