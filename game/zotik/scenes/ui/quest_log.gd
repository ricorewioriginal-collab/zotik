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
				add_row("%s %s\n    → %s" % ["★" if q.type == "main" else "•", q.name, Quests.objective(id)], [])
			"COMPLETED":
				add_row("✓ %s (abgeschlossen)" % q.name, [])
