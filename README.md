# ZOTIK – Die Splitter der Welten

Ein eigenständiges Action-JRPG über Zotik, ein kleines orangefarbenes Fantasiewesen, und die Splitter, die seine Welten verbinden.

**Status:** Early Development · **Engine:** Godot 4.x · **Sprache:** GDScript

## Projektziele

Das Repository ist die wartbare Grundlage für einen plattformübergreifenden Vertical Slice. Originalität, Offline-Spielbarkeit, modulare Systeme, datengetriebene Inhalte, Barrierefreiheit und nachvollziehbare Beiträge haben Vorrang vor großer Content-Menge. Es werden keine Inhalte anderer Spiele übernommen.

## Unterstützte Zielplattformen

Geplant sind Windows, Linux, Android und Web. Die aktuelle Grundlage ist ein Godot-Projekt mit einer kleinen 2D-Testregion. Plattform-Exportvorlagen, Android-Signing und Release-Builds sind noch nicht eingerichtet.

## Aktueller Stand

- Startfähiges Godot-Projekt und eigenständiges Hauptmenü
- Bewegungs-, Interaktions- und Angriffs-Grundlage für Zotik
- Kleine gezeichnete Testregion mit NPC, Gegner, Fundstück und Bereichsübergang
- Lokale, versionierte Save-Slots mit einfacher Prüfsumme und Backup
- Input Actions für Tastatur und Gamepad; Touch-Steuerungsgrundlage
- Strukturierte Kern- und Design-Dokumentation

Das ist ein Entwicklungs-Vertical-Slice, kein vollständiges Spiel. Koop, Online-Dienste, Cloud, Marketplace, Radio-Streams, Housing, vollständiges Quest-/Dialogsystem und Release-Exports sind **geplant, aber nicht implementiert**. Externe Dienste bleiben optional; es gibt keine Echtgeld-Glücksspiel- oder Pay-to-Win-Funktion.

## Projektstruktur

```text
game/                 Godot-Projekt (hier project.godot öffnen)
  core/               Zustands-, Szenen-, Save- und Einstellungsgrundlage
  player/             Zotik-Controller und Spielfigur-Szene
  scenes/             Menü und Vertical-Slice-Testregion
  ui/                 Mobile Touch-Steuerungsgrundlage
docs/                 Architektur, Design, Entwicklung und Roadmap
tests/                Repository-Strukturprüfungen (Python-Standardbibliothek)
.github/workflows/    Headless-Projekt- und Testvalidierung
```

## Lokale Entwicklung

1. Godot 4.x installieren (derzeit ausgerichtet auf Godot 4.4 oder neuer).
2. `game/project.godot` in Godot importieren und starten.
3. Für automatisierte Basisprüfungen Python 3 verwenden:

   ```sh
   python3 -m unittest discover -s tests -v
   ```

4. Projekt zusätzlich headless validieren:

   ```sh
   godot --headless --path game --editor --quit
   godot --headless --path game --script res://tests/runtime_smoke_test.gd
   ```

   Unter Umständen heißt das Programm `godot4`. Exportvorlagen sind für den Editor-Import nicht erforderlich. Der Laufzeittest verwendet vorübergehend Save-Slots 1 und 3 und stellt vorhandene Slot-/Backupdateien wieder her.

## Beitrag und Dokumentation

Vor Änderungen bitte `docs/AI_DEVELOPMENT.md` und `CONTRIBUTING.md` lesen. Die Architektur und der tatsächliche Implementierungsstand sind in `docs/` beschrieben. Neue Funktionen sollen mit gezielten Tests und aktualisierter Dokumentation ergänzt werden.

## Lizenz und Copyright

Es wurde noch keine Software- oder Asset-Lizenz festgelegt. Siehe [`LICENSE-HINWEIS.md`](LICENSE-HINWEIS.md). Projektname, Figur und Inhalte sind eigenständig; fremde geschützte Assets, Musik, Karten oder Texte gehören nicht in dieses Repository.
