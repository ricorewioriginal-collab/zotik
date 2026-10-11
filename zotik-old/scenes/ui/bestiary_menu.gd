class_name BestiaryMenu
extends MenuPanel
## Bestiary: every enemy type, revealed once defeated (05_GAMEPLAY fields).


func refresh() -> void:
	super()
	title_label.text = "Bestiarium"
	var ids := Content.table("enemies").keys().filter(func(i): return i != "ENEMY_TRAINING_DUMMY_001")
	ids.sort_custom(func(a, b): return [Content.get_entry("worlds", Content.enemy(a).region).get("chapter", 0), a] < [Content.get_entry("worlds", Content.enemy(b).region).get("chapter", 0), b])
	var known := ids.filter(func(i): return Guild.kills(i) > 0).size()
	info_label.text = "Erfasst: %d / %d" % [known, ids.size()]
	for id in ids:
		var en := Content.enemy(id)
		if Guild.kills(id) == 0:
			add_row("??? – %s" % Content.get_entry("worlds", en.region).get("name", "?"), [])
			continue
		var drops: Array = en.get("drops", []).map(func(d): return Content.item(d.id).name)
		add_row("%s (%s) – besiegt: %d\n  Beute: %s\n  %s" % [en.name, Content.get_entry("worlds", en.region).name, Guild.kills(id), ", ".join(drops) if not drops.is_empty() else "–", en.description], [])
