# Architektur

## Laufender Stand

Das Godot-Projekt liegt unter `game/` und ist in GDScript umgesetzt. `project.godot` definiert die Eingabeaktionen sowie vier bewusst kleine Autoloads: `GameManager` verwaltet benannte Zustände und den Szenenstart, `SceneManager` wechselt Szenen, `SaveManager` liest und schreibt lokale Slots, `SettingsManager` persistiert derzeit die Master-Lautstärke. Autoloads sind Infrastruktur, keine Sammelstelle für Spiellogik.

Die Testregion und der Splitterwald bestehen aus Szenen und kleinen Komponenten. Zotik verarbeitet Bewegungsaktionen und sucht Interaktionsziele in Gruppen, statt konkrete NPC-/Item-Szenen fest zu referenzieren. Noch nicht vorhandene Manager (u. a. Quest, Dialog, Inventar, Audio, Party und Multiplayer) sind zukünftige Module, keine behaupteten Implementierungen.

## Zustandsmodell

`GameManager.State` enthält die geplanten Zustände BOOT, MAIN_MENU, PROFILE_SELECTION, LOADING, WORLD, TOWN, DUNGEON, COMBAT, PAUSE, DIALOGUE, CUTSCENE, VEHICLE, HOUSING, MULTIPLAYER, CASINO und GAME_OVER. Derzeit werden nur Menü, Laden und Welt im Spielfluss verwendet. Weitere Zustände werden erst aktiv, wenn dafür ein echtes Feature existiert.

## Erweiterungsregeln

- Szenen-/Inhaltsdaten in Szenen oder Resources ablegen, nicht in UI- oder Manager-Monolithen.
- Systeme über Signals/kleine APIs koppeln; aktuell zeigen Szenenwechsel, Save-Abschluss und Spielzustandswechsel Beispiele.
- Core-Referenzen über stabile IDs statt Node-Pfade oder direkte Node-Referenzen serialisieren.
- Plattformbedingte Bedienung von Gameplay-Aktionen trennen: Tastatur, Gamepad und mobile Tasten lösen dieselben Input Actions aus.
- Inhalte und IDs vor dem Einchecken auf Originalität, Datenintegrität und Lizenzstatus prüfen.

## Geplante Manager

Quest-, Dialog-, Inventar-, Kampf-, Party-, Multiplayer-, Event-, Fahrzeug-, Housing-, Radio-, Achievement- und Localization-Systeme sind Roadmap-Arbeit. Sie sollen getrennte Verantwortlichkeiten und testbare Schnittstellen erhalten. Keine dieser Funktionen darf als fertig gelten, nur weil ein State oder Ordnername existiert.
