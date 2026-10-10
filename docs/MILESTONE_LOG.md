# Phase 1 – Milestone Log

The project owner authorized continuous work through the milestones on 2026-10-02 ("Arbeite fortlaufend …").
Each milestone is a separate commit. Tests are executed with Godot 4.7 headless:
`GODOT=<godot 4.7> tools/run_tests.sh [--json=$PWD/mcp/test_results.json] [filter]`; CI runs the same suite (`.github/workflows/tests.yml`).

## M00 Repository Audit – PASSED
See `docs/PHASE_1_AUDIT.md`.

## M01 Boot & Project Core – PASSED
- New Godot 4.7 project `game/zotik/` (C-09). The legacy starter is untouched.
- Autoloads: `EventBus` (gameplay facts), `App` (version, scene switching with missing-scene guard).
- Scenes: `boot` → `title` (Neues Spiel / Beenden) → `game_root` (World + UI layer).
- Input map: legacy actions kept and extended with jump, interact, camera, use_item, menu, inventory, quest_log, puzzle_reset and puzzle_hint (C-07). Attack moved from Space to LMB/J because Space is now jump.
- Headless test runner `tests/run_tests.gd` with `TestCase` base. It exits non-zero on failures, which was checked with a failing sentinel test.
- Tests: `tests/unit/test_m01_boot.gd` (5 tests).

## M02 Save Foundation – PASSED
- `GameState` autoload is the single source of persistent world state: flags, inventory, equipment, currency, quests, chests, puzzles, unique rewards, defeated enemies, NPC states, customization, player, play time. `from_dict()` restores exact types, which fixes the legacy int→float defect.
- `SaveSystem` autoload: 3 slots and a JSON envelope (`schema_version`, `game_version`, `saved_at`, SHA-256 checksum).
  - Writes are atomic: `.tmp` is written, then the previous valid save is kept as `.bak`, then the file is renamed.
  - A corrupt or tampered slot is kept as `.corrupt`, the backup is loaded and the status is `RECOVERED_FROM_BACKUP`.
  - Newer schemas are rejected and older schemas are upgraded through a registered migration chain.
  - A failed load leaves the current state untouched.
- `Settings` autoload: separate `user://settings.cfg` with type-checked values.
- Tests: `tests/unit/test_m02_save.gd` (9 tests). A save → separate-process load check follows in M15.

## M03 Content Registry – PASSED
- `data/*.json` contains all Phase-1 content:
  - 12 flags and 6 areas with flag-gated exits
  - 8 items (legacy items migrated, C-08) and 8 cosmetics
  - 4 enemies including Orun's 3 phases, 3 chests and Boro's shop
  - 2 puzzles with 3-tier hints, the main quest (13 steps) and the side quest (2 steps)
  - 8 NPCs with conditional dialogue selection, 24 dialogues and 4 in-engine cutscenes
  - savepoint and unique-reward rules
- All dialogue and cutscene text is marked `placeholder: true` and only paraphrases `docs/04` (C-10).
- `Content` autoload checks:
  - namespaces and global ID uniqueness
  - every cross-reference: areas, gates, drops, summons, chest contents, shop stock and prices, puzzle setup, quest conditions, effects, dialogue speakers and gates, uniques
  - cosmetic defaults
  - presence of all canonical IDs from `docs/07`
- Tests: `tests/unit/test_m03_content.gd` (7 tests, including negative tests that prove broken references, namespaces and duplicates are detected).

## M04 Player + Mein Zotik – PASSED
- `Player` (CharacterBody3D) features:
  - camera-relative movement with a third-person SpringArm camera (mouse and gamepad)
  - jump, plus dodge with invulnerability frames, which replaces the defective legacy dodge
  - block with damage reduction
  - health stored in `GameState`, death signal, heal and revive
- `Stats`: base stats from `data/world.json` plus equipment bonuses, and a shared damage formula.
- `ZotikVisual`: a clearly labelled PLACEHOLDER built from primitives. It shows the canonical non-human traits: orange fur, pointed ears, green eyes, light muzzle and chest, bushy tail, scarf and outfit. Gameplay never references it.
- "Mein Zotik" character creator: fur shade (orange shades only), scarf and outfit, with a live 3D preview. Choices are cosmetic only, validated and persisted in `GameState.customization`.
- Flow: Title → Neues Spiel → character creator → game root.
- Tests: `tests/unit/test_m04_player.gd` (8 tests: movement, camera yaw, jump, i-frames, block, death, customization, equipment). The boot test now also covers the creator step.

## M05 Lunaris Greybox – PASSED
- `data/layouts.json` defines six streamed greybox areas: Zuhause, Dorf, Mondwald, Alte Ruinen, Risshöhle (with chasm) and Weltenanker/Orun-Arena. Each has spawns per arrival direction, exits, props and entity placements.
- `WorldArea` builds an area from its data, using PLACEHOLDER primitives only.
  - Exits are triggers. A flag-gated exit has a physical barrier that disappears when the flag is set, and a locked exit shows a notification.
  - The Resonanzbrücke is a flag-dependent prop: invisible and not walkable until the puzzle is solved.
- `GameRoot` loads one area at a time and places the player at the arrival spawn.
  - Falling into the void respawns the player with fall damage. Play time is counted.
  - `sync_state` writes the position before every save. "Laden" on the title restores area and exact position.
- Interaction foundation (`Interactable`, nearest-in-range selection), `CutsceneTrigger`, and a HUD with HP, area, objective, prompt and notifications.
- Flow gating added: `FLAG_LUN_WELTENANKER_AWAKENED` (set by quest step 8) opens the arena, so Orun cannot be fought before the main quest reaches him. `FLAG_LUN_ORUN_MET` covers the one-time intro trigger.
- Content validation extended:
  - every area has a layout, and exits match `areas.json`
  - every exit target has an arrival spawn
  - every NPC, chest, puzzle, savepoint and unique is placed exactly once and in its own area
  - flag and cutscene references in layouts resolve
- Fixes found while testing:
  - The test runner now unloads the scene after each test.
  - `tools/audit/m00_checks.sh` uses a separate user directory, because the legacy probes wrote into the save directory of the new game (same project name).
  - The title offers slots that can be recovered from backup.
- Tests: `tests/unit/test_m05_greybox.gd` (8 tests). One of them raycasts ground under every spawn in every area.

## M06 NPC + Dialogue – PASSED
- `Dialogue` autoload runs NPC dialogues and in-engine cutscenes. Both are line sequences with effects that run when the sequence ends. Requests that arrive while a sequence is running are queued. `npc_talked` is emitted for NPC dialogues.
- NPC dialogue selection is data-driven: the first entry whose gates hold wins (quest step/state, flag, not_flag, has_item).
- `Effects` is the single place where content changes state: flags, items (uniques are idempotent), currency, equip, quest start, shop, cutscene, travel. `Inventory` (stack limits, equipped items protected, unique grants) and `Conditions` were added for this.
- `Npc` entity: PLACEHOLDER capsule with a name label. Its presence follows `appears_when` (Professorium, Lyra).
- Dialogue box UI. A new game plays `CUT_LUN_DREAM_001`, which sets the intro flag and starts `QUEST_MAIN_LUN_001`. Player control is locked during sequences.
- Fixes:
  - The key that closes a dialogue no longer re-opens it in the same frame (control returns after 2 physics frames).
  - `tools/run_tests.sh` now has a hard timeout, because a runner that fails to compile used to hang forever.
  - CI runs once per PR update instead of twice.
- Content validation: every dialogue must be used by an NPC.
- Tests: `tests/unit/test_m06_dialogue.gd` (7 tests).

## M07 Inventory, Equipment & Shop – PASSED
- `Shop`:
  - Buying checks stock, price, currency (Lun) and stack limit.
  - Selling pays the shop's sell ratio. Key items, uniques and worthless items cannot be sold, and neither can the only equipped copy of an item.
- `Inventory.use`: consumables (Heiltrank heals 50 and is not used up at full health). The `use_item` key uses the first consumable.
- `Chest` entity: opens once per save, gives contents and Lun, and stays open after save and load.
- UI:
  - The inventory menu (key I) shows items, equipment and stats, and lets you equip or take off accessories and use items.
  - The shop menu opens after Boro's dialogue (`open_shop` effect).
  - Player control is locked while a menu is open.
- Tests: `tests/unit/test_m07_inventory_shop.gd` (7 tests).

