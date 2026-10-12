# Web-Zotik: Kingdom-Hearts- und Lufia-Elemente – Plan

Owner-Auftrag 2026-10-13: „Elemente aus Lufia und Kingdom Hearts, unser Vorbild für Zotik … richtig verdrahtet.“
Ausgewählt (alle acht, ein gemeinsamer Pull Request): Befehlsmenü + Zielerfassung, Reaktionsbefehle,
Gefährten-Team-Angriffe, Rissform (Verwandlung), Ausrüstung + IP-Leiste, Kapselmonster (Felli),
Werkzeug-Dungeons, Uralte Höhle.

Betroffen ist nur die Browser-Version `zotik/index.html` (und ihre Kopie in `easygames/zotik/`).
Übernommen werden Spielmechaniken, keine geschützten Namen oder Designs der Vorbilder.

## Systeme

| System | Vorbild | Umsetzung in Zotik |
|---|---|---|
| Befehlsmenü | Kingdom Hearts | Befehlsleiste links unten (PC): Angriff, Magie ▸, Items ▸, Spezial ▸, Werkzeug ▸. Pfeil hoch/runter wählen, Enter ausführen, Backspace zurück, Maus klickbar. Handy: Fähigkeit-Taste (Magie/Items) und neue Spezial-Taste ⟡ (Team, Form, IP, Werkzeug). |
| Zielerfassung | Kingdom Hearts | Q bzw. 🎯: nächstes Ziel / weiter / aus. Kamera hält Ziel im Bild, Angriffe und Zauber richten sich aufs Ziel, Markierung über dem Gegner. |
| Reaktionsbefehle | Kingdom Hearts | F bzw. Aktion-Taste, sobald „▲ Reaktion“ erscheint: Konter (Biss/Sprung), Mondsprung (Heulen), Reflektor (Geschoss), Finisher (Gegner unter 22 %). |
| Team-Angriffe | Kingdom Hearts (Limits) | Teamleiste füllt sich durch Treffer von Zotik und Gefährten. Lyra „Sternenregen“, Nia „Pfeilhagel“, Rovan „Schildsturm“. Taste T. |
| Rissform | Kingdom Hearts (Drive) | Rissleiste füllt sich im Kampf. G verwandelt: Rissform (Kraft, ab Orun) oder Sternform (Magie, ab Kapitel 6), je 18 s. |
| Ausrüstung + IP | Lufia 2 | Waffe, Rüstung, Schmuck mit Werten. IP-Leiste füllt sich, wenn Zotik getroffen wird. Jedes Teil hat eine IP-Technik (Tasten 4/5/6). Quellen: Truhen, Läden, Werkzeug-Ruinen, blaue Truhen der Uralten Höhle. |
| Kapselmonster | Lufia 2 | Felli kämpft mit, sammelt Erfahrung, frisst Gegenstände (Füttern im Menü) und entwickelt sich: Moosling → Blütling (Lv 5, heilt) → Dornling (Lv 10, Flächenangriff) → Waldgeist (Lv 15). |
| Werkzeug-Dungeons | Lufia 2 | Werkzeuge als Kapitelbelohnung: Enterhaken (Kap. 2), Bombe (3), Feuerstab (4), Eisstab (5). In jeder Welt eine Werkzeug-Ruine mit Schiebeblöcken, Druckplatten, Rissmauern, Dornen, Fackeln, Wasser und Pfosten; Belohnung: Ausrüstung. Lunaris-Ruine = Schiebeblock-Einführung. Taste C benutzen, X wechseln. |
| Uralte Höhle | Lufia 2 | Eingang in Lunaris nach Kapitel 1. 50 Zufallsebenen, Start mit Stufe 1 ohne Ausrüstung, rote Truhen nur für den Lauf, blaue Truhen bleiben. Alle 10 Ebenen Wächter, Ausgangskristall auf jeder Ebene, Rekord im Menü. |

## Annahmen (geloggt)
1. Die Uralte Höhle ist nur allein betretbar (nicht im Koop), damit Stufe/Inventar-Rücksetzung sauber bleibt.
2. Werkzeug-Ruinen sind optional; der Hauptpfad bleibt ohne Werkzeug spielbar (alte Spielstände können nicht hängenbleiben).
3. Werkzeuge werden beim Abschluss des Kapitels vergeben; bereits abgeschlossene Kapitel geben sie beim Laden nachträglich.
4. Rissform ist freigeschaltet, sobald Orun besiegt ist (auch für alte Spielstände), Sternform nach Kapitel 6.
5. Die neuen Werte (Ausrüstung, IP, Felli, Werkzeuge, Höhle) sind pro Spieler und werden im Koop nicht geteilt.
6. Neues Spiel+ behält Ausrüstung, Felli, Werkzeuge und Höhlenrekord.

## Abnahme
Voller Regressionsdurchlauf (Kapitel 1–10, Endspiel, Halle, Casino, Laden) plus gezielte Tests je System; Ergebnisse unten.

## Ergebnisse (2026-10-13, Headless-Chromium mit Software-GL, beide Kopien)
- Regression: Kapitel 1–10, Endspiel (7 Siegel, Enden), Halle der 100, Casino, Menüs, Speichern – ohne JavaScript-Fehler.
- Zielerfassung: Ziel erfasst, Kamera folgt. Reaktionen: Konter (29 Schaden, Gegner unterbrochen), Finisher (Gegner besiegt), Reflektor (Geschoss umgedreht).
- Rissform: Angriff 42,8 → 68,5, endet nach 18 s. IP: Mondsichel kostet 60 IP, feuert 3 Wellen. Team: Sternenregen 104–115, Pfeilhagel 118–123, Schildsturm 168 Schaden.
- Felli: Fütterung bis Stufe 12 (Dornling), Flächenangriff trifft (≈ 76 Schaden in 3 s).
- Ruinen: Lunaris-Schiebeblock öffnet Tor, Schatz gibt Mondring; Aqualis Bombe + Eis; Elaris Enterhaken (Landung frei begehbar); Solmera Dornen + zwei Fackeln öffnen Tor.
- Uralte Höhle: Start Stufe 1/Angriff 12, 10 Ebenen inkl. Wächter, rote Funde nur im Lauf, blaue bleiben, Rückkehr stellt Stufe 5 wieder her, Rekord 10.
- Fehlerkorrekturen aus der Gesamtprüfung bleiben gültig (Speicher stabil, Koop-Prüfung, Laden pausiert).
- Nicht prüfbar hier: echtes Handy, Koop über das Internet.
