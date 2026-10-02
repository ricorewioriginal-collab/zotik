# Roadmap

Jede Phase ist ein überprüfbares Ziel. Nicht aufgeführte Funktionen sind nicht stillschweigend als fertig zu verstehen.

## Phase 0 – Repository und Architektur

- [x] Godot-Projekt, Grundstruktur und Editor-Startszene anlegen
- [x] Kernzustände, Szenewechsel, Input Actions und lokale Save-Grundlage
- [x] Contribution-/AI-Regeln, Architektur- und Systemstatus dokumentieren
- [x] Automatisierte Strukturtests und Headless-CI einrichten

## Phase 1 – Playable Core

- [x] Menü mit neuem Spiel, Fortsetzen, Lautstärke und Beenden
- [x] Zotik-Bewegung, Interaktion, einfacher Echtzeitangriff und Gamepad-Aktionen
- [x] Lokaler Slot mit Versionsfeld, einfacher Prüfsumme und Backupkopie
- [ ] Save-Slot-Auswahl, Migrationen, Backup-Wiederherstellung und robustere Save-Tests
- [ ] Controller-/Tastatur-Remapping, Audio-Busse, Accessibility- und Grafikoptionen

## Phase 2 – Vertical Slice

- [x] Testregion, NPC, Gegner, Item, Resonanzrätsel und zwei Bereiche
- [ ] Datengetriebene Dialoge, Quests, Inventar und UI
- [ ] Kampf-/Rätseltests sowie Android-Safe-Area- und Gerätevalidierung

## Phase 3 – Expanded World

- [ ] Regions-/Dungeon-Ressourcen, Streaming und Übergänge
- [ ] Charaktere, Gegner, Items, Skills und Loot als überprüfbare Daten

## Phase 4 – Multiplayer

- [ ] Netzwerkarchitektur/Threat Model und Serialisierungsformat spezifizieren
- [ ] Autoritativen Host/Client-Prototyp inkl. Offline-Regressionsprüfungen bauen
- [ ] Dedicated-/Headless- und selbst betriebene Server evaluieren

## Phase 5 – Housing und soziale Systeme

- [ ] Spielerhäuser, Rechte, Dekoration und Besuchsmodell
- [ ] Erweiterbares City-Building und NPC-/Besucherregeln

## Phase 6 – Creator-/Community-Systeme

- [ ] Geprüftes Inhaltsmanifest, Vertrauens-/Importmodell und Modding-Grenzen
- [ ] Optionale Integrationsschicht nur für verifizierte APIs planen

## Phase 7 – Contentproduktion

- [ ] Originale, lizenzierte Welt-, Figuren-, Audio- und UI-Inhalte produzieren
- [ ] Quest-, Dialog-, Minispiel- und Lokalisierungsumfang ausbauen

## Phase 8 – Optimierung und Release-Vorbereitung

- [ ] Performance-/Speicherbudgets und Assetkompression messen
- [ ] Windows-, Linux-, Android- und Web-Exports automatisieren
- [ ] Rechtstexte, Datenschutz, Barrierefreiheit und Releaseprozesse prüfen