## M08 Combat Foundation – PASSED
- Player melee hits every enemy in a frontal cone within range, with a cooldown and damage `max(1, attack − defense)`. Lock-on targets the nearest enemy, Zotik faces it, and the lock is released on death or distance.
- `Enemy` is data-driven and has the states IDLE → CHASE → WINDUP (a telegraphed strike, 0.5 s) → RECOVER.
  - Strikes can be dodged (i-frames) and blocked.
  - Drops and Lun are paid on defeat, and `enemy_defeated` is emitted.
  - Regular enemies respawn when the area is re-entered. Persistent spawns (Mondwolf, Orun) stay defeated across save and load.
- `Boss` base: data-defined phases change attack and cooldown multipliers and can summon helpers. It is completed in M12.
- Death: Zotik falls, and after 1.5 s the area encounter resets (enemy HP, boss phase, summons). Zotik respawns at the area entry with full HP. Quest and world progress is kept.
- Fixes found while testing:
  1. **Chained area transitions.** A stale position from the previous area could trigger an exit of the new area immediately (Mondwald → Höhle → Ruinen). The player is now placed before the area is built, and exits have a 250 ms grace period. A regression test covers it.
  2. **Silent test passes.** A GDScript runtime error used to abort a test without failing it. The runner now records script errors through `Logger` and fails the test.
- Tests: `tests/unit/test_m08_combat.gd` (7 tests) and 1 new regression test in M05.

