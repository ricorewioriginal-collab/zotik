# Sicherheit und Datenschutz

Es gibt im aktuellen Prototyp keine Accounts, Telemetrie, Netzwerkverbindung, externen Streams oder Marketplace-Funktion. Lokale Spielstände und Einstellungen liegen im Godot-Benutzerverzeichnis. Der Prüfsummen-Hash von Saves ist keine Sicherheitsgrenze.

## Anforderungen für spätere Online-Funktionen

- Server validieren Aktionen, Inventar, Besitz, Housing-Berechtigungen und Marktdaten.
- Community-Dateien strikt validieren; keine beliebige Codeausführung.
- Keine Secrets, Signierschlüssel oder personenbezogenen Daten committen oder protokollieren.
- Online-Integrationen optional, transparent, datensparsam und abschaltbar ausführen.
- Datenschutz, Nutzungsbedingungen, Chat, UGC, Käufe und Alters-/Familienfunktionen vor Veröffentlichung fachlich prüfen lassen. Dieses Dokument ist keine Rechtsberatung.

`.gitignore` schließt lokale `.env`-Dateien und gängige Signiermaterialien aus; echte Geheimnisse gehören trotzdem nie in Git.
