# ZOTIK – Einheitlicher Rätselstandard

Status: VERBINDLICH
Stand: 2026-09-24

Jedes Rätsel in ZOTIK verwendet eine einheitliche Struktur und einen reproduzierbaren Zustandsautomaten. Fehler dürfen keinen Spielstand beschädigen oder den Spieler dauerhaft blockieren.

## Pflichtstruktur
1. Rätsel-ID
2. Welt / Dungeon / Ort
3. Ziel
4. Einführung / Kontext
5. Mechanik
6. Ausgangszustand
7. Interaktionsobjekte
8. Hinweise Level 0–3
9. Falsche Aktionen
10. Reset-Verhalten
11. Lösung
12. Erfolgsinszenierung
13. Belohnung
14. Dialog / Epilog
15. technische Zustände und Save-Verhalten

## Reset
- RESET_MANUAL: Spieler setzt das aktuelle Rätsel selbst zurück.
- RESET_FAILURE: definierter Fehlversuch löst automatisch einen Reset aus.
- RESET_RESTART: Spiel-/Level-Neustart setzt das Rätsel auf den letzten gültigen Rätselzustand zurück.
- RESET_CHECKPOINT: Rückkehr zum Rätsel-Checkpoint.
- Der normale Spielfortschritt außerhalb des Rätsels bleibt erhalten.
- Reset darf keine Quest-, Inventar-, Level- oder Story-Fortschritte außerhalb des Rätselzustands rückgängig machen.
- UI-Aktion: „Rätsel zurücksetzen“; Tastaturbelegung beispielhaft R, später konfigurierbar.

## Hinweissystem
- Stufe 0: keine Hilfe.
- Stufe 1: subtile Umgebungs-/Dialoghinweise.
- Stufe 2: konkreter mechanischer Hinweis.
- Stufe 3: fast vollständige bzw. vollständige Lösung.
- Hinweise dürfen auf Wunsch optional automatisch nach längerer Inaktivität angeboten werden.

## Demo-Rätsel: Elaris – Turm der Erinnerung
Rätsel-ID: ELARIS_TURM_01
Ziel: Vier Symbolsäulen in der korrekten Reihenfolge aktivieren.
Symbole: Mond → Blatt → Kristall → Flamme.
Fehler: Reset des Rätselzustands.
Belohnung: Schlüssel zum inneren Bereich, Lun, Elaris-Lore und seltene Materialien.

### Demo-Dialog / Epilog
Zotik: „Geschafft.“
Nia: „Du hast gerade eine uralte Weltenmaschine geknackt und sagst einfach ‚geschafft‘?“
Zotik: „Was soll ich sonst sagen?“
Rovan: „Vielleicht nichts. Die Tür ist offen.“
Zotik: „Das ist ein gutes Argument.“

## Technische Empfehlung
Rätsel als datengetriebene Definitionen implementieren. Jede Definition enthält initial_state, interactables, transitions, failure_conditions, reset_state, hints, solution, reward_bundle und completion_dialogue. Rätsel-UI, Reset und Hint-System werden zentral implementiert; einzelne Rätsel liefern nur Daten/Regeln.
