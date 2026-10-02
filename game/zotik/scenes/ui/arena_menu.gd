class_name ArenaMenu
extends MenuPanel
## Choose an arena challenge.

var game: Node


func refresh() -> void:
	super()
	title_label.text = "Arena von Valdoria"
	info_label.text = "Niederlagen kosten nichts. Gegenstandsbelohnungen nur beim ersten Sieg."
	var ids := Content.table("arena").keys()
	ids.sort()
	for id in ids:
		var a := Content.get_entry("arena", id)
		var won := int(GameState.arena.get(id, 0))
		var label := "%s – %d Wellen – %d Lun%s" % [a.name, a.waves.size(), int(a.reward_currency), ("  (gewonnen ×%d)" % won) if won > 0 else ""]
		if ArenaRun.unlocked(id):
			add_row(label, [["Antreten", start.bind(id)]])
		else:
			add_row("%s – noch gesperrt" % a.name, [])


func start(id: String) -> void:
	close_menu()
	game.start_arena(id)
