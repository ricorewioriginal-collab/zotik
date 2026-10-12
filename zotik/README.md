# Zotik 2.0 (Browser, Three.js)

Moderne 3D-Neuaufbau-Variante von **Zotik – Die Splitter der Welten**: eine Datei (`index.html`), kein Build-Schritt, Three.js per CDN, Handy und PC.

- **Alle 10 Kapitel**: Lunaris, Elaris, Valdoria, Solmera, Aqualis, Frosthain, Ignara, Noctaris, Astralis und Elyndra (siehe unten).
- **Kapitel 1 Lunaris**: Dorf am Mondblick, Mondwald, Risshöhle mit Mondwolf-Alpha (Boss), Haupt- und Nebenquest, Händler, Truhen, Stufenaufstieg.
- **Figuren nach den Master-Sheets** (`reference/approved/`): Zotik als aufrecht gehender oranger Fuchs mit grünem Schal, Weste, Reiseklinge mit Kristall und buschigem Schwanz mit heller Spitze; Mira (blaue Haare, Mondschmuck), Professorium (Fliegerbrille, Technikrucksack), Felli.
- **Steuerung**: WASD/Stick bewegen, rechte Maustaste bzw. Wischen = Kamera, J/Klick = Angriff (3er-Kombo), Shift = Ausweichen, 1/2/3 = Funkenwirbel / Lichtstoß / Heiltrank, E = Sprechen, Esc = Menü.
- **Handy-Steuerung** (Gay-Life-Stil): runder Stick links, rechts max. 4 Tasten – Angriff (groß), Ausweichen (im Nautilux „Turbo"), Fähigkeit (Tippen = gewählte, Halten = Funkenwirbel/Lichtstoß/Heiltrank wählen) und Aktion (Sprechen/Öffnen bzw. Einsteigen/Aussteigen; Halten = Nautilux-Form wählen). Begleiter kämpfen automatisch.
- **Leistung**: Props werden in Raster-Zellen gezeichnet (nur was im Bild bzw. im Schattenbereich liegt), die Qualität passt sich automatisch an die Bildrate an (Auflösung und Schatten-Takt sinken schrittweise und kehren zurück, wenn es wieder rund läuft).
- **Speicherstand**: `localStorage`, Schlüssel `zotik2_save_slot1` (Autosave). Das Cloud-Skript aus easygames (`anmacha-cloud.js`, Spielname `zotik2`) hängt sich dort ein; das Godot-Zotik bleibt unberührt.

Ordner: Dieses Spiel liegt jetzt in `zotik/` und ist die Startseite der Pages-Seite. Das alte Godot-Zotik liegt komplett in `zotik-old/` (Web-Build unter `/zotik-old/`).

## Titelscreen, HUD und Handy-Ansicht
- Konsolen-Titelscreen nach dem Key-Art-Vorbild: Logo, Menü mit Leuchtbalken (Pfeiltasten/Enter oder Tippen), Untermenü „Steuerung".
- HUD und Dialoge zeigen die Originalfiguren (Gesichter aus den Master-Sheets: Zotik, Mira, Professorium, Felli).
- Menü, Aufgaben und Steuerung sind für Hoch- und Querformat kompakt (Tabs, scrollbar); Handy zeigt Touch-Steuerung statt Tastaturliste.
- Ablauf: Startscreen („Tippen oder Taste drücken") → Ladebalken → Menü (Neues Spiel / Spiel laden / Steuerung) → Speicherplatz (3 Slots) → „Mein Zotik" (Fellton, Schal, Kleidung; nur bei neuem Spiel) → Spawn im Dorf.
- Speicherstände: `zotik2_save_slot1` bis `zotik2_save_slot3`; die Auswahl wird im Spielstand (`cos`) gespeichert.
- Häuser sind begehbar: Tür vorn, Innenraum mit Möbeln (Taverne, Schmiede, drei Wohnhäuser), Wandkollision, Dach und Wände blenden beim Betreten aus; in drei Häusern liegt eine Truhe.

## Kapitel 2 bis 10 (Welten-Baukasten)
- Nach Kapitel 1 öffnet das **Weltentor** (Standbild mit Ring im Dorf, `E`) das Menü „Weltreise". Jede Welt öffnet erst, wenn die vorige geschafft ist; man kann jederzeit zurückreisen.
- Jede Welt hat eigene Palette, Himmel, Nebel, Bäume/Props, Wahrzeichen am Horizont, Dorf mit Ältester/Ältestem und drei Bewohnern (der erste handelt), vier Gegnerarten (Fernkämpfer, Nahkämpfer, Wächter, Boss) und Truhen.
- Ablauf je Kapitel: mit der Ältesten sprechen → ins Umland gehen → 5 Gegner vertreiben → das Rätsel der Welt lösen → Wächter besiegen (Siegel bricht) → Boss in der Arena → Bericht und Belohnung.
- Namen, Gegner, Bosse und Aufgaben stammen aus dem alten Spiel (`zotik-old/data/*.json`): Wurzelkönigin, Kanalwächter, Kharos, Neryx, Avarn, Magmarion, Erinnerungshüter, Solyra, Elyon.
- Fortschritt je Kapitel im Spielstand (`ch`, `cd`), alte Spielstände laden unverändert. Daten der Kapitel: `CHP` im Skript, Aufbau in `buildWorld`.

## Begleiter, Rätsel und Zwischensequenzen (aus der alten Version)
- **Begleiter:** Lyra (Heilerin, schließt sich beim ersten Besuch von Elaris an), Nia (Bogenschützin, im Forschungsviertel ansprechen) und Rovan (Nahkämpfer, im Wald von Elaris). Sie folgen, kämpfen mit, Lyra heilt bei wenig Leben; Symbole neben dem Porträt, Liste im Inventar. Gespeichert in `party`.
- **Rätsel** (neue Oberfläche mit Hinweisen, Esc schließt): Lunaris hat Mondtor-Scheiben und Resonanzkristalle, die das Risstor öffnen; jede Welt hat ein eigenes Rätsel (Scheiben, Reihenfolge oder Ventile) vor dem Wächter. Daten `PZD` im Skript, Lösungen in `pz`.
- **Zwischensequenzen** (Kinobalken, Sprecher mit Porträt): Traum zum Spielstart, Orun-Begegnung und Riss-Vision in Lunaris, Lyras Ankunft, je Welt Ankunft, Rätsel/Ruinen, Boss und Abschluss. Daten `CUT`.
- **Orun** ist der zweite Boss in Lunaris (nach dem Mondwolf) und gibt die Weltenklinge (+8 Angriff).

## Endspiel: Weltenriss (Kapitel 11)
- Öffnet im Weltentor, sobald Elyndra geschafft ist (Ankunfts-Zwischensequenz, Hub mit Veyra, Kael, Eryn, Toren).
- **Sieben Siegel** im Norden, je mit Zwischensequenz: Weltenbrecher (Der erste Wächter, Die Wurzel ohne Ende, Der Goldene Koloss, Der Sandkönig, Der Abyss, Das Frostherz, Der Feuerkern) → Wächter des Dungeons → Siegel-Rätsel (Scheiben) → Schatzkammer mit Splittern und Tränken. Fortschritt in `end`.
- **Drei Enden** bei Veyra, wenn alle Siegel gebrochen sind: Getrennt bewahren, Vereinen, Verweben (jeweils mit Zwischensequenz, später änderbar). Gewählt wird in `ending`.
- Vereinfacht gegenüber dem alten Spiel: Die Dungeons sind Siegel-Stationen mit Wächterkampf statt begehbarer Räume.

## Casino, Nautilux, Nebenaufträge, Halle der 100, NG+
- **Golden Star Casino** in Valdoria (Kapitel 3): Kristallslots mit Einsätzen 10/50/100, nur virtuelle Splitter, abschaltbar (Familienoption, `cas.off`).
- **Nautilux** (Professorium schenkt sie nach Kapitel 1, `fl.naut`; Vorlage: Master-Sheet „Professoriums modulares Fahrzeug, U-Boot und spätere Transformationen“): V (am Handy 🚤) steigt ein und aus, B (🔄) wechselt die Form. Sie verwandelt sich im Spielverlauf:
  - **Gleiter** 🚤 (ab Kapitel 1): schnell, rammt Gegner.
  - **U-Boot** 🛥️ (nach Kapitel 4): taucht in die blauen **Tiefsee-Becken** jeder Welt (zwei Truhen darin); Shift = Turbo.
  - **Luftschiff** 🎈 (nach Kapitel 7): fliegt über Klippen zu **Himmelstruhen** auf hohen Felsen, nimmt wenig Schaden; Landen nur auf flachem Boden.
  - **Riss-Form** 🔮 (nach Kapitel 10): am schnellsten, Rammen mit 2,6-fachem Schaden.
  Steigt bei Dialog, Reise und Tod automatisch ab.
- **Kollision**: Spielerbewegung läuft in Teilschritten (kein Durchtunneln bei Dash, Turbo oder niedriger Bildrate), Hindernisse werden in zwei Durchgängen aufgelöst, alle Felsen, Rissscherben, Risstor-Pfeiler und Hochhäuser sind fest, und auch das Luftschiff stößt an Häuser, Bäume und Felsen (es fliegt nur über Gelände und Klippen).
- **Nebenaufträge** im Weltenriss-Hub (Sela, Nerea, Professorium, Kael, Eryn, Toren): zählen Gegner in Lunaris, Elaris, Aqualis, Elyndra, Erinnerungssplitter und Rissessenz; Belohnung sind Splitter und ein Andenken (+1,5 Angriff). Stand im Menü unter „Nebenaufträge“.
- **Halle der 100**: 100 Prüfungen in Wellen, jede zehnte ein Bosskampf, Rang-Belohnungen (`hall`). Vereinfacht gegenüber dem alten Spiel (Wellen statt Arena-Rängen).
- **Neues Spiel+**: nach einem Ende bei Veyra wählbar. Behält Stufe, Splitter, Waffen, Andenken, Nautilux, Gefährten, Halle und Nebenaufträge; Gegner mit +50 % Leben und +35 % Angriff je Stufe, Bosse mit Raserei-Phase.

## Grafikupdate (Oktober 2026)
- Terrain: kleine prozedurale, gekachelte Bodenstruktur sowie feinere Farbvariation; Weg nach Lunaris mit flachen Randsteinen.
- Mondwald: vollere Baumkronen mit hellen Blattspitzen. Zusätzliche Kronenteile und Wegsteine nutzen Instancing für geringe Draw-Call-Kosten.
- Dorf: steinerne Sockel und Türstufen, helle Eckleisten, gefasste Fenster mit Sprossen und Fensterbänken, Dachkanten und Dachspitzen. Dachdetails werden beim Betreten zusammen mit den Dächern ausgeblendet.
- Etwas klareres Mondlicht und weniger dichter Fernnebel. Speicherformat, Kollisionen und Weltpositionen bleiben gleich.

Prüfung: Inline-JavaScript syntaktisch geprüft; vollständiger Weltaufbau mit Three.js r128 und simuliertem Renderer geprüft. Alle zehn Instancing-Gruppen bleiben innerhalb ihrer Kapazität, und die 592 Kollisionskreise entsprechen exakt dem vorherigen Stand. Ein echter Browser- oder Handytest war in dieser Umgebung nicht möglich.
