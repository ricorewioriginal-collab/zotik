class_name EndingMenu
extends MenuPanel
## The choice at the end of the main story: what becomes of the Weltenkern (docs/CONFLICTS.md C-W20).
## Each way sets FLAG_ENDING_CHOSEN and its own flag and plays an epilogue; Veyra's lines afterwards follow it.
## It can be postponed: Veyra offers it again as long as nothing was chosen.

const ENDINGS := [
	["SEPARATE", "Getrennt bewahren", "Veyras Weg: Die Welten bleiben, wie sie sind. Sicher, aber getrennt – und die Splitter ruhen an ihren Orten."],
	["UNITE", "Wieder verbinden", "Elyons Weg: Die Splitter fügen sich in den Kern. Die Welten wachsen langsam zusammen, mit allem Risiko."],
	["WEAVE", "Neu knüpfen", "Zotiks Weg: Zotik öffnet seinen Klang und hält die Fäden zwischen den Welten, ohne sie zu verschmelzen."],
]


func refresh() -> void:
	super()
	title_label.text = "Was soll aus dem Weltenkern werden?"
	info_label.text = "Der Kern ist ruhig. Die sieben Splitter antworten dir. Diese Entscheidung prägt, wie die Geschichte endet."
	for e in ENDINGS:
		add_row("%s\n      %s" % [e[1], e[2]], [["Wählen", choose.bind(e[0])]])
	add_row("Noch nicht entscheiden – Veyra fragt später noch einmal.", [["Später", close_menu]])


func choose(id: String) -> void:
	if GameState.has_flag("FLAG_ENDING_CHOSEN"):
		return
	GameState.set_flag("FLAG_ENDING_CHOSEN")
	GameState.set_flag("FLAG_ENDING_" + id)
	close_menu()
	Dialogue.play_cutscene("CUT_ENDING_%s_001" % id)
