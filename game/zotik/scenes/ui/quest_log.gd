class_name QuestLog
extends MenuPanel
## Read-only quest log (it cannot change quest state).


func refresh() -> void:
	super()
	title_label.text = "Questlog"
	info_label.text = ""
	for id in Content.table("quests"):
		var q := Content.get_entry("quests", id)
		match Conditions.quest_state(id):
			"ACTIVE":
				var followed: bool = Quests.tracked_quest() == id or (Quests.tracked_quest() == "" and Quests.active_quests()[0] == id)
				add_row("%s %s%s\n      Ziel: %s" % ["»" if q.type == "main" else "•", q.name, "  (verfolgt)" if followed else "", Quests.objective(id)],
					[] if followed else [["Verfolgen", _track.bind(id)]])
			"COMPLETED":
				add_row("[erledigt] %s" % q.name, [])


func _track(id: String) -> void:
	Quests.track(id)
	refresh()
