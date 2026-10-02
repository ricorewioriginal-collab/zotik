# ZOTIK – Phase 1 project (Godot 4.7)

Lunaris vertical slice: New Game → Mein Zotik → Lunaris → Mondwald → Mondtor → Risshöhle/Resonanzbrücke → Mondwolf → Weltenanker → Orun → Weltenklinge → return → Professorium/Lyra.

Open the folder in Godot 4.7, or run `godot --path game/zotik`.

## Controls (keyboard / gamepad)
| Action | Keys |
|---|---|
| Move | WASD / left stick |
| Camera | mouse (captured) / right stick |
| Jump | Space / A |
| Attack | left mouse, J / X |
| Dodge (i-frames) | F / B |
| Block | right mouse / R3 |
| Lock-on | Q / LB |
| Interact / continue dialogue | E / Y |
| Use potion | R |
| Inventory · Quest log | I · L |
| Puzzle reset · hint | T · H |
| Pause | Esc / Start |

## Tests
```
GODOT=/path/to/Godot_v4.7 tools/run_tests.sh          # all tests
GODOT=/path/to/Godot_v4.7 tools/run_regression.sh     # + golden path restart check
```
Code layout: `core/` (autoload systems, rules), `scenes/` (player, world entities, UI), `data/` (all content, validated by `core/content.gd`), `tests/`.
