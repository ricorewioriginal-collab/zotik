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
