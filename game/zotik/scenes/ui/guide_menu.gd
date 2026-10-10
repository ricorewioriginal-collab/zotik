class_name GuideMenu
extends MenuPanel
## In-game manual: what the game is about and how everything works.

const PAGES := [
	["Worum geht es?", [
		"Du bist Zotik, ein orangefarbenes Fuchswesen mit großem Schweif. Die Welten sind in Splitter zerbrochen. Du reist von Welt zu Welt, hilfst den Bewohnern, löst Rätsel, besiegst Wächter und findest Stück für Stück heraus, was den Weltenkern zerbrochen hat.",
		"Die Reise geht durch zehn Welten: Lunaris (Start), Elaris, Valdoria, Solmera, Aqualis, Frosthain, Ignara, Noctaris, Astralis und Elyndra. Jede Welt hat mehrere Orte, eigene Händler, Rätsel und einen großen Gegner am Ende.",
		"Du kannst nichts falsch machen: Das Spiel zeigt dir rechts oben unter „Aktuelles Ziel“, was als Nächstes zu tun ist.",
	]],
	["Bewegen und Kamera", [
		"PC: Mit W A S D oder den Pfeiltasten läufst du, mit der Maus (oder Z und C) drehst du die Kamera, mit der Leertaste springst du.",
		"Touch: Der Stick unten links bewegt Zotik, Wischen auf der rechten Bildschirmhälfte dreht die Kamera. Tippst du auf den Boden, läuft Zotik dorthin.",
		"Die Minikarte rechts oben zeigt dir die Umgebung.",
	]],
	["Sprechen und Benutzen", [
		"Steh nah an einer Person, einer Truhe, einem Schalter oder einem Weltenanker: Unten erscheint ein Hinweis, was du tun kannst.",
		"PC: Drücke Enter (oder E). Touch: Tippe die Person oder das Objekt an – Zotik läuft hin und spricht oder benutzt es.",
		"In Gesprächen geht es mit Enter, Leertaste oder Antippen weiter. Bei Auswahlen tippst du die Antwort an.",
		"Rede mit allen! Viele Bewohner geben Aufgaben, Hinweise oder verkaufen etwas. Namen über Köpfen erscheinen nur, wenn du nah genug bist.",
	]],
	["Kämpfen", [
		"PC: Linksklick oder J = schneller Angriff. K = starker Angriff, der den Bruch-Wert des Gegners senkt. F = ausweichen (kurz unverwundbar). Rechtsklick = blocken. Q = Gegner anvisieren. R = Heiltrank benutzen.",
		"Touch: Gegner antippen, dann läuft Zotik hin und kämpft. Doppeltippen = ausweichen. Die Aktionstasten unten rechts gibt es zusätzlich.",
		"Jeder Gegner hat Lebenspunkte und einen Bruch-Wert. Ist er voll, ist der Gegner kurz benommen und nimmt viel mehr Schaden („BREAK!“). Starke Angriffe sind dafür am besten.",
		"Bei großen Gegnern leuchtet ein roter Kreis am Boden, bevor sie zuschlagen: Weich aus! Bosse haben mehrere Phasen und neue Angriffe, wenn sie schwächer werden.",
		"In freier Wildnis, Kanälen, Dünen und Höhlen streifen außerdem Wildtiere und Wesen umher – jedes Mal andere und an anderen Stellen. Sie sind schwächer als die Wächter, bringen aber Lun und Material. In Dörfern und Städten bist du sicher.",
		"Nach dem Finale öffnet sich über den Weltstein die Welt „Weltenriss“: sieben Superbosse (Weltenbrecher) mit einzigartigen EX-Belohnungen und die Halle der 100 mit zehn Rängen. Am Ende wartet der letzte Splitter.",
		"Hinter jedem besiegten Superboss öffnet sich im Norden seiner Arena ein begehbarer Endgame-Dungeon mit Wächtern, Truhen und einem Weltenanker.",
		"Außerdem warten nach dem Finale Abschluss-Quests bei Kael, Eryn, Toren, Sela, Mirael und dem Professorium – und sieben Endgame-Dungeons (Rissläufe in fünf Riss-Arten, von klein bis Weltenriss) im Arena-Menü der Halle.",
		"Neues Spiel+: Ysolde im Weltenriss lässt die Geschichte von vorn beginnen. Du behältst Gegenstände, Ausrüstung, Lun, Andenken und Rekorde – dafür werden Gegner stärker, Bosse bekommen eine Raserei-Phase, es tauchen neue Chronik-Gegner und zusätzliche Truhen auf, und Händler Corvin im Weltenriss verkauft Chronik-Ausrüstung.",
	]],
	["Quests", [
		"Das Questlog (Taste L oder Symbol „Quests“) listet Hauptgeschichte und Nebenaufgaben mit dem aktuellen Schritt.",
		"Die Hauptquest führt dich durch die Geschichte. Nebenquests geben Belohnungen, Ausrüstung und oft Hintergrund zur Welt.",
		"Ein Leuchtstrahl zeigt zum Ziel. Folge ihm, wenn du nicht weiter weißt.",
	]],
	["Rätsel", [
		"Rätsel stehen hinter Toren, Brücken und in Dungeons. Es gibt Drehscheiben (die richtige Stellung finden), Folgen (Symbole in der richtigen Reihenfolge) und Ventile (Wasserläufe so schalten, dass alles fließt).",
		"Benutze die Teile des Rätsels der Reihe nach. T setzt das Rätsel zurück, H gibt einen Hinweis.",
		"Manche Rätsel verraten ihre Lösung in Gesprächen, Büchern oder Inschriften der Umgebung.",
	]],
	["Speichern und Heilen", [
		"Weltenanker (leuchtende Kristalle) heilen die Gruppe und öffnen das Speichermenü mit drei Slots. Speichern geht außerdem jederzeit über das Zahnrad-Symbol (Hilfe & Einstellungen, dann „Spielstand speichern“). Ein belegter Slot fragt vor dem Überschreiben nach.",
		"Zusätzlich speichert das Spiel automatisch in die Autospeicherung: bei jedem Gebietswechsel, wenn die App in den Hintergrund geht und im Browser beim Verlassen oder Verstecken der Seite. Sie erscheint am Titelbildschirm als „Laden: Autospeicherung“. Im Browser wird jeder Spielstand doppelt gesichert (Datei und Browser-Speicher).",
		"Spielstand auf ein anderes Gerät bringen: Im Titelbildschirm oder im Pausemenü „Spielstand übertragen“ öffnen, bei einem Slot „Code erzeugen“ wählen und den Code kopieren (im Browser auch als Datei laden). Auf dem anderen Gerät denselben Menüpunkt öffnen, den Code einfügen und einen Slot zum Importieren wählen.",
		"An Reisepunkten öffnet sich die Weltkarte, mit der du zwischen Orten und Welten reist, die du schon besucht hast.",
	]],
	["Inventar und Händler", [
		"Inventar (Taste I): Tränke, Waffen, Rüstungen, Schmuck und Questgegenstände. Hier rüstest du aus und benutzt Dinge.",
		"Händler kaufen und verkaufen gegen Lun, die Währung. Besser ausrüsten lohnt sich vor jedem großen Gegner.",
		"Truhen in der Welt enthalten Lun, Tränke und seltene Ausrüstung. Schau in Ecken und Nebenräume.",
	]],
	["Gruppe und Bestiarium", [
		"Im Lauf der Reise schließen sich dir Gefährten an. Sie kämpfen mit, haben eigene Lebenspunkte und stehen links oben unter Zotiks Anzeige.",
		"Das Bestiarium (Taste B) sammelt, was du über Gegner gelernt hast – Schwächen, Angriffe und Fundorte.",
	]],
	["Nebenbei", [
		"Arena und Kopfgeldtafeln bieten zusätzliche Kämpfe mit Belohnung. Das Casino ist eine Familienoption und lässt sich in den Einstellungen ausschalten.",
		"Alles Wichtige zu Einstellungen, Touch-Steuerung und Spiel beenden findest du im Zahnrad oben links.",
	]],
	["Wenn du nicht weiter weißt", [
		"1. Schau im Questlog nach dem aktuellen Schritt. 2. Folge dem Leuchtstrahl. 3. Sprich noch einmal mit der Person, die dir die Aufgabe gegeben hat. 4. Bei Rätseln: H für einen Hinweis. 5. Bei Kämpfen: ausweichen statt draufhauen, Heiltränke mitnehmen, bei einem Anker speichern und heilen.",
	]],
]


func refresh() -> void:
	super()
	title_label.text = "Spielanleitung"
	info_label.text = "Alles, was du zum Spielen wissen musst – Schritt für Schritt."
	for p in PAGES:
		add_heading(p[0])
		for t in p[1]:
			add_note(t)
