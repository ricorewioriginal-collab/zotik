# Zotik 2.0 (Browser, Three.js)

Moderne 3D-Neuaufbau-Variante von **Zotik – Die Splitter der Welten**: eine Datei (`index.html`), kein Build-Schritt, Three.js per CDN, Handy und PC.

- **Kapitel 1 Lunaris**: Dorf am Mondblick, Mondwald, Risshöhle mit Mondwolf-Alpha (Boss), Haupt- und Nebenquest, Händler, Truhen, Stufenaufstieg.
- **Figuren nach den Master-Sheets** (`reference/approved/`): Zotik als aufrecht gehender oranger Fuchs mit grünem Schal, Weste, Reiseklinge mit Kristall und buschigem Schwanz mit heller Spitze; Mira (blaue Haare, Mondschmuck), Professorium (Fliegerbrille, Technikrucksack), Felli.
- **Steuerung**: WASD/Stick bewegen, rechte Maustaste bzw. Wischen = Kamera, J/Klick = Angriff (3er-Kombo), Shift = Ausweichen, 1/2/3 = Funkenwirbel / Lichtstoß / Heiltrank, E = Sprechen, Esc = Menü.
- **Speicherstand**: `localStorage`, Schlüssel `zotik2_save_slot1` (Autosave). Das Cloud-Skript aus easygames (`anmacha-cloud.js`, Spielname `zotik2`) hängt sich dort ein; das Godot-Zotik bleibt unberührt.

Ordner: Dieses Spiel liegt jetzt in `zotik/` und ist die Startseite der Pages-Seite. Das alte Godot-Zotik liegt komplett in `zotik-old/` (Web-Build unter `/zotik-old/`).

## Titelscreen, HUD und Handy-Ansicht
- Konsolen-Titelscreen nach dem Key-Art-Vorbild: Logo, Menü mit Leuchtbalken (Pfeiltasten/Enter oder Tippen), Untermenü „Steuerung".
- HUD und Dialoge zeigen die Originalfiguren (Gesichter aus den Master-Sheets: Zotik, Mira, Professorium, Felli).
- Menü, Aufgaben und Steuerung sind für Hoch- und Querformat kompakt (Tabs, scrollbar); Handy zeigt Touch-Steuerung statt Tastaturliste.
- Ablauf: Startscreen („Tippen oder Taste drücken") → Ladebalken → Menü (Neues Spiel / Spiel laden / Steuerung) → Speicherplatz (3 Slots) → „Mein Zotik" (Fellton, Schal, Kleidung; nur bei neuem Spiel) → Spawn im Dorf.
- Speicherstände: `zotik2_save_slot1` bis `zotik2_save_slot3`; die Auswahl wird im Spielstand (`cos`) gespeichert.
- Häuser sind begehbar: Tür vorn, Innenraum mit Möbeln (Taverne, Schmiede, drei Wohnhäuser), Wandkollision, Dach und Wände blenden beim Betreten aus; in drei Häusern liegt eine Truhe.
