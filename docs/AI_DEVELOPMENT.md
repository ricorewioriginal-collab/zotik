# Regeln für Coding Agents

Diese Regeln gelten für GitHub Copilot, Claude Code und andere automatisierte Beiträge.

1. Vor Änderungen bestehende Architektur, Dateiinhalt und Aufrufstellen suchen.
2. Keine funktionierenden Systeme blind ersetzen oder durch Platzhalter austauschen.
3. Keine Datei neu anlegen, bevor geprüft wurde, ob sie bereits existiert.
4. Bestehende Implementierungen gezielt erweitern und klein halten.
5. Keine Fake-Funktionen, leeren Buttons oder Mock-Daten als fertige Features präsentieren.
6. Keine TODO-Funktion als abgeschlossene Implementierung ausgeben; Entwicklungs-Mocks klar kennzeichnen.
7. Keine erfundenen Bibliotheken, Engine- oder Drittanbieter-APIs verwenden.
8. Keine Secrets committen oder personenbezogene Daten protokollieren.
9. Keine fremden urheberrechtlich geschützten Assets, Texte, Musik, Maps oder Designs übernehmen.
10. Dokumentation und Roadmap mit dem tatsächlichen Implementierungsstand synchron halten.
11. Tests für geänderte Verhaltensweisen ergänzen und vorhandene Tests ausführen.
12. Save-Format, Versionierung und Kompatibilität nicht beiläufig brechen.
13. Auswirkungen auf Android, Desktop, Eingaben und künftigen Multiplayer prüfen.
14. Fehler nicht durch Entfernen der betroffenen Funktion „beheben“.
15. Bei unbekannter Architektur zuerst suchen, lesen und verstehen.

Aktuelle ausführbare Prüfungen stehen in `docs/BUILDING.md`. Ein in Dokumentation erwähnter Manager oder State ist nicht automatisch implementiert.
