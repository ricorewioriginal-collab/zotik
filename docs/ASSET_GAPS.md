# Asset Gaps – Phase 1

States per `docs/05_ASSET_SCENE_MANIFEST.md`: MISSING → PLACEHOLDER → DRAFT → REVIEW → APPROVED → IMPLEMENTED.
Reference sheets are art direction, not game-ready assets.

| Asset | Reference | Game asset state |
|---|---|---|
| CHAR_ZOTIK_MASTER_001 (model, rig, base animations, tail/ear channels, face blend shapes) | `reference/approved/ZOTIK_MASTER_CHARACTER_SHEET_1.0.png` | MISSING |
| Zotik modular cosmetics (Mein Zotik) | `MASTER_SHEETS_1.0_MAIN_CAST.png`, `TECHNICAL_SHEETS_1.0.png` | MISSING |
| CHAR_MIRA_MASTER_001 | `ZOTIK_MIRA_PROFESSORIUM_MASTER_SHEET_1.0.png` | MISSING |
| CHAR_PROFESSORIUM_MASTER_001 | `ZOTIK_MIRA_PROFESSORIUM_MASTER_SHEET_1.0.png` | MISSING |
| CHAR_LYRA_MASTER_001 | `MASTER_SHEETS_1.0_MAIN_CAST.png` (board only, no individual sheet) | MISSING – individual master sheet also missing |
| NPCs Toren, Boro, Elwen, Finn, Sari | none | MISSING – no reference |
| ENEMY_RIFTLING_001 | `ENEMY_BOSS_WEAPON_MASTER_SHEET_1.0.png` | MISSING |
| ENEMY_MOONWOLF_001 | `ENEMY_BOSS_WEAPON_MASTER_SHEET_1.0.png` | MISSING |
| BOSS_ORUN_001 (3 phases, state-driven materials) | `ENEMY_BOSS_WEAPON_MASTER_SHEET_1.0.png` | MISSING |
| WEAPON_WORLD_BLADE_001 (resonance VFX) | `ENEMY_BOSS_WEAPON_MASTER_SHEET_1.0.png` | MISSING |
| Lunaris modular kit (home, village, market, training, forest gate) | `MASTER_SHEETS_2.0_WORLD_OBJECTS.png` | MISSING |
| Moon Forest, ruins, Moon Gate, Rift Cave, Resonance Bridge, Weltenanker, Orun arena | `MASTER_SHEETS_2.0_WORLD_OBJECTS.png`, `19_VISUAL_REFERENCES/` | MISSING |
| UI (HUD, dialogue, inventory, shop, quest log, save) | `19_VISUAL_REFERENCES/*ui*` | MISSING |
| VFX (rift, resonance, hits) | `MASTER_SHEETS_2.0_WORLD_OBJECTS.png` | MISSING |
| Music / SFX / voice | none | MISSING – no reference |
| Cutscenes (in-engine) | story flow in `docs/01` | MISSING |

## Plan
Gameplay milestones use clearly labelled placeholder primitives (capsules, boxes, coloured materials) named `PLACEHOLDER_*`.
Gameplay code addresses actors by content ID and never by mesh, so final art can replace placeholders without rewrites.
Producing final 3D art (Blender/media generation) is outside what can be done or verified in this repository environment.
