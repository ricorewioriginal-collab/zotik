# Entwicklung und Build

## Voraussetzungen

- Godot 4.4 oder neuer, Compatibility-Renderer
- Python 3 für die Repository-Strukturtests (nur Standardbibliothek)

## Editor

`game/project.godot` in Godot öffnen. Der Editor importiert das Projekt; anschließend F6 startet die aktuelle Szene, F5 das Hauptmenü. Für headless Validierung:

```sh
godot --headless --path game --editor --quit
```

## Tests

```sh
python3 -m unittest discover -s tests -v
godot --headless --path game --script res://tests/runtime_smoke_test.gd
```

Der Godot-Laufzeittest prüft Save/Load, Backup, beschädigte Daten sowie NPC-, Kampf-, Item-, Rätsel- und Bereichswechsel. Er verwendet vorübergehend Slots 1 und 3 und stellt vorhandene Slot-/Backupdateien wieder her. GitHub Actions führt die Strukturtests, den Godot-Editorimport und den Laufzeittest aus. Exportvorlagen, plattformspezifische Pakete, signierte Builds und Veröffentlichungen sind nicht eingerichtet. Niemals Schlüssel oder Zertifikate in den Build-Workflow einchecken.
