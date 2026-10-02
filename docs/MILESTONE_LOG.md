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
