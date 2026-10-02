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
