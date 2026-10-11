class_name BountyMenu
extends MenuPanel
## Accept, track and claim guild bounties.


func refresh() -> void:
	super()
	title_label.text = "Monsterjäger-Gilde – Kopfgelder"
	info_label.text = "Aktive Aufträge: %d / %d" % [Guild.active_count(), Guild.MAX_ACTIVE]
	var ids := Content.table("bounties").keys()
	ids.sort()
	for id in ids:
		var b := Content.get_entry("bounties", id)
		var target := "%s ×%d – %d Lun" % [Content.enemy(b.enemy).name, int(b.count), int(b.reward_currency)]
		match Guild.state(id):
			"AVAILABLE":
				if Guild.is_offered(id):
					add_row("%s: %s" % [b.name, target], [["Annehmen", accept.bind(id), Guild.active_count() < Guild.MAX_ACTIVE]])
			"ACTIVE":
				add_row("%s: %s (%d/%d)" % [b.name, target, int(GameState.bounties[id].progress), int(b.count)], [])
			"DONE":
				add_row("%s: erfüllt!" % b.name, [["Abholen", claim.bind(id)]])
			"CLAIMED":
				add_row("%s: abgeschlossen" % b.name, [])


func accept(id: String) -> void:
	Guild.accept(id)
	refresh()


func claim(id: String) -> void:
	Guild.claim(id)
	refresh()
