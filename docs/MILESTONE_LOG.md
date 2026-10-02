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
