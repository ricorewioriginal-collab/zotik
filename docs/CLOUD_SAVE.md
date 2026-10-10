# Cloud-Speicher (optional)

Spielstände folgen dem Spieler zwischen Web-Version und Apps. Gleiches Firebase-Projekt und gleiches Dokumentformat wie im easygames-Repo (`cloud/anmacha-cloud.js`).

## Web
`web/zotik_shell.html` bindet das Skript aus easygames ein (Prefix `zotik_save_`). Zotik spiegelt jeden Spielstand schon in localStorage, das Skript gleicht diese Schlüssel mit Firestore ab. Am Spielcode ändert sich nichts. Anmeldung: ☁-Knopf unten links, Google.

## Apps (Windows, Linux, Android)
`core/cloud_sync.gd` (Autoload `CloudSync`), Menü: Pause → „Spielstand übertragen“ → „Cloud-Speicher“.
- Anmeldung: Google-Gerätecode (Code in der App, Eingabe auf google.com/device), getauscht gegen einen Firebase-Nutzer. Gespeichert wird nur das Refresh-Token in `user://cloud.cfg`.
- Pro Slot gewinnt der neuere Stand (`saved_at`). Abgleich beim Start, nach jedem Speichern (5 s verzögert) und beim Pausieren der App.
- Aus bis `OAUTH_CLIENT_ID` in `cloud_sync.gd` gesetzt ist.

## Einrichtung (einmalig)
1. Firebase-Projekt, Authentication (Google) und Firestore mit den Regeln aus easygames `cloud/firestore.rules`.
2. Google Cloud Console → APIs & Dienste → Anmeldedaten → OAuth-Client-ID vom Typ „Fernseher und Geräte mit begrenzter Eingabe“ im selben Projekt; Client-ID und Secret in `cloud_sync.gd` eintragen (stehen in der App, sind kein Geheimnis).
3. Firebase → Authentication → Google → „Client-IDs externer Projekte zulassen“: die Client-ID eintragen, falls die Anmeldung mit `INVALID_IDP_RESPONSE` scheitert.

Tests: `tests/unit/test_cloud_sync.gd` (Merge, Dokumentformat inkl. gzip aus dem Browser, Rohtext-Rundlauf). Der Geräte-Login selbst ist nur gegen echte Google-Dienste prüfbar.
