class_name QuickStartMenu
extends MenuPanel
## Shown once when a new game starts: the few things a first-time player needs (W22). The full manual
## stays in the pause menu; this card only says how to move, fight, talk and where to look next.


func refresh() -> void:
	super()
	title_label.text = "So spielst du"
	info_label.text = "Kurz und bündig – alles Weitere steht jederzeit in der Spielanleitung (Zahnrad oben links)."
	if TouchControls.wanted():
		add_row("Laufen\n      Linker Stick unten links. Die Kamera drehst du mit einem Wisch rechts.", [])
		add_row("Sprechen, Truhen, Schalter\n      Die Taste A (unten, leuchtet in Reichweite) oder die Person direkt antippen.", [])
		add_row("Kämpfen\n      X = schneller Schlag, Y = starker Schlag, B = ausweichen. Oder Gegner antippen: Zotik läuft hin und schlägt zu.", [])
	else:
		add_row("Laufen\n      W A S D oder Pfeiltasten, Maus dreht die Kamera, Leertaste springt.", [])
		add_row("Sprechen, Truhen, Schalter\n      Enter oder E, wenn unten ein Hinweis erscheint.", [])
		add_row("Kämpfen\n      Linksklick oder J = schneller Schlag, K = starker Schlag, F = ausweichen, Q = anvisieren.", [])
	add_row("Wohin?\n      Rechts oben steht „Aktuelles Ziel“, ein Leuchtstrahl zeigt den Weg. Sprich mit allen Bewohnern!", [])
	add_row("Gesund bleiben\n      Weltenanker (Kristalle) heilen und speichern. Heiltrank: R oder Taste links vom Stick.", [])
	add_row("Los geht’s – viel Spaß!", [["Verstanden", close_menu]])
