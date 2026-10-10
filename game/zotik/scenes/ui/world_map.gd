class_name WorldMap
extends MenuPanel
## Weltkarte: lists the worlds and travels to unlocked ones.


func refresh() -> void:
	super()
	title_label.text = "Weltkarte"
	var here := Content.world_of(GameState.player.get("area", ""))
	info_label.text = "Aktuelle Welt: %s" % Content.get_entry("worlds", here).get("name", "?")
	var ids := Content.table("worlds").keys()
	ids.sort_custom(func(a, b): return int(Content.get_entry("worlds", a).chapter) < int(Content.get_entry("worlds", b).chapter))
	for id in ids:
		var wd := Content.get_entry("worlds", id)
		var label := "Kapitel %d: %s – %s" % [int(wd.chapter), wd.name, wd.subtitle]
		if id == here:
			add_row(label + "  (hier)", [])
		elif Content.world_unlocked(id):
			add_row(label, [["Reisen", travel.bind(id)]])
		if Content.world_unlocked(id):
			for a in Content.anchors_of(id):
				var here_area: bool = a[1] == GameState.player.get("area", "")
				var aname := "   Anker: " + str(Content.get_entry("areas", a[1]).get("name", a[1]))
				add_row(aname + ("  (hier)" if here_area else ""), [] if here_area else [["Reisen", travel_to_area.bind(a[1])]])
		else:
			add_row("Kapitel %d: ??? – noch versiegelt" % int(wd.chapter), [])


func travel(world_id: String) -> void:
	if not Content.world_unlocked(world_id):
		return
	var wd := Content.get_entry("worlds", world_id)
	close_menu()
	Effects.apply({"type": "travel", "area": wd.hub_area, "spawn": wd.hub_spawn})


## Fast travel to a Weltenanker the player has touched before.
func travel_to_area(area_id: String) -> void:
	close_menu()
	Effects.apply({"type": "travel", "area": area_id, "spawn": "default"})
