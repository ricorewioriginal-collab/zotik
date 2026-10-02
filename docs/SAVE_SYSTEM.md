# Save-System

## Implementiert

`SaveManager` speichert drei lokale Slots unter `user://saves/slot_<n>.json`. Die Daten enthalten eine Versionsnummer, serialisierbare Payload und einfache JSON-Hash-Prüfsumme. Ein bestehender Slot wird vor Überschreiben als `.bak` kopiert. Die Testregion speichert Regions-ID, Spielerposition als Zahlenpaar, eingesammelte stabile Item-ID, Rätselzustand und Siegelstatus. Es werden keine Node-Referenzen serialisiert.

## Grenzen und nächste Schritte

Die Prüfsumme ist eine grundlegende Beschädigungserkennung, keine kryptografische Authentizitätsgarantie. Der Loader akzeptiert aktuell nur die gegenwärtige Version; Migrationsfunktionen und Wiederherstellung aus Backups sind noch nicht implementiert. Autosave, mehrere auswählbare UI-Slots, Konfliktbehandlung und Cloud-Sync sind ebenfalls geplant, nicht vorhanden. Cloud bleibt optional.