## M09 Main Quest – PASSED
- `Quests` autoload:
  - Event-driven progression from talk, defeat, area, puzzle, savepoint and item events.
  - Item and area conditions are also state-checked when a step is entered (e.g. Sari's delivery already in the bag).
  - Kill counts are stored in `progress` and survive save and load.
  - Events raised by effects are queued instead of recursing.
  - Out-of-order events are ignored: an early Orun kill or talking to Toren first does not advance the quest.
  - There is no public force or complete API; the UI can only read (docs/03).
- Step and completion effects and rewards run through `Effects`. New objectives and completions are announced.
- HUD shows the main (★) and side (•) objectives. Read-only quest log (key L).
- `QUEST_MAIN_LUN_001` (13 steps) and `QUEST_SIDE_LUN_001` (2 steps) are completable end to end by events.
- Tests: `tests/unit/test_m09_quests.gd` (7 tests).

## M10 Puzzle Framework – PASSED
- `PuzzleLogic` is data-driven:
  - `dials`: rotate (wraps after 4), then submit. A wrong submit gives feedback and keeps the state.
  - `sequence`: a wrong crystal clears the attempt.
  - Manual reset returns to the initial state. Hints come in 3 tiers, the last tier repeats, and unlocked tiers survive a reset.
  - The solved state is final and idempotent: effects and the `puzzle_solved` event happen exactly once.
- Partial puzzle state (dials, sequence progress, hints) survives save and load.
- `PuzzleNode` in the world (PLACEHOLDER): Mondtor with 3 moon-phase dials and an activation plate, Resonanzbrücke with 4 crystals. The `puzzle_reset` (T) and `puzzle_hint` (H) keys work within 9 m. Solving opens the gate or bridge through flags.
- Tests: `tests/unit/test_m10_puzzles.gd` (7 tests, including Moon Gate wrong/reset/correct in the world).

## M11 Dungeon & Resonance Bridge – PASSED
- The Risshöhle is fully built: entrance, chest, Resonanzbrücke puzzle over a real chasm, Mondwolf, Weltenanker and the gated exit to the arena.
- The bridge is physical: before the puzzle is solved, walking north drops Zotik into the chasm (respawn with fall damage). Afterwards he can walk across.
- `Savepoint` (Weltenanker) fully heals, emits `savepoint_used` (quest step 8 → opens the arena) and opens the save menu with 3 slots.
- Pause menu (Esc): resume, camera inversion (persisted in settings), back to title, quit.
- Tests: `tests/unit/test_m11_dungeon.gd` (4 tests).

## M12 Boss Orun – PASSED
- `BOSS_ORUN_001` has 3 data-defined phases:
  - Wächter: from 100 %.
  - Splitterruf: below 66 %, attack ×1.1, summons 2 Risslinge once.
  - Resonanzsturm: below 33 %, attack ×1.3, cooldown ×0.75.
  - Each phase has its own colour (state-driven material, docs/13). A single big hit runs through skipped phases exactly once.
- Defeat:
  - `on_defeat` data effects set `FLAG_BOSS_LUN_ORUN_DEFEATED`. This is idempotent and independent of the quest.
  - The boss stays defeated across save and load.
  - Summons are removed.
- Death during the fight resets boss HP, phase and summons. Progress stays unchanged.
- All enemies are passive during dialogues and cutscenes; an attack wind-up is cancelled. The arena intro (`CUT_LUN_ORUN_001`) plays once.
- Boss HP bar with name and phase in the HUD while engaged.
- Tests: `tests/unit/test_m12_boss.gd` (6 tests).

## M13 Rift, Weltenklinge & Story End – PASSED
- `UniquePedestal` appears only after Orun's defeat.
  - `WEAPON_WORLD_BLADE_001` is granted exactly once and equipped. Duplicates are impossible, including after save/load and repeated effects.
  - The blade glows on Zotik, a placeholder for "the Weltenklinge reacts to Zotik".
  - Then `CUT_LUN_RIFT_VISION_001` plays and the `travel` effect brings Zotik back to Lunaris (`return` spawn).
- Ending:
  1. Mira return dialogue: the Professorium arrives.
  2. Professorium dialogue: he recognises the Weltenklinge and the main quest completes (+100 Lun, `FLAG_LUN_CHAPTER_COMPLETE`).
  3. `CUT_LUN_LYRA_BRIDGE_001` plays and Lyra is present afterwards.
- Mira and Lyra stay separate characters with their own dialogues (MIGRATION_DECISIONS). An end-of-chapter notice is shown.
- Tests: `tests/unit/test_m13_story_end.gd` (4 tests, the ending runs through the real dialogues).

## M14 Sidequest & World Reactions – PASSED
- "Saris verlorene Lieferung" plays through in the world: Sari gives the quest, the delivery is in `CHEST_LUN_002` in the Mondwald, Zotik hands it back for 60 Lun and the Mondanhänger, and Sari gets a waiting line, a thank-you line and a follow-up line.
- NPC reactions: Toren, Boro, Elwen and Finn switch to reaction dialogues after Orun's defeat. Mira, Sari, the Professorium and Lyra react through their quest-dependent dialogues.
- Visual world reactions are data-driven (`requires_flag` / `hidden_by_flag` on layout props) and persist after save and load:
  - the rift glow in the Mondwald calms after the victory
  - banners appear in the village
  - the Professorium's machine appears on his arrival
  - Sari's crates appear after the delivery
- Tests: `tests/unit/test_m14_side_reactions.gd` (3 tests).

## M15 Complete Regression – PASSED
- Golden path from `docs/08`, played through real interactions, plus a restart check in a **new Godot process**: the persistent state after loading is identical to the state saved before quitting.
- `tools/run_regression.sh` (used by CI) runs all 92 tests and then the restart check.
- Traceability of every acceptance and regression item: `docs/ACCEPTANCE_MATRIX.md`.
- Rendered visual check (`tests/screenshots.gd` under Xvfb, `docs/screenshots/`) found and fixed four UI issues:
  - HP bar was unreadable
  - creator preview faced away from the camera
  - area boundaries were invisible
  - 3D name labels were too small
- Open items (not part of the passed tests): Windows export not executed, all art and dialogue are placeholders, no human playtest. See the matrix.

**Phase 1 milestones M00–M15: PASSED. Phase 2 is not started and requires explicit project-owner approval (CLAUDE.md rule 8).**

## P1 Playability pass (post-M15, Phase 1 polish) – PASSED
The project owner authorised autonomous work and merging on 2026-10-02. Phase 2 was **not** started (CLAUDE.md rule 8). This pass makes the existing slice playable for a human:
- **Mouse camera:** the mouse is captured while playing and freed in menus and dialogues. Before this, the camera could only be turned with a gamepad. The arrow keys ←/→ also turn the camera.
- **Objective beacon:** a light pillar with an arrow marks the current objective: NPC, puzzle, savepoint, chest, nearest target enemy, or the exit on the shortest path to the target area (`core/navigator.gd`, BFS over area exits). After the main quest it guides the side quest.
- **Controls overlay** in the HUD, toggled with F1 and persisted in the settings.
- **Combat feedback:**
  - weapon swing
  - enemy hit flash and knockback
  - floating damage numbers
  - red screen flash when Zotik takes damage
- **Placeholder sound effects** synthesised in code (`Sfx` autoload, no audio assets): swing, hit, hurt, pickup, puzzle solved/wrong, dialogue blip, enemy defeated, save.
- **Test guard:** every autoload in `project.godot` must compile and be instanced. Before this, a broken autoload only showed up as follow-up errors.
- Tests: `tests/unit/test_p01_playability.gd` (6 tests). Rendered check: `docs/screenshots/04b_village_beacon_on_mira.png`.
- Level sanity test `tests/unit/test_p02_reachability.gd`: with all gates open, every entity, exit and spawn of every area is reachable on foot from the default spawn. It uses a grid flood fill with the player radius. A mutation check confirmed that it detects a walled-in NPC.

## P2 Builds and web check – PASSED
- `build` workflow: exports Windows (38 MB), Linux (28 MB) and Web (10 MB) and smoke-tests the Linux build (boot + `CONTENT OK`). Release `phase1-latest` is published on every merge to `main`.
- GitHub Pages deploy needs a one-time repository setting (Settings → Pages → Source: GitHub Actions). The workflow token is not allowed to enable it ("Resource not accessible by integration").
- The web build from the release was loaded in headless Chromium (WebGL2 via SwiftShader). Booting, content validation, New Game, the intro and walking into the village all worked.
- That run found issues that only appear without system fonts or in real layouts. All are fixed:
  - ★ ← → ✓ ▼ glyphs showed as boxes. They were replaced, and the beacon arrow is now a 3D cone.
  - The controls overlay overlapped the dialogue box. It now sits under the HP bar and hides during dialogues.
  - The title menu was off-centre.
- New test `tests/unit/test_p03_glyphs.gd`: every string literal in game scripts and every data string must render with the built-in font. A mutation check confirmed it fails on "★".

# Phase 2 – Elaris

## E00 Phase-2 plan – PASSED
The owner authorised Phase 2. The plan is in `docs/PHASE_2_PLAN.md`; assumptions are logged as C-15 to C-18.

## E01 World travel + save schema v2 – PASSED
- `data/worlds.json` (namespace `WORLD_`): Lunaris (chapter 1), Elaris (chapter 2, unlocked by `FLAG_LUN_CHAPTER_COMPLETE`), Valdoria (sealed placeholder). Every area now has a `world`.
- Weltenstein travel points (`TRAVEL_LUN_001` in the village, `TRAVEL_ELA_001` in the Elaris town skeleton) open the **Weltkarte**. It lists the chapters, travels only to unlocked worlds and shows sealed ones as "???".
- Save schema **v2** adds `GameState.party`. The built-in migration v1 → v2 lets Phase-1 saves continue unchanged (tested with a real v1 envelope).
- The beacon routes across worlds: first to the current world's hub, then to its Weltenstein.
- Validation: area worlds, world hub area and spawn, unlock flags, `TRAVEL_` ids.
- Tests: `tests/unit/test_e01_travel.gd` (5 tests).

## E02 Party foundation (Lyra) – PASSED
- `data/party.json` (namespace `PARTY_`): `PARTY_LYRA_001`, a ranged healer, with all values in data.
- `join_party` effect (idempotent). On the first arrival in Elaris, `CUT_ELA_ARRIVAL_001` (placeholder text) adds Lyra to the party. Her Lunaris NPC is then hidden through `hidden_when`.
- `Companion` AI:
  - follows Zotik and teleports along when far away or on area changes
  - attacks enemies within 10 m of Zotik from range, but not the training dummy
  - heals Zotik below 45 % HP with a cooldown
  - passive during dialogues
  - enemies target only Zotik, so a companion can never block progress
- The party persists across save, load and area changes.
- Tests: `tests/unit/test_e02_party.gd` (5 tests).

## E03 Break system – PASSED
- Enemy data has `break` (gauge) and `break_duration`. Combat values live in `data/world.json → combat`. Enemies without a gauge, such as the training dummy, cannot be broken.
- Break amounts and effects:

  | Source | Break | Damage | Other |
  |---|---|---|---|
  | Light attack | 8 | normal | |
  | **Strong attack** (K / LB) | 25 | ×1.6 | 1.1 s cooldown |
  | Party member hit | 6 | normal | |
  | Strong attack during a telegraphed wind-up | +15 bonus | | interrupts the wind-up (the legacy "interruptible telegraphs") |

- At 0, the enemy is BROKEN: stunned, never attacks, takes ×1.5 damage. Afterwards it recovers with a full gauge.
- `break_started` and `break_ended` are each emitted exactly once, including when the enemy dies while broken. The legacy BreakSystem emitted repeatedly and never signalled the start; that defect was not reproduced.
- The enemy label shows Break progress and "[BREAK]". The HUD help lists the strong attack.
- Tests: `tests/unit/test_e03_break.gd` (5 tests). One found a real bug, fixed: `break_ended` was lost when an enemy died while broken.

## E04 Elaris greybox & content – PASSED
- Five streamed areas in the world Elaris:
  - Stadt (Forschungsviertel, Werkstatt, Weltenstein, arrival scene)
  - Der lebende Wald, where "sich bewegende Wege" are two `MovingPlatform`s (AnimatableBody3D, ping-pong) that carry Zotik across a ravine
  - Turm der Erinnerung
  - Das Herz des Waldes (dungeon with a Weltenanker)
  - Thron der Wurzelkönigin
- Gates: the forest needs `FLAG_ELA_FOREST_OPEN` (E06 quest), the dungeon needs `FLAG_ELA_TOWER_SOLVED` (E05 puzzle), the arena needs `FLAG_ELA_ROOTS_PARTED` (set by the Wurzelkriecher's `on_defeat`).
- Enemies: Pilzling, Dornenwolf and the persistent Wurzelkriecher miniboss. All have Break gauges.
- NPCs with placeholder lines: Mara (research), Elio (craftsman shop), Sela, Nia, Rovan. Names come from the legacy NPC/character lists (C-19).
- New items: Großer Heiltrank, Leuchtspore, Blattamulett (+2 DEF, +10 HP).
- Party data for Nia (archer) and Rovan (melee guardian with a higher Break value). The companion AI now handles melee and non-healers.
- Validation: platform entities (`PLATFORM_`, target, period). The reachability test counts platform sweeps as floor. It found a real gap at the ravine edges, fixed by extending the platform travel.
- Tests: `tests/unit/test_e04_elaris.gd` (6 tests, including a physical platform ride and a ravine fall).

## E05 Puzzles: Turm der Erinnerung – PASSED
- `PUZ_ELA_TURM_001` implements spec `ELARIS_TURM_01` (`20_RIDDLES`):
  - four symbol pillars (Flamme, Mond, Kristall, Blatt in physical order), each showing its symbol
  - the order must be Mond → Blatt → Kristall → Flamme
  - a wrong symbol resets the attempt (RESET_FAILURE); manual reset (T) and hints at levels 1–3 (H, level 3 = solution) are available
- Reward as specified: the key to the inner area (`FLAG_ELA_TOWER_SOLVED`), 80 Lun, Elaris lore and rare materials (2× Erinnerungskristall).
- The completion epilogue `CUT_ELA_TURM_EPILOG_001` uses the **verbatim demo dialogue from the spec** (Zotik/Nia/Rovan). It is the first non-placeholder text, and it cites its source. The content test now requires that every dialogue is either a placeholder or cites a project document.
- The "moving paths" from `04_WORLDS` were implemented as a traversal mechanic in E04 (moving platforms), not as a separate switch puzzle. The plan was adjusted accordingly.
- The glyph guard caught an "→" in a hint that would have rendered as a box on web; it was rephrased.
- Tests: `tests/unit/test_e05_tower.gd` (4 tests).

## E06 Chapter-2 quests – PASSED
- `QUEST_MAIN_ELA_001` "Der Wald, der sich erinnert" has 11 steps. It starts with the arrival scene:
  1. Mara opens the forest.
  2. Nia joins.
  3. Enter the forest.
  4. Defeat 3 Pilzlinge.
  5. Rovan joins.
  6. Reach the tower.
  7. Solve the tower puzzle.
  8. Touch the Weltenanker.
  9. Defeat the Wurzelkriecher.
  10. Defeat the Wurzelkönigin.
  11. Return to Mara: +200 Lun, `FLAG_ELA_CHAPTER_COMPLETE`.
- Party joins happen through quest step effects. Talking to Rovan early does nothing, and Nia's and Rovan's town/forest NPCs hide while they are in the party.
- `QUEST_SIDE_ELA_001` "Leuchtsporen für Sela": collect 5 spores (from Pilzlinge and the dungeon chest) for 90 Lun and 2 Große Heiltränke.
- Generalised:
  - chapter-end notices come from `completion_notice` in the quest data
  - main quests are sorted before side quests, Lunaris before later chapters
  - the HUD marks every main quest with »
- Boss data for `BOSS_WURZELKOENIGIN_001` was added (3 phases) so the quest can reference it. The arena fight follows in E07.
- Tests: `tests/unit/test_e06_quests.gd` (5 tests).

## E07 Boss Wurzelkönigin – PASSED
- `BOSS_WURZELKOENIGIN_001` (520 HP, Break 140) has 3 data phases with their own colours:
  - Erwachen: from 100 %.
  - Dornenkrone: below 60 %, 2 Pilzlinge summoned, root eruptions start.
  - Wurzelzorn: below 30 %, 1 Dornenwolf summoned, faster and larger eruptions.
- **Root eruptions:** a data-defined phase hazard. A telegraphed disc appears under Zotik and hits after a delay unless he leaves it (or dodges with i-frames). Eruptions pause during cutscenes, while the boss is broken or idle, and are cleared on defeat and on death or reset.
- One-time intro `CUT_ELA_QUEEN_001`. Defeat sets `FLAG_BOSS_ELA_QUEEN_DEFEATED` (persistent), plays the memory vision `CUT_ELA_QUEEN_DEFEAT_001` and brings the party back to Elaris town to report to Mara.
- Tests: `tests/unit/test_e07_queen.gd` (6 tests).

## E08 Chapter-2 regression – PASSED
- Chapter-2 golden path from a real v1 Phase-1 save through the whole chapter, using real interactions. The restart check now verifies **both** chapters in a fresh process, each with its own save directory.
- The rendered check of Elaris found and fixed four UI issues:
  - Companions stood on one spot and in front of the camera. They now use formation slots behind Zotik, with a test for it.
  - 3D name labels became huge up close. They now have a fixed screen size.
  - **The HUD root and other full-screen controls had size 0**, because `set_anchors_preset` does not move offsets. As a result, notifications were never centred and the red hurt flash never covered the screen. Fixed everywhere; tests now check the HUD and flash sizes.
  - Notifications overlapped the controls overlay; they were moved below it and centred.
- `docs/ACCEPTANCE_MATRIX.md` gained the Phase-2 section. Screenshots 07–10 show Elaris.

**Phase 2 (Elaris) milestones E00–E08: PASSED.** Further chapters (Valdoria, …) need owner approval and story input.

# Phase 3 – Valdoria

## V00 Phase-3 plan – PASSED
Standing owner approval was recorded in `CLAUDE.md` (rule 8 update). The plan is in `docs/PHASE_3_PLAN.md`; assumptions are logged as C-20 and C-21.

## V01 Valdoria hub – PASSED
- World Valdoria (chapter 3), unlocked by `FLAG_ELA_CHAPTER_COMPLETE`, with a one-time arrival scene. Solmera is added as a sealed placeholder for chapter 4.
- Three districts:
  - **Markt & Hafen:** Weltenstein; Haldor's smithy; Ysmé the alchemist; Lotte at the harbour; a closed casino (C-20)
  - **Gildenviertel:** Veyr's guild hall, library and arena wall
  - **Kanaltor:** Tibor at the canal gate
- New **armour slot** (`ARMOR_`, C-22): Lederwams and Kanalmantel. Also new: Stahlschwert and Elixier.
- `data/lore.json` + `LoreBook` entity: readable library books shown in the dialogue box and validated like dialogue.
- Tests: `tests/unit/test_v01_valdoria.gd` (4 tests).

## Owner concept uploads (2026-10-02) – integrated
- 20 concept boards were stored as JPEG in `reference/concept_2026-10-02/` (57 MB → 9.5 MB), with an index and status "concept, not approved".
- Applied, consistent with written canon:
  - Zotik's default scarf is now **green**. `03_CHARACTERS` says so; the earlier red default was wrong.
  - He now has a brown shoulder bag.
  - The placeholder scale follows the size comparison on the boards: Zotik ≈ 1.2 m; Rissling, Mondwolf and Orun are resized to match. Collision and camera were adjusted (C-23).
- Logged instead of decided: C-24 to C-28 (human protagonist in demo images rejected, round-based combat concept, alternative world names, the "Felli"/Moosling companion, Lyra's hair colour and Nia's role).
- C-20 resolved: the casino is wanted with virtual Lun and a family toggle. It is implemented in V03.

## V02 Guild bounties + bestiary – PASSED
- `Guild` autoload:
  - **Bestiary:** every `enemy_defeated` is counted in `GameState.bestiary`. Every enemy now has a `region` (world) and a `description`, both validated.
  - **Bounties** (`data/bounties.json`, namespace `BOUNTY_`): accept, count kills of the target enemy, then claim Lun and items exactly once. Up to 3 bounties can be active, and some are only offered behind a flag.
- Guild bounty board in the Gildenviertel. Bestiary menu on **B**, showing the `05_GAMEPLAY` fields: name, region, drops, description, times defeated. Unknown enemies show as "???", and a progress counter is shown.
- New canal enemies (data): Kanalschleim and the armoured Schleusenkrabbe (DEF 9, best handled with Break). New items: Altmetall and Jägerabzeichen (+3 ATK).
- Bestiary and bounty state persist. They are additive fields with defaults, so schema v2 still loads.
- Tests: `tests/unit/test_v02_guild.gd` (4 tests).

## V03 Arena + casino – PASSED
- **Arena** (`AREA_VAL_ARENA`, west of the Gildenviertel). Arena master Kasimir opens the challenge menu.
  - Challenges are defined in `data/arena.json` (namespace `ARENA_`). Each one is a sequence of enemy waves around the arena centre.
  - Bronze: 2 waves, 120 Lun, Hi-Potions ×2 on the first clear. Clearing it unlocks Silver (`FLAG_VAL_ARENA_BRONZE`).
  - Silver: 3 waves including the canal enemies, 260 Lun, Kanalmantel on the first clear.
  - Lun is paid on every win. Items and flags are granted only on the first clear.
  - Defeat is safe: no loss, full heal, and Zotik returns to the arena entrance. Leaving the area mid-run cancels the challenge.
- **Golden Star Casino** on the market (C-20 resolution):
  - Slot machine with virtual Lun only and bets of 10/50/100.
  - The odds are fixed in code; the expected return is ≈ 93 %, so the house edge is visible and tested.
  - The pause menu has a "Casino (Familienoption)" toggle. When it is off, the entrance is closed and spinning is blocked.
  - Spin statistics are saved (`GameState.casino`).
- New effect `open_menu` (arena/casino) and entity type `casino`, both validated by `Content`.
- Arena wins and casino statistics are additive save fields with defaults, so schema v2 still loads.
- Tests: `tests/unit/test_v03_arena_casino.gd` (7 tests).
- Regression: 156/156 tests plus restart checks for chapters 1 and 2: PASS.

## V04 Forgotten canals – PASSED
- **Kanaltor:** on first talk, Tibor opens the canal gate (`FLAG_VAL_CANALS_OPEN`); the gate prop disappears. He has follow-up lines afterwards and after the golem.
- **Vergessene Kanäle** (`AREA_VAL_CANALS`): Kanalschleim ×3 and Schleusenkrabbe, a chest (Elixier, 70 Lun) and a savepoint.
  - A flooded channel blocks the way north until the puzzle is solved.
- **New puzzle kind `valves`** (`PUZ_VAL_VALVES_001`):
  - Each valve flips the water level of its channels; the puzzle is solved when every channel is empty.
  - Channel gauges (West/Mitte/Ost) show the current state, and a notification follows each turn.
  - Reset, hints (3 tiers) and the "stays solved" rule work as for the other puzzles.
  - `Content` rejects valve setups that are malformed, already solved at the start, or unsolvable.
  - Solving sets `FLAG_VAL_CANALS_DRAINED`: the water disappears and the cistern opens.
- **Alte Zisterne** (`AREA_VAL_CISTERN`): miniboss **Rostgolem** (220 HP, DEF 7, Break 90).
  - He is persistent, sets `FLAG_VAL_ROSTGOLEM_DEFEATED` and drops Altmetall ×3 and a Hi-Potion.
  - The sealed floodgate at the back leads to the boss in V05.
- Canal enemies have their own placeholder colours and sizes.
- Test adjustment: `test_p02_reachability` now treats props removed by a flag (`hidden_by_flag`) as open. This matches its documented intent ("with every gate open").
- Tests: `tests/unit/test_v04_canals.gd` (5 tests).
- Regression: 161/161 tests plus restart checks: PASS.

## V05 Chapter-3 quests + boss Kanalwächter – PASSED
- **Main quest `QUEST_MAIN_VAL_001` "Die Stadt, die niemals schläft"** (7 steps):
  1. Veyr
  2. Tibor
  3. the canals
  4. the valve puzzle
  5. the Rostgolem
  6. the Kanalwächter
  7. report back to Veyr

  Reward: 300 Lun and `FLAG_VAL_CHAPTER_COMPLETE`.
  - The quest is started by the arrival scene. Saves that already arrived before V05 can still start it by talking to Veyr.
  - Tibor opens the gate only on the quest step "Sprich mit Tibor". This avoids sequence breaks: the order is linear (gate → puzzle → golem → floodgate), so no step can be skipped.
- **Side quest `QUEST_SIDE_VAL_001` "Ein Boot für Lotte":** bring 4 Altmetall to Lotte at the harbour. Reward: 150 Lun and 2 Hi-Potions.
- **Boss Kanalwächter** (`AREA_VAL_FLOODGATE`, behind the cistern's floodgate, which opens after the Rostgolem):
  - 640 HP and Break 160.
  - Phases: Strömung (circle eruptions), Flutwelle (summons 2 Kanalschleime), Tiefenzorn (summons a Schleusenkrabbe).
  - Intro scene plays once. The defeat scene returns the party to the canal gate.
- **New hazard kind `surge`** (water surge): a telegraphed band across the whole arena at Zotik's depth. Moving sideways does not help; stepping forwards or backwards (or dodging) does.
  - `Content` now validates hazards: kind circle/surge plus the required fields.
- V04 test updated: Tibor first needs Veyr's word (intended behaviour change from V05).
- Tests: `tests/unit/test_v05_chapter3.gd` (9 tests).
- Regression: 170/170 tests plus restart checks: PASS.

## V06 Chapter-3 regression – PASSED (Phase 3 complete)
- `tests/unit/test_v06_golden_valdoria.gd`: the chapter-3 golden path from a chapter-2 save, through real interactions (details in `docs/ACCEPTANCE_MATRIX.md`).
- `tests/restart_check.gd` now checks all three chapters in a fresh process.
- **Bug found and fixed via the screenshots:** the third companion's formation slot sat exactly on the line between the camera and Zotik, so Rovan hid Zotik. The slots are now to the sides, still behind Zotik and without overlap.
- New reference screenshots:
  - 11 Valdoria market with the casino
  - 12 canals with valves and gauges
  - 13 Kanalwächter
- Version 0.4.0.
- Regression: 171/171 tests plus restart checks for chapters 1–3: PASS.

## G01 Look & renderer – PASSED
- Plan: `docs/GRAPHICS_PLAN.md`.
- Renderer: Forward+ on PC. Android (`.mobile`) and Web (`.web`) keep the compatibility renderer, with a cheaper shadow profile (`Look.low_end()`).
- `core/look.gd`, per world:
  - procedural sky (Lunaris dusk, Elaris daylight, Valdoria golden evening)
  - sun with soft shadows, fog
  - filmic tonemapping, glow, saturation/contrast, SSAO on PC
  - dark, foggy interiors for caves and canals
- Nine CC0 Poly Haven textures at 512 px (1.3 MB total, mipmaps on), applied as world-space triplanar materials. They are tinted with the layout colours so the art direction is kept.
- Props get proper shapes; collision and node names are unchanged, so no gameplay or test change:
  - houses with a tiled roof and timber posts
  - trees with a trunk and canopy
  - water as a glossy transparent surface
  - rifts and crystals glow
- Visible area borders (hedge, town wall or cave rock) with openings at exits. Outdoor ground continues into the fog.
- Tests: `tests/unit/test_g01_look.gd` (4 tests).

## G02 Animated characters – PASSED
- `scenes/world/character_rig.gd`: a shared rig on CC0 KayKit models (5 models, 75 animations each). It scales to a target height and faces the game's forward direction (-Z), and supports:
  - idle/walk/run locomotion and one-shot actions (attack, strong attack, cast, hit, dodge, block, death)
  - choosing visible weapons, hiding body parts, attaching meshes to bones
  - palette recolouring and tinting
- **Zotik:**
  - Rig body recoloured to his fur shade and outfit colour (follows the character creator).
  - The human head is hidden. A fox head (muzzle, nose, green eyes with pupils, cheek fluff, large ears with light inner fur, hair tuft), the green scarf, light chest fur, a bushy tail with a light tip, the shoulder bag and the blade are attached to the bones, so they animate with him.
  - Animations follow the gameplay state: run/walk/idle, light or strong attack, dodge, block, hit, death.
  - `ZotikVisual`'s API is unchanged; the customization and scale tests still pass.
- **Companions:**
  - Lyra: mage with staff.
  - Nia: hooded archer with crossbow.
  - Rovan: barbarian guardian with axe and shield.
  - Walk/run animations follow movement; casts or swings play on attacks.
- **NPCs:** a model and height each, tinted with their colour.
- Formation slots moved further to the sides and the camera pulled back slightly (4.2 → 5.0 m), so the wider models do not fill the screen.
- Conflict C-29 logged: chibi interim proportions versus the owner's target look.
- Tests: `tests/unit/test_g02_characters.gd` (3 tests).
- Regression: 178/178 tests plus restart checks: PASS.

## G03 Enemies & bosses – PASSED
- `scenes/world/creature_visual.gd`: procedural interim creatures following the enemy master sheet (dark bodies, emissive rift crystals and eyes). Archetypes:
  - **imp:** Rissling, with large glowing eyes and a crystal crest
  - **wolf:** Mondwolf with a blue crystal ridge, Dornenwolf with a green thorn ridge
  - **golem:** Orun, Rostgolem, Kanalwächter, with rounded rock bodies, a glowing core, horn crystals and crystal clusters on the shoulders
  - **queen:** a golem with a crystal crown and root tendrils
  - **mushroom:** Pilzling, with a glowing-spotted cap
  - **slime:** Kanalschleim, translucent with a glowing core and squash
  - **crab:** Schleusenkrabbe
  - **roots:** Wurzelkriecher
  - **dummy:** training dummy
- Animation from the enemy state: idle bob, walk cycle, wind-up rear-back, strike lunge, dazed wobble while broken. Hit and wind-up tints still work. Defeat shows a short burst of rift light.
- Rift and crystal glow is toned down so it keeps its colour instead of blowing out to white.
- Tests: `tests/unit/test_g03_creatures.gd` (3 tests). Regression: 181/181 tests plus restart checks: PASS.

## A01 Android – implemented; APK build verified by CI only
- **Touch controls** (`scenes/ui/touch_controls.gd`). They are active on Android or any touch screen, and can be forced via "Touch-Steuerung" in the pause menu.
  - virtual stick on the left
  - swipe on the right half to turn the camera
  - action buttons: Angriff, Stark, Ausweichen, Springen, Benutzen, Block, Trank
  - menu buttons: Menü, Inventar, Quests, Bestiarium

  They send the same input actions as keyboard and gamepad, so gameplay is unchanged. Behaviour:
  - Hidden during dialogue (a tap advances it) and while menus are open (menus are touchable).
  - The keyboard help is hidden and the mouse is not captured in touch mode.
- Landscape (sensor) orientation and `expand` aspect for phone screens. ETC2/ASTC texture import is on; Android uses the compatibility renderer (`rendering_method.mobile`).
- **Export preset "Android":** arm64-v8a, package `de.zotik.splitterderwelten`, immersive mode.
- **CI** (`build.yml`) adds:
  - Java 17, the runner's Android SDK, a generated debug keystore and Godot's Android template
  - export of `ZOTIK-android-arm64.apk` (debug-signed), checking the arm64 library is inside
  - publishing the APK with the rolling release
- The APK cannot be built in this container: there is no Android SDK or template here. The build is therefore verified only by CI. It has not been tested on a real device.
- Tests: `tests/unit/test_a01_touch.gd` (3 tests). Regression: 184/184 tests plus restart checks: PASS.

## A01 follow-up – owner device test (2026-10-02)
- The owner tested the APK and found the controls "buggy". Two root causes were found and fixed:
  1. Android turns every touch into an emulated left click, and `attack` is bound to the left mouse button, so every stick, camera or button touch also attacked. Mouse-button bindings are now removed while touch mode is on and restored when it is off.
  2. The stick sent its "release" only if `Input.is_action_pressed` already reported the action. Input is buffered until the next frame, so a quick flick left Zotik walking. The stick now tracks its own pressed actions.
- The CI APK build is green, so A01 counts as PASSED. It still needs another device test by the owner.
- Tests: `test_a01_touch` gained 2 regression tests; 5 in total.

## G04 World dressing – PASSED
- 40 curated CC0 models from the KayKit Medieval Hexagon pack (2.5 MB).
  - Buildings replace the procedural houses, fitted inside the prop's collision footprint:
    - homes A/B in the world colour (Lunaris blue, Elaris green, Valdoria red)
    - blacksmith, market, church (library, research hall), tavern (guild hall)
  - Trees use real tree models.
- Backdrop beyond the walkable border (outdoors only, purely visual, exit openings left free):
  - an inner row of trees, or town houses facing inwards in Valdoria
  - an outer row of forest clusters
  - halved density on Android and Web
- The pack's hexagon hills and mountains were tried and rejected: they look blocky, which is exactly what the owner criticised.
- **Bug fixed:** the invisible border colliders were drawn as 5 m fog-coloured walls, which showed as a grey band at the horizon. They are now collision-only.
- Outdoor borders are a low stone edge, so the forest behind them stays visible.
- Regression: 186/186 tests plus restart checks: PASS.

## U01 UI overhaul – PASSED (owner request: Final Fantasy / Kingdom Hearts direction)
- **Design system** `core/ui_style.gd`:
  - dark navy glass panels with gold trim and crystal-blue highlights
  - Cinzel for titles, Exo 2 for text (both OFL)
  - saved as `assets/ui/zotik_theme.tres` and set as the project theme. A theme set only on the root window does not reach controls under a CanvasLayer. A test keeps the file in sync with the builder.
- **HUD** (same API as before; all tests unchanged):
  - top left: Zotik frame with a painted portrait, HP and Lun, plus party frames (portrait, name, role, HP, readiness bar)
  - top right: a round minimap drawn from the layout data (no second 3D render, so it stays cheap on Android). It shows props, exits, NPCs, enemies, the objective and Zotik's facing.
  - area title and an "Aktuelles Ziel" quest box
  - boss bar in an ornate frame
  - interaction prompt chip
  - icon bar with drawn icons (Inventar, Quests, Bestiarium, Menü). On touch screens it moves under the party frames, and taps on it are not treated as stick or camera input.
- **Dialogue box:** wide panel with a name plate (hidden for the narrator) and a bobbing continue arrow.
- **Menus:** centred, themed, with Cinzel titles.
- **Title screen:** the owner's party poster as key art, with a fade, themed buttons and the version number.
- The glyph test now checks the UI fonts.
- Tests: `tests/unit/test_u01_ui.gd` (3 tests).

## U02 Companion HP – PASSED (owner request)
- Lyra 110, Nia 120, Rovan 190 HP, each with their own defence. Saved in `GameState.party_hp`, an additive save field.
- Enemies pick the nearest member who is still standing. Boss hazards hit companions too; Zotik's armour bonus is only removed for Zotik.
- K.O. at 0 HP: a death pose, no actions, ignored by enemies. The companion gets up with 30 % HP once nearby fighting stops. Every full heal (savepoint, respawn, arena) restores the party.
- Lyra heals the weakest member (Zotik or a companion).
- HUD party frames show HP and "k.o.".
- Logged as C-31. Tests: `tests/unit/test_u02_party_hp.gd` (5 tests).
- Regression: 194/194 tests plus restart checks for chapters 1–3: PASS. The golden paths still pass with vulnerable companions.

## C01 Realistic-proportion characters – PASSED (owner: "Charaktere sollen so aussehen wie sie sollen")
- **Problem:** The chibi KayKit figures read as "Animal Crossing". Replaced by the CC0 Quaternius human kit (11 MB in total):
  - base body (head only, cut above the neck)
  - modular fantasy outfits (peasant/ranger, male/female)
  - rigged hairstyles
  - Universal Animation Library: 17 animations, stored as one compressed AnimationLibrary
  - textures reduced from 4K to 1K for Android
- `CharacterRig.create_human(spec, height)` builds a figure from outfit, body, hair or beard, hair colour, outfit tint, hidden parts and weapons. Weapon meshes are borrowed from the KayKit packs. It keeps the same API as before (play/action/locomotion/attach), so gameplay code is unchanged.
- **Companions:**
  - Lyra: long blue hair, blue-tinted dress, staff
  - Nia: hair in buns, ranger outfit, crossbow
  - Rovan: beard, ranger outfit, axe and shield
- **NPCs:** all 19 styled individually (outfit, hair, colour, weapon); Finn is child-sized.
- **Zotik:** the same human rig in the ranger outfit with fur-coloured arms. The fox head (muzzle, nose, green eyes, cheek fluff, large ears), green scarf, neck fur, bushy tail, bag and the Weltenklinge sit on the bones. Positions are defined in model space and converted per bone, so they follow every animation.
- Logged as C-32. G02 tests updated to the new rig: no human head, skin uses the fur shade, Sword_Attack animation.
- Regression: 194/194 tests plus restart checks for chapters 1–3: PASS.

## G05 World detail – PASSED (owner: "die Spielwelt soll aussehen wie sie soll")
- New layout key `decor`: hand-placed CC0 models (wells, tents, barrels, crates, sacks, weapon racks, targets, flags, fences, trees, rocks, wheelbarrows, lumber). An optional thin collider (`r`) stops the player walking through them.
- Procedural decor types:
  - `lantern`: wooden pole with a warm glowing lamp
  - `path`: cobbled roads and plazas
  - `water`: the Valdoria harbour
- Decor models are validated by `Content`; the reachability test includes decor colliders.
- Areas dressed:
  - Lunaris village: main road with branches, 6 lanterns, well, tent, training corner, garden fences, trees inside the village
  - Elaris town: roads, lanterns, trees, tent, workshop props
  - Valdoria market: east–west street, market plaza, harbour water, tents and stalls
  - Guild district: street, training racks, targets
- **Horizon** (Lunaris, Valdoria): a castle far away and floating islands with trees, like the key art (3 on Android/Web, 6 on PC).
- `backdrop_skip` keeps the town ring out of the harbour.
- Regression: 194/194 tests plus restart checks: PASS.

## X01 Full playthrough – PASSED (owner: "das Spiel soll spielbar sein in deinen bisherigen Welten in voller Logik")
- New test `test_x01_full_playthrough`: the whole game in one session, with no prepared saves.
  - Title → new game → chapter 1 (Lunaris) → Weltenstein to Elaris → chapter 2 → Weltenstein to Valdoria → chapter 3 (guild, bounty, bronze arena, canals, cistern golem, Kanalwächter) → save → reset → load through the title.
  - Every chapter starts from the state the previous chapter really produced: party, items, flags and quest steps. The golden paths m15/e08/v06 start from hand-written saves; this one does not.
  - Uses each chapter's savepoint, because doing so is a quest step.
- Checks:
  - All 6 main and side quests COMPLETED.
  - Companions follow across worlds (2 in Elaris, then 3).
  - The loaded state is identical to the saved one (play_time excluded, because it keeps counting).
- No game bugs found. The two failures during writing were test-script mistakes: the savepoint step was missing, and the valve order was wrong (the solution is valves 1 and 2).
- Regression: 195/195 tests plus restart checks for chapters 1–3: PASS.

## S00/S01 Solmera hub (chapter 4) – PASSED
- Phase-4 plan `docs/PHASE_4_PLAN.md` (S00–S05), assumptions logged as C-34.
- World Solmera is unlocked by `FLAG_VAL_CHAPTER_COMPLETE`. The existing Weltenstein in Valdoria lists it; the oasis has its own stone for the way back.
- Areas:
  - Oase Qamra (hub): pond, plazas, tents, rocks, lanterns, steles, closed Dünentor
  - Basar: smithy and alchemist
- NPCs: Nuri (caravan guide), Zeyd (elder), Amani (smith), Jabir (alchemist).
- New items: Sonnenstaub, Dattelkuchen, Sonnensäbel (attack 18), Sandschleier (defense 7, +20 HP).
- Two lore steles (Karawanenwege, Kharos); one-time arrival scene.
- Desert look: CC0 Poly Haven sand floor (512 px), warm sky and fog, rock and tent backdrop.
- The Dünentor is still closed; the dunes follow in S02 (`FLAG_SOL_DUNES_OPEN` is reserved). No main quest yet.
- 6 new tests (`test_s01_solmera`), 2 new screenshots (15 oasis, 16 bazaar).
- Regression: 201/201 tests plus restart checks for chapters 1–3: PASS.

## S02 Dunes – PASSED
- Nuri opens the Dünentor (`FLAG_SOL_DUNES_OPEN`); after that the oasis exit leads to the dunes.
- Area `AREA_SOL_DUNES` (60×80): rocks, tents, Weltenanker (heals and saves), chest (2 Großer Heiltrank, 3 Sonnenstaub, 90 Lun) and a still-sealed `ruin_gate` (opens in S03 via `FLAG_SOL_RUINS_OPEN`).
- Enemies, both with break gauge, bestiary entry and Sonnenstaub drops:
  - Sandskorpion (armoured, crab model in sand colour)
  - Sandgeist (fast, imp model in sand colour)
- Sandstorm: layout key `sandstorm` makes the fog dense and warm. It is cheap, so it also runs on Android and Web.
- 4 new tests (`test_s02_dunes`), screenshot 17.
- Regression: 205/205 tests plus restart checks for chapters 1–3: PASS.
## A02 Touch usability – PASSED (owner: "auf Android noch blöd bedienbar", "irritierende Flächen", "muss per Touch steuerbar sein")
- Fewer and calmer on-screen controls:
  - Big: Angriff, Ausweichen, Springen. Small: Stark, Block, Trank.
  - Translucent at rest (60 %), brighter while pressed.
  - "Benutzen" appears only while something can be used, and pulses.
- Tap the world:
  - tap a person, chest, stone or sign to use it (a "Geh näher heran." hint if too far)
  - tap an enemy to lock on
  - swipes and stick drags are not taps (max 0.25 s, 20 px)
- Settings in the pause menu (touch mode only): size 80/100/120/140 %, opacity 35/60/85 %. Stored with the other settings.
- Stick and buttons scale from their screen corners and stay inside the screen.
- 5 new tests in `test_a01_touch` (context button, calm layout + settings, tap person, tap far, tap enemy, tap vs swipe).
- Not done: menus are still the same size. Compact HUD frames on small phones and gyro/pinch camera are open ideas.
- Regression: 211/211 tests plus restart checks for chapters 1–3: PASS.

## S03 Sunken city – PASSED
- At the end of the dunes a trigger plays a short scene and opens the stairs (`FLAG_SOL_RUINS_OPEN`); the `ruin_gate` prop disappears.
- Area `AREA_SOL_SUNKEN` (ruins, rocks, Weltenanker, chest, lore stele, 2 Sandskorpion + 2 Sandgeist) and the closed `AREA_SOL_SUN_HALL`.
- Sun-mirror puzzle `PUZ_SOL_MIRRORS_001`: four mirrors, four quarter-turn states (Nord, Ost, Süd, West), solution 1-3-0-2, three hints, then "Sonnenlicht bündeln". Reward: 80 Lun, 3 Sonnenstaub; it opens the hall (`FLAG_SOL_MIRRORS_DONE`).
  - Built on the existing "dials" puzzle kind. New optional data keys `part_prompt` and `plate_prompt` replace the hard-coded moon-gate texts.
- Miniboss Sandwächter in the Sonnenhalle (golem model, break gauge, persistent). It sets `FLAG_SOL_WAECHTER_DEFEATED`.
- 5 new tests (`test_s03_sunken_city`), screenshot 18.
- Not yet: no quest text for chapter 4; S04 adds the quests, Kharos and the Nuri arc.
- Regression: 216/216 tests plus restart checks for chapters 1–3: PASS.

## S04 Chapter-4 quests + Kharos – PASSED
- Main quest "Wo der Sand sich erinnert" (Nuri arc): arrival or talking to Nuri starts it (also for older saves), it runs through dunes, ruins and mirror puzzle to the boss and ends with `FLAG_SOL_CHAPTER_COMPLETE`.
- Side quest "Sonnenstaub für Jabir" (reward: Elixier and more).
- Boss Kharos (the sand colossus, 780 HP, break gauge) in the Sonnenhalle arena, intro scene plays once, three phases:
  - Sandfaust: circular sand slam hazard
  - Sandsturm (60 %): sand wave across the arena (sidestep it), summons 2 Sandgeister
  - Sturz des Kolosses (30 %): faster waves, summons a Sandskorpion
- Defeat sets `FLAG_BOSS_SOL_KHAROS_DEFEATED`, plays the ending scene and stays defeated after a reload.
- Desert enemies and Kharos have colours and size entries (`enemy.gd`) and creature models (`creature_visual.gd`).
- 8 new tests (`test_s04_kharos`).
- Regression: 224/224 tests plus restart checks (golden paths of chapters 1–3): PASS, run with Godot 4.7.2.

## S05 Chapter-4 regression – PASSED
- `test_s06_golden_solmera`: starts from a schema-v2 save at the end of chapter 3, loads it through the title, travels from the Valdoria Weltenstein to Solmera and plays chapter 4 with real interactions (Nuri, Jabir, dunes, ruins scene, mirror puzzle, Sandwächter, Kharos, both quests). It writes a final save.
- `restart_check.gd` also verifies that save in a new process (`golden_expected_sol.json`), next to the chapter 1–3 saves.
- `test_x01_full_playthrough` now continues into chapter 4 from the state chapter 3 really produced (new game to Kharos, all 8 quests completed, save/load through the title at the oasis bazaar).
- Regression: 225/225 tests plus restart checks for chapters 1–4: PASS (Godot 4.7.2).
- Phase 4 (Solmera) is complete.

## A03 Controls – PASSED (owner: "die Steuerung gefällt mir noch nicht … Android voll Touch ohne große Buttons … Windows auch Pfeiltasten")
- Windows / keyboard:
  - Arrow keys move, in addition to WASD.
  - The camera turns with Z / C (the arrow keys no longer double as camera keys); the mouse still works.
  - The F1 help text lists both.
- Android / touch is gesture-first (autopilot in `Player`: goals POINT, USE, FIGHT):
  - tap the ground → Zotik walks there (a marker shows the target)
  - tap a person, chest or stone → walk there and use it
  - tap an enemy → approach, lock on and attack automatically
  - double-tap → dodge
  - floating stick on the left, swipe on the right turns the camera
  - any manual input (stick) cancels the autopilot; it also gives up when the way is blocked
- The action buttons are small and translucent at the screen edge. The pause menu has "Aktionstasten" to hide them entirely (setting `touch_buttons`).
- Tests: `test_a01_touch` (18) and `test_p01_playability` (arrow and Z/C bindings, help text).
- Not tested on a real phone yet, only in headless tests and a rendered screenshot (14).
- Regression: 232/232 tests plus restart checks for chapters 1–4: PASS (run locally on Windows with Godot 4.7).

## Q00/Q01 Aqualis hub (chapter 5) – PASSED
- Phase-5 plan `docs/PHASE_5_PLAN.md` (Q00–Q05), assumptions logged as C-35.
- World Aqualis ("Die Stadt unter dem Meer") unlocks with `FLAG_SOL_CHAPTER_COMPLETE`. The Weltenstein in the Solmera oasis lists it; the dome city has its own stone for the way back.
- Areas:
  - Kuppelstadt (hub): pond, plazas, lanterns, coral-rock stand-ins, two lore steles, a closed Korallentor (`FLAG_AQU_CAVES_OPEN`, opens in Q02)
  - Hafendock: smithy and alchemist
- NPCs: Mirael (engineer and guide), Oriel (archivist), Doran (smith), Perla (alchemist).
- New items: Perle, Algenwickel, Dreizack (attack 22), Korallenpanzer (defense 9, +25 HP).
- Underwater look: teal sky, dense fog (world style key `fog_density`, new and optional), blue buildings.
- No chapter-5 quest yet; Q04 adds it.
- 6 new tests (`test_q01_aqualis`), screenshots 20 (dome) and 21 (harbour).
- Regression: 238/238 tests plus restart checks for chapters 1–4: PASS.

## Q02 Coral caves – PASSED
- Mirael opens the Korallentor (`FLAG_AQU_CAVES_OPEN`); after that the dome city exit leads into the caves.
- Area `AREA_AQU_CAVES` (60×80): coral-rock stand-ins, Weltenanker (heals and saves), chest (2 Großer Heiltrank, 3 Perlen, 100 Lun) and a still-sealed `reef_gate` (opens in Q03 via `FLAG_AQU_ARCHIVE_OPEN`).
- Enemies, both with break gauge, bestiary entry and Perlen drops: Riffkrabbe (crab model, coral red) and Leuchtqualle (slime model, glowing blue).
- Drifting current: layout key `current` makes the water thick and dark teal. It is only fog, so it is cheap on Android and Web.
- 4 new tests (`test_q02_caves`), screenshot 22.
- Regression: 242/242 tests plus restart checks for chapters 1–4: PASS.

## Q03 Weltenarchiv – PASSED
- At the end of the caves a trigger plays a short scene and opens the stairs (`FLAG_AQU_ARCHIVE_OPEN`); the `reef_gate` prop disappears.
- Areas `AREA_AQU_ARCHIVE` (anchor, chest, lore stele, 2 Riffkrabben, 2 Leuchtquallen) and the closed `AREA_AQU_VAULT`.
- Current puzzle `PUZ_AQU_CURRENTS_001`: reuses the "valves" kind, four valves that each flip two neighbouring currents (solution: valves 1 and 3), three hints. Reward 90 Lun and 3 Perlen; it opens the vault (`FLAG_AQU_CURRENT_DONE`). The content validator proves it solvable.
- Miniboss Archivwächter in the vault (golem model, break gauge, persistent), sets `FLAG_AQU_WAECHTER_DEFEATED`.
- 5 new tests (`test_q03_archive`), screenshot 23. No chapter-5 quest yet; Q04 adds it.

## W01 Web and Android weight + app icon – PASSED (owner: "Zotik im Web total am Hängen", "App-Icon, beim Laden nur diese komische Godot-Seite")
- Measured on the published build (downloaded and served locally, rendered with a software GL in a headless Chromium):
  - The title screen is static; at a small window it runs at 60 fps, so the slowness there is the software renderer's fill rate, not game logic.
  - Browsers receive about 47 MB on the first load (10 MB wasm + 37 MB game data, gzip by GitHub Pages).
  - Real-device performance could not be measured here.
- Download weight:
  - The five KayKit adventurer models (about 18 MB) were only used to borrow weapon meshes, and every character with a weapon instantiated a whole 3.6 MB scene for it.
  - New `tools/bake_weapon_meshes.gd` extracts the five weapons into 12–31 KB files under `assets/characters/weapons/`. `CharacterRig` and `ZotikVisual` load those.
  - The `*.glb` models stay in the repo as sources but are excluded from all four exports.
  - The whole regression passes with the models removed.
- Rendering on browser and Android only (PC unchanged):
  - no 4× MSAA
  - shadow map 2048, light soft-shadow filter, one shadow split instead of four
  - no full-screen glow and no colour-adjustment pass
- Icon and loading screen:
  - project icon, Windows `.ico` and Android launcher icons (main and adaptive) use the owner's cover image (Zotik logo with the party; source `reference/derived/ZOTIK_COVER_640.jpg`, from the owner's site)
  - the Android adaptive icon is the cover on a blurred copy of itself, so the logo stays inside the round mask
  - the loading screen uses the title art
  - the web build has its own loading page (`web/zotik_shell.html`, set as `html/custom_html_shell`): title art, gold progress bar with percent and MB, German texts and error messages, fade into the game. It keeps Godot's placeholders and was checked in a headless browser with the placeholders filled in as Godot does; the real export is checked after the merge on the Pages site.
  - concept art, not final (CLAUDE.md rule 6)
- New test `test_web_and_mobile_stay_light` keeps these settings.
- To verify: after the merge, open https://ricorewioriginal-collab.github.io/zotik/ again (the Pages job runs on `main` only).
- Regression: 248/248 tests plus restart checks for chapters 1–4: PASS.

## U03 – Help tile and menu rows (owner request)
- Owner: the keyboard hints at the top left are annoying; a simple gear tile with settings would be easier, and the menu entries looked bad.
- The permanent hint text is gone. A small gear tile sits top left under the party frames (also in touch mode, where the icon bar moves right of it). It opens the former pause menu, now "Hilfe & Einstellungen": controls overview (keyboard or touch, depending on the mode), settings, title/quit. Esc and F1 open the same panel; the bottom bar keeps Inventar / Quests / Bestiarium.
- Menu rows (all `MenuPanel` menus): dark rounded plates with the text left and gold-rimmed rounded buttons right; headings and notes for grouping; a gold "Schließen" button.
- Tests adapted (p01, a01, u01); the `show_controls` setting is no longer used by the HUD.
- Screenshot `04c_help_and_settings` added to `tests/screenshots.gd`.

## U03 (cont.) – names, Enter, in-game guide
- Name tags (`NameTag`): smaller, UI font, soft dark outline, colour by role (gold people, blue companions, red enemies), only visible within ~13–16 m. Enemy tag is two lines (name / HP).
- Enter (and keypad Enter) now also use/talk next to E; the prompt reads "[Enter]". Touch: tapping a person already walks up and talks.
- "Spielanleitung" (`GuideMenu`): opened from the help panel (gear); story, movement, talking, combat, quests, puzzles, saving, inventory, party, tips when stuck.

## C02 – Colour grading (PC, optional) and boot splash fix
- Live check of the Pages site after #16/#17: new loading page shows (progress text, hand-over to the title screen), pck 32.9 MB (was 36.6 MB).
- Boot splash bug: Godot only accepts PNG for `boot_splash/image`; the JPG was ignored and the default Godot splash showed on desktop/Android. Now `assets/ui/boot_splash.png` (the web page is unaffected).
- Rytelier "Color Grading" (MIT): runtime part in `compositor/` (no editor plugin), `core/color_grade.gd`. Works only with RenderingDevice (Forward+/Mobile), so PC only; setting `color_grading`, default OFF, switch in the help panel (shown only where available). Could not be run here (no GPU, headless/Compatibility) – the owner's local session must try it on a PC: switch on, check the look, switch off.
- Vertex Studio: not integrated (editor tool, licence; owner may install locally).

## Q04 + Q05 – Chapter-5 quests, Neryx, regression – PASSED
- Main quest `QUEST_MAIN_AQU_001` "Die Stadt unter dem Meer": Mirael → Weltenarchiv → current puzzle → Archivwächter → Neryx → report to Mirael (reward 450 Lun, `FLAG_AQU_CHAPTER_COMPLETE`). Started by the arrival scene; Mirael also starts it for older saves.
- Side quest `QUEST_SIDE_AQU_001` "Perlen für Perla": 5 pearls to Perla (220 Lun + Elixier).
- New area `AREA_AQU_ABYSS` behind the vault (gated by `FLAG_AQU_WAECHTER_DEFEATED`), boss `BOSS_NERYX_001`: 860 HP, three phases (Strömung → Strudel with 2 Leuchtquallen → Tiefendruck with a Riffkrabbe); the whirlpool/pressure hazards reuse the existing circle and surge kinds (ground circle, travelling surge), intro and defeat scenes, persistent defeat, bestiary entry. Placeholder look (golem model, concept art not final).
- Tests: `test_q04_neryx` (8), `test_q05_golden_aqualis` (golden path from a chapter-4 save plus restart check `golden_expected_aqu.json`), `test_x01_full_playthrough` now plays chapters 1–5 and saves/loads at the end.
- Screenshot 24 (Neryx arena).

## U04 – Character creator in the new UI style
- "Mein Zotik": title font, row plates and gold buttons like the menus, navy preview background instead of grey. Live check of the Pages build after #18: starts, Neryx data in the pck, game loads (software renderer, frame rate not representative).

## R01 – Atmosphere (Phase 6)
- Lunaris is now a night world: sky shader `assets/shaders/night_sky.gdshader` (gradient, twinkling stars, big moon with halo, soft aurora; no textures, works in the compatibility renderer), cool moonlit ground tint and path tint, moonlight sun.
- `Look.build_flora`: tufts of grass (7 bent blades each) and glowing flowers as two MultiMeshes per area (Lunaris, Elaris, Valdoria, Solmera); fewer on web/Android; keeps roads, houses, water and exits free.
- Lantern lamps are brighter and carry a warm OmniLight on PC (not on web/Android).
- Placeholder/procedural art, not final.

## R04 (early) – Quaternius Stylized Nature models
- 40 CC0 models (trees, pines, bushes, rocks, grass, flowers, mushrooms, pebbles) in `assets/world/nature`; `Look.model()` falls back to this folder, `_place_h` scales to a height in metres.
- Used for: placed "tree" props, the tree rows beyond the border (Lunaris, Elaris), and the flora scatter (grass, flowers, mushrooms as MultiMeshes; thinner on web/Android).
- Source via itch.io download page (free, CC0); textures 512 px keep the build small.
