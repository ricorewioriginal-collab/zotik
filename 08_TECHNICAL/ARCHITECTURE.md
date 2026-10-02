# TECHNICAL ARCHITECTURE

Engine: Godot 4.x.

Empfohlene Bereiche:
scenes/player
scenes/characters
scenes/enemies
scenes/bosses
scenes/npcs
scenes/worlds
scenes/dungeons
scenes/vehicles
scenes/ui

scripts/player
scripts/combat
scripts/timeline
scripts/break
scripts/party
scripts/enemies
scripts/quests
scripts/dialogue
scripts/inventory
scripts/equipment
scripts/save
scripts/rifts
scripts/loot
scripts/world
scripts/radio
scripts/relationships

data/items
data/weapons
data/monsters
data/quests
data/characters
data/bosses
data/dialogue
data/radio

Audio-Busse:
MASTER / Musik / Radio / SFX / Stimmen / UI

Radiofehler dürfen niemals den Game-Loop blockieren.

Data-driven design verwenden, wo sinnvoll.
Bestehende Systeme immer erweitern statt duplizieren.
