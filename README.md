# ZOTIK – Die Splitter der Welten

## Jetzt spielen
- **Neues Zotik im Browser:** [ZOTIK auf GitHub Pages](https://ricorewioriginal-collab.github.io/zotik/) – auch auf dem Smartphone spielbar.
- **Alte Godot-Version (`zotik-old/`):** [Windows](https://github.com/ricorewioriginal-collab/zotik/releases/download/phase1-latest/ZOTIK-windows-x86_64.zip), [Linux](https://github.com/ricorewioriginal-collab/zotik/releases/download/phase1-latest/ZOTIK-linux-x86_64.zip), [Android](https://github.com/ricorewioriginal-collab/zotik/releases/download/phase1-latest/ZOTIK-android-arm64.apk) und [Web-Archiv als ZIP](https://github.com/ricorewioriginal-collab/zotik/releases/download/phase1-latest/ZOTIK-web.zip). Diese Downloads bleiben als letzter Stand erhalten und werden nicht mehr automatisch neu gebaut.

Änderungen an `zotik/` veröffentlichen die Browser-Version automatisch auf GitHub Pages. Die automatischen Godot-Builds und -Tests für `zotik-old/` sind abgeschaltet.

## Archivierte Godot-Projektplanung

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


## Ordner
- `zotik/`: neues Zotik (3D im Browser, Einzeldatei), Startseite der Pages-Seite.
- `zotik-old/`: archiviertes Godot-Zotik (frühere `game/zotik`); unter `/zotik-old/` liegt ein Link zum letzten Release.
