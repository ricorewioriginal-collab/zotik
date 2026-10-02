# ZOTIK – Die Splitter der Welten

## Jetzt spielen (Phase 1 – Lunaris)
- **Windows:** [ZOTIK-windows-x86_64.zip](https://github.com/ricorewioriginal-collab/zotik/releases/download/phase1-latest/ZOTIK-windows-x86_64.zip) herunterladen, entpacken und `ZOTIK.exe` starten. Windows SmartScreen warnt eventuell, weil die Datei nicht signiert ist: „Weitere Informationen → Trotzdem ausführen“.
- **Linux:** [ZOTIK-linux-x86_64.zip](https://github.com/ricorewioriginal-collab/zotik/releases/download/phase1-latest/ZOTIK-linux-x86_64.zip), dann `ZOTIK.x86_64` starten.
- **Browser:** Die Web-Version wird automatisch auf GitHub Pages veröffentlicht, sobald Pages einmalig aktiviert ist: *Settings → Pages → Build and deployment → Source: GitHub Actions*. Danach läuft sie unter `https://ricorewioriginal-collab.github.io/zotik/`.
- Steuerung: F1 im Spiel blendet die Tastenhilfe ein und aus (Details in `game/zotik/README.md`).
- Alle Grafiken, Sounds und Dialogtexte sind Platzhalter.

Jeder Merge auf `main` baut die Downloads neu (Release `phase1-latest`).

Gesamter bisher ausgearbeiteter Projektstand.

## Wichtig
Dieses Paket enthält die bisherige Spielkonzeption, technische Spezifikation,
Claude-Code-Arbeitsgrundlagen und die bisher erzeugte Godot-Starterbasis.

Es ist NICHT das bereits fertig entwickelte komplette Spiel. Die eigentliche
vollständige Implementierung soll anschließend durch Claude Code erfolgen.

## Leitprinzip
Wir entwickeln ZOTIK zunächst vollständig konzeptionell und übergeben danach
die Spezifikation an Claude Code als ausführenden Entwicklungsagenten.

## Engine
Godot 4.x

## Primärplattform
Windows PC

## Architektur-Update 2026-09-24
Siehe `08_TECHNICAL/ARCHITECTURE_ADDENDUM_2026-09-24.md` für die neuen Systeme: MCP Hub, Local-First, Live Events, Housing/City Builder, My Zotik, Creator Marketplace, Giftcodes, Premium/DLC, Game Manual, Legal/Compliance und 2-GB-Ziel.

## Aktueller Chat-Stand 2026-09-24
Neue verbindliche Ergänzungen befinden sich in:
- `20_RIDDLES/` – zentrales Rätselsystem inkl. Reset und Hinweisen
- `21_EMOTES/` – Tänze, Siegerposen, Gruppenposen und Gimmicks
- `22_GIFTCODES/` – öffentliche, Event- und exklusive Giftcodes
- `20_CHAT_DECISIONS/` – Session-Addendum
- `19_VISUAL_REFERENCES/` – Rätsel- und Weltkarten-Demo
