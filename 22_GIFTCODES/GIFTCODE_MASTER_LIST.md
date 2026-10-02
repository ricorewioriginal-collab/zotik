# ZOTIK – Giftcode Masterliste

Status: VERBINDLICHES Konzept / Produktionscodes erst serverseitig generieren
Stand: 2026-09-24

## 1. Öffentliche vordefinierte Community-Codes

| Code | Belohnung |
|---|---|
| WELCOMEZOTIK | 500 Lun + Heiltrank ×5 |
| HELLOELYNDRA | 1.000 Lun |
| ZOTIKSTART | Starter-Kosmetik „Waldabenteurer“ |
| WELTENRISS | Risssplitter ×5 |
| LUNARISLOVE | Mond-Anhänger |
| ELARISGREEN | Waldblüten-Emote |
| VALDORIA | 2.000 Lun |
| SOLMERA | Sonnenstaub ×10 |
| AQUALIS | Wasserperlen ×10 |
| FROSTHAIN | Frostkristall ×5 |
| IGNARA | Feuerherz |
| NOCTARIS | Schatten-Emote |
| ASTRALIS | Sternenstaub ×10 |
| ELYNDRA | Weltenkristall ×3 |
| RIFTREADY | Risssplitter ×10 |
| ZOTIKDANCE | Tanz „Zotik Shuffle“ |
| ZOTIKFUN | Gimmick „Großer Kopf“ |
| PARTYELYNDRA | Party-Emote |
| WELTENFREUND | Freundschafts-Emote |
| PROFESSORIUM | Professorium-Gimmick |
| NAUTILUX | Nautilux-Horn-Emote |
| RISSKICK | Siegerpose „Rissenergie“ |
| 1000LUN | 1.000 Lun |
| TREASUREZOTIK | Schatzfinder ×1 |
| CAMPFIRE | Lagerfeuer-Emote |
| MOONWALK | Tanz „Mondschritt“ |
| TEAMZOTIK | Gruppenpose |
| THANKYOU | Dankeschön-Paket |
| COMMUNITY | Community-Emote |
| ZOTIKFOREVER | kleine Zotik-Kosmetik |

## 2. Eventcodes
- FROSTHAIN2026
- ELYNDRA2026
- ZOTIKWEEN
- WINTERZOTIK
- SPRINGRIFT
- SUMMERELYNDRA
- ANNIVERSARYZOTIK
- NEWYEARZOTIK

Eventcodes erhalten jeweils serverseitig definierte Ablaufdaten und Redemption-Limits.

## 3. Exklusive Creator-/Partner-Codes
- ZOTIK_CREATOR_01 → Creator-Pose
- ZOTIK_CREATOR_02 → Creator-Tanz
- ZOTIK_CREATOR_03 → exklusives Outfit
- ZOTIK_STREAM_01 → Streamer-Emote
- ZOTIK_STREAM_02 → Siegerpose
- ZOTIK_PARTNER_01 → Partner-Kosmetik
- ZOTIK_PARTNER_02 → exklusives Gimmick

## 4. Beta-/Community-Codes
- FIRSTFRAGMENT → Gründer-Emote
- EARLYZOTIK → Early-Player-Siegerpose
- RIFTTESTER → Beta-Tester-Kosmetik
- WELTENBAUER → exklusives Housing-Bauteil
- FIRSTEXPLORER → exklusiver Rucksack
- ANCIENTZOTIK → antike Zotik-Kosmetik
- MEMORYKEEPER → Erinnerungsemote
- RIFTWALKER → Rissläufer-Siegerpose

## 5. Ultra-exklusive Codes
Beispielhafte Serien für spätere serverseitige Generierung:
- ZOTIK-EX-0001
- ZOTIK-EX-0002
- ZOTIK-EX-0003
- ZOTIK-EX-0004
- ZOTIK-EX-0005

Diese sichtbaren Beispiele sind Platzhalter und dürfen nicht als sichere Produktionscodes verwendet werden.

## 6. Giftcode-Datenmodell
Jeder Code besitzt mindestens:
Code-ID, Code-Hash/Serverwert, Typ, Reward-Bundle, Status, Startdatum, Ablaufdatum, globale Redemption-Grenze, Account-Limit, Plattform, Region, Creator/Quelle, Erstellungszeit, Einlösungsstatistik und Widerrufsstatus.

### Code-Typen
- PUBLIC: öffentlich, optional mehrfach bzw. einmal pro Account konfigurierbar.
- EXCLUSIVE: nur für definierte Zielgruppe/Account/Creator.
- SINGLE_USE: exakt einmal einlösbar.
- EVENT: zeitlich begrenzter Code.
- PROMO: Kampagnen-/Partnercode.

### Sicherheitsregeln
Produktionscodes werden zufällig generiert und serverseitig validiert. Keine vorhersehbaren Serien als echte Produktionscodes verwenden. Einlösung atomar protokollieren und Replay/Mehrfacheinlösung verhindern. Codes müssen deaktivierbar und widerrufbar sein.
