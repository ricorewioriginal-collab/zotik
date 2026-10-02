# ZOTIK MCP HUB

## Zweck
Gemeinsame Entwicklungs- und Projektwissensschicht für ChatGPT, Claude Code und das ZOTIK-Projekt. Der Hub ist **kein Spielstandserver**.

## Rollen
- ChatGPT: Game Direction, Story/Lore, Systems Design, Spec- und Qualitätsprüfung.
- Claude Code: Godot-Implementierung, Tests, Builds, technische Dokumentation.
- MCP Hub: gemeinsame Projektwahrheit, Tasks, Status, Audit und Synchronisation.

## Kernbereiche
- Master Specs, Lore, Charaktere, Welten, Gameplay und technische Architektur lesen/suchen.
- Tasks, Bugs, Features, Changelog und Development Log verwalten.
- Godot-Projekt, Szenen, Scripts, Assets, Input Map und Projektstatus prüfen.
- Builds, Tests, Regressionstests und Performanceberichte erfassen.
- Änderungsprotokoll mit Agent, Zeitpunkt, System, Task, Grund und Teststatus.

## Berechtigungen
Claude darf implementieren und testen, aber keine zentrale Story-/Designentscheidung stillschweigend überschreiben. Zentrale Spezifikationsänderungen müssen nachvollziehbar dokumentiert werden.

## Local-First
Der MCP Hub speichert keine normalen Spielstände und keine komplette Spielerwelt. Spielstände bleiben lokal; optionale Cloud-Synchronisierung ist ein separater Dienst.

## Geplante Toolgruppen
`zotik_get_*`, `zotik_search_*`, `zotik_create_task`, `zotik_update_task`, `zotik_add_bug`, `zotik_resolve_bug`, `zotik_start_build`, `zotik_run_tests`, `zotik_get_test_results`, `zotik_validate_scene`, `zotik_update_changelog`, `zotik_write_development_log`.
