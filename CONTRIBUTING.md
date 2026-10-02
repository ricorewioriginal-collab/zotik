# Beiträge

ZOTIK befindet sich in einer frühen Entwicklungsphase. Kleine, nachvollziehbare Änderungen sind willkommen; bitte zuerst `docs/ARCHITECTURE.md` und `docs/AI_DEVELOPMENT.md` lesen.

## Arbeitsablauf

1. Bestehende Implementierung und Dokumentation vor Änderungen suchen.
2. Umfang und sichtbare Auswirkungen beschreiben; keine bestehenden Dateien blind ersetzen.
3. Tests ergänzen oder aktualisieren und lokal ausführen.
4. Godot-Import/Validierung ausführen, sofern Godot installiert ist.
5. Geänderte Systeme und bekannte Einschränkungen dokumentieren.

GDScript-Klassen verwenden PascalCase, Variablen und Funktionen `snake_case`, Konstanten `UPPER_SNAKE_CASE`. Stabile Inhalts-IDs verwenden das Schema `zotik:<typ>:<name>` (z. B. `zotik:item:healing_fruit`). Keine Secrets, geschützten Fremdinhalte oder nicht verifizierten externen APIs einbringen.

## Validierung

```sh
python3 -m unittest discover -s tests -v
godot --headless --path game --editor --quit
```

Es gibt derzeit keine festgelegte Pull-Request- oder Release-Automatisierung über die Projektvalidierung hinaus.
