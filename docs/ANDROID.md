# Android

Der Godot-Prototyp verwendet den Compatibility-Renderer und eine skalierbare Canvas-UI. Auf Android zeigt die Testregion eine einfache Touch-Steuerungsgrundlage; sie löst dieselben `move_*`, `interact` und `attack` Input Actions wie Tastatur und Gamepad aus. Optionale Controller-Eingabe wird über die Projektaktionen gemappt.

Das ist noch keine fertige mobile Bedienung. Safe-Area-Behandlung, Gesten-/Joystickkonfiguration, umfassende Geräte-/Auflösungsprüfung, Android-Export, Signing und Store-Paketierung müssen vor einem Build ergänzt und getestet werden. Schlüssel bleiben lokal und ungecheckt.
