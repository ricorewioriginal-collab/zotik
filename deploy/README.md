# ZOTIK – Server-Deploy (Windows + Android)

Ein Skript auf dem eigenen VPS prüft alle 5 Minuten, ob es auf `main` einen neuen Commit gibt. Wenn ja:
Tests laufen lassen → Windows-ZIP und Android-APK bauen → unter `/var/www/zotik/latest/` veröffentlichen.
Läuft ohne GitHub Actions.

## Einrichten (einmalig, auf dem VPS, Debian/Ubuntu)

```bash
git clone https://github.com/ricorewioriginal-collab/zotik.git && cd zotik/deploy
sudo bash install.sh
sudo systemctl start zotik-deploy.service     # ersten Build sofort starten
journalctl -u zotik-deploy -f                 # zusehen
```

Danach:

| | |
|---|---|
| Download-Seite | `http://<server>/` |
| Android-APK | `http://<server>/latest/ZOTIK-android-arm64.apk` |
| Windows-ZIP | `http://<server>/latest/ZOTIK-windows-x86_64.zip` |
| Versionsinfo | `http://<server>/latest/latest.json` |

HTTPS (empfohlen für Handy-Downloads): `sudo apt install certbot python3-certbot-nginx && sudo certbot --nginx -d deine.domain`.

## Einstellungen

`/etc/zotik-deploy.env` (Vorlage: `zotik-deploy.env.example`): Ziele (`TARGETS`), Tests an/aus (`RUN_TESTS`), Anzahl aufbewahrter Versionen (`KEEP`), Cloud-Speicher-OAuth-Client.
Privates Repository: `REPO_URL` auf eine SSH-URL setzen und einen Read-only-Deploy-Key für den Benutzer `zotik-deploy` hinterlegen.

## Wichtig für Android-Updates

* Android installiert ein Update nur, wenn **Versionscode höher** und **Signaturschlüssel gleich** sind. Das Skript setzt den Versionscode automatisch auf die Anzahl der Commits (vorher stand er fest auf 4) und signiert immer mit `/var/lib/zotik-deploy/zotik.keystore`.
* Die bisherigen GitHub-APKs wurden bei jedem Build mit einem **neuen** Zufallsschlüssel signiert. Deshalb muss die alte App **einmal deinstalliert** werden (Spielstand vorher über „Spielstand übertragen“ sichern). Ab dann gehen alle Updates direkt darüber.
* **Den Keystore sichern** (Kopie außerhalb des Servers). Ohne ihn lässt sich später kein Update mehr über die Installation legen.
* Windows hat keinen Installer: neues ZIP entpacken (Spielstände liegen im Benutzerordner und bleiben erhalten).

## Betrieb

* Neu bauen ohne neuen Commit: `sudo -u zotik-deploy /usr/local/bin/zotik-deploy --force`
* Schlägt ein Commit fehl (Tests/Export), wird er nicht erneut versucht, bis ein neuer Commit kommt oder `--force` benutzt wird. Logs: `/var/lib/zotik-deploy/last_tests.log`, `last_export.log`.
* Der Stand auf dem Server bleibt bei einem Fehler unverändert (die alte Version bleibt online).
* Beim ersten Android-Export meldet Godot ggf. fehlende SDK-Versionen (Build-Tools/Plattform): in `install.sh` über `ANDROID_PACKAGES` anpassen und erneut ausführen.
* Hinweis: Dieses Skript wurde mit einem Godot-Ersatzprogramm auf Ablauf und Versionierung geprüft, aber noch nicht auf einem echten VPS mit echtem Godot/Android-SDK ausgeführt.
