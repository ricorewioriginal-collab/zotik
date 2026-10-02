# Phase 1 – M00 Repository Audit

- Date: 2026-10-02
- Audited state: commit `834d0af` (import of `ZOTIK_MASTER_2026-09-26`)
- Engine used for checks: Godot `4.7.stable.official.5b4e0cb0f` (Linux, headless)
- Reproduce: `GODOT=<godot 4.7 binary> tools/audit/m00_checks.sh`

All checks run against a temporary copy. `game/legacy_starter/` stays unmodified.

## 1. Repository content

| Area | Content | State |
|---|---|---|
| `CLAUDE.md`, `START_HERE_CLAUDE.md`, `docs/00–13` | Current master specification (Phase 1) | text only |
| `01_MASTER` … `22_GIFTCODES` | Legacy/retained specifications | text only |
| `game/legacy_starter/ZOTIK/` | Godot starter (extracted from `10_CLAUDE/ZOTIK_Build01_Godot_Starter.zip`) | see §2 |
| `reference/approved/` | 3 master sheets + 3 production boards (PNG) | art-direction references, SHA256 verified for the 3 boards |
| `19_VISUAL_REFERENCES/` | 15 concept/target images | concept only |
| `mcp/`, `status/` | Machine-readable project state | updated by this audit |
| Tests | none existed before this audit | — |

The extracted starter matches the ZIP. It holds 10 files; the ZIP also contains 43 empty directories that are not reproduced (git does not track empty directories).

## 2. Legacy Godot starter (`game/legacy_starter/ZOTIK`)

### 2.1 Project validity
| Check | Result |
|---|---|
| A1 original `project.godot` loads in Godot 4.7 | **FAIL** – `Error parsing project.godot at line 26: Expected '}' or ','` (`move_right` lacks closing `}`). Godot then loads no project settings, so **no input actions exist**. |
| A2 same project with the missing `}` added (copy) | PASS – loads, imports, main scene runs and prints its two lines |
| A3 all 6 scripts `--check-only` (on fixed copy) | PASS |
| Declared engine feature | `config/features = "4.3"`, target is 4.7 (Godot upgrades the tag when re-saved) |
| Renderer | `gl_compatibility` (desktop and mobile) |

### 2.2 Scenes
| Scene | Content |
|---|---|
| `scenes/worlds/lunaris/Lunaris.tscn` (main scene) | `Node3D` + `WorldEnvironment` + `DirectionalLight3D` + empty `WorldOrigin`. **No ground, no collision, no camera, no player, no enemies, no UI.** |

No other scenes exist. The running main scene shows nothing playable.

### 2.3 Scripts
| Script | Attached to a scene | Assessment |
|---|---|---|
| `world/Lunaris.gd` | yes (main scene) | prints two lines only |
| `player/Zotik.gd` (`CharacterBody3D`) | no | Basic camera-unaware movement, gravity, dodge. The dodge impulse is decayed by the normal `move_toward` acceleration from the next frame on; `dodge_time` only blocks re-triggering and does not shape the dodge (no i-frames). Reusable as reference only. |
| `combat/CombatController.gd` | no | Cooldown + `take_damage` duck-typing. No hitboxes, no damage formula. |
| `timeline/TimelineSystem.gd` | no | Probe: actors fire `action_ready` immediately on `advance(0)`; `speed` argument is ignored. |
| `break/BreakSystem.gd` | no | Probe: `break_completed` emitted on **every** hit once gauge is 0 (3× in test); `break_started` is never emitted. |
| `save/SaveManager.gd` | no | Probe: JSON round-trip turns ints into floats; corrupt file silently returns `{}` – no backup, no schema version, no atomic write, unchecked `FileAccess.open` on load. Contradicts the development contract (schema-versioned saves, corrupt-save backup). |

### 2.4 Autoloads
None.

### 2.5 Input map (from fixed copy)
| Action | Bindings | Note |
|---|---|---|
| move_forward/back/left/right | WASD (physical) + left stick | ok |
| attack | LMB, Space | ok |
| dodge | F, **Right arrow** (`4194321`) | README claims F12 – binding is wrong |
| block | RMB, **Shift** (`4194325`) | README only mentions RMB |
| lock_on | Q | ok |
| camera, interact, pause, menu | — | missing |

### 2.6 Gameplay systems vs. Phase-1 scope
| System | State |
|---|---|
| Boot / title / game root | missing |
| Save foundation (slots, schema, backup) | prototype only, non-compliant |
| Content registry / ID validation | missing (`items.json` uses non-canonical IDs, e.g. `healing_potion` instead of `ITEM_…`) |
| Player + Mein Zotik customization | movement prototype; no customization |
| Lunaris greybox | missing |
| NPC + dialogue | missing |
| Inventory / equipment / shop | data stub only (`items.json`, 4 entries) |
| Combat | cooldown prototype only |
| Quests | missing |
| Puzzles (Moon Gate, Resonance Bridge) | missing |
| Dungeon, boss Orun, rift, Weltenklinge | missing |
| Timeline / Break | prototypes with defects (§2.3); legacy feature, not required by the focused slice |

### 2.7 Assets
No game-ready meshes, textures, audio, animations or shaders exist. All images are concept or reference art. See `docs/ASSET_GAPS.md`.

### 2.8 Tests
None existed. Test results of this audit: `mcp/test_results.json`.

### 2.9 Build errors
Only A1 (project file parse error). No export presets exist, so no Windows build can be produced from the starter.

## 3. Reusable systems
- Input action names and WASD/gamepad bindings (after fixing the brace and the dodge/block keys).
- `Zotik.gd` movement as reference for M04.
- `items.json` item concepts (Heiltrank, Mondanhänger, Mondklinge, Weltenkernsplitter) as content input – IDs must be migrated to the `ITEM_`/`WEAPON_` namespaces.
- Timeline/Break design intent (retained legacy requirement, deferred).

## 4. Conflicts
Recorded in `docs/CONFLICTS.md` (C-04 … C-09 added by this audit).

## 5. Recommended migration actions
1. Leave `game/legacy_starter/` untouched as historical input.
2. Create the Phase-1 project as a new Godot 4.7 project in `game/zotik/` (M01), reusing input names, movement reference and item concepts from the starter.
3. Implement saves from scratch per contract: schema version, per-slot backup, atomic write, typed restore (M02).
4. Introduce a content registry that validates all cross-references at test time (M03).
5. Add a headless test runner so every milestone has executable acceptance tests.
6. Use clearly labelled placeholder geometry; no visual mesh dependency in gameplay logic.

## 6. M00 result
The repository state is reproducibly documented by this file and `tools/audit/m00_checks.sh`.
**M00_REPOSITORY_AUDIT: PASSED.**
