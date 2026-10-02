class_name CasinoMenu
extends MenuPanel
## Slot machine UI. Virtual Lun only.

var last := ""


func refresh() -> void:
	super()
	title_label.text = "Golden Star Casino – Kristallslots"
	info_label.text = "Nur virtuelle Lun – kein Echtgeld. Lun: %d · Drehungen: %d · Bester Gewinn: %d" % [GameState.currency, int(GameState.casino.spins), int(GameState.casino.best_win)]
	if last != "":
		add_row(last, [])
	for bet in Casino.BETS:
		add_row("Einsatz %d Lun" % bet, [["Drehen", spin.bind(bet), GameState.currency >= bet]])
	add_row("Drei gleiche: Stern ×25 · Kristall ×12 · Flamme ×8 · Mond/Blatt ×5 · Zwei gleiche: Einsatz zurück", [])


func spin(bet: int) -> void:
	var r := Casino.spin(bet)
	if r.is_empty():
		last = "Nicht genug Lun."
	else:
		last = "[ %s | %s | %s ]  %s" % [r.reels[0], r.reels[1], r.reels[2], ("Gewinn: %d Lun!" % r.win) if r.win > 0 else "Leider nichts."]
		Sfx.play("pickup" if r.win > bet else "blip")
	refresh()
