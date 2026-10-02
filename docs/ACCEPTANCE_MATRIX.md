# Phase-1 Acceptance Matrix (docs/08_ACCEPTANCE_TESTS.md)

All tests are executed headless with Godot 4.7-stable: `GODOT=<godot 4.7> tools/run_regression.sh`.
CI runs the same command on every PR update.
Last local run on 2026-10-02: **92/92 tests passed + restart check PASS**.

## Critical golden path
`tests/unit/test_m15_golden_path.gd` plays the whole path through real interactions: dialogues, melee hits, puzzle parts, exits, savepoint and pedestal.
`tests/restart_check.gd` then runs in a **separate Godot process**.

| Golden path step | Covered |
|---|---|
| New Game → customize Zotik | title button → creator `change()` → `confirm()` |
| Lunaris → Mira → Toren → training | exits, `Npc.interact`, dummy defeated by attacks |
| forest → combat → chest | 3 Risslinge defeated, `CHEST_LUN_001/002` opened |
| Moon Gate wrong / reset / correct | wrong submit rejected, reset, correct solve |
| dungeon → Resonance Bridge → savepoint | crystals in order, Mondwolf, Weltenanker save (slot 2) |
| Orun → rift → Weltenklinge → return | intro trigger, 3-phase fight, pedestal, vision, travel home |
| quest completion → Professorium/Lyra hook | Mira → Professorium → Lyra scene, `QUEST_MAIN_LUN_001` COMPLETED |
| save → exit → restart → load → identical persistent state | save slot 1, process ends, new process loads via the title and compares the full `GameState` (play time must continue from the saved value) |

## Regression items
| Item | Tests |
|---|---|
| Multiple slots | `test_m02_save::test_slots_are_independent`, `test_m11_dungeon::test_weltenanker_heals_saves_and_progresses_quest` |
| Corrupt-save backup | `test_m02_save::test_corrupt_save_recovers_from_backup`, `test_tampered_save_is_detected`, `test_newer_schema_rejected` |
| Death before / during boss | `test_m08_combat::test_death_resets_encounter_and_keeps_progress`, `test_m12_boss::test_death_during_boss_resets_fight` |
| Puzzle partial-save reload | `test_m10_puzzles::test_partial_state_survives_save_load` |
| Opened chests | `test_m07_inventory_shop::test_chest_opens_once_and_persists` |
| Shop currency | `test_m07_inventory_shop::test_buy_rules`, `test_sell_rules`, `test_boro_dialogue_opens_shop_and_locks_control` |
| Unique-item idempotency | `test_m06_dialogue::test_unique_effect_is_idempotent`, `test_m13_story_end::test_blade_cannot_be_duplicated_after_reload` |
| Settings persistence | `test_m02_save::test_settings_persist` |
| Customization persistence | `test_m04_player::test_customization_applies_and_persists`, golden path + restart check |
| Content cross-references | `test_m03_content` (7 tests incl. negative tests) |
| Quest progression cannot be forced by UI | `test_m09_quests::test_quests_start_once_and_have_no_force_api`, `test_hud_objective_and_quest_log` |

## Visual check
`tests/screenshots.gd` (needs a display, e.g. `xvfb-run`) renders `docs/screenshots/`. The 2026-10-02 render showed and fixed:
- an unreadable HP bar
- a creator preview that faced away from the camera
- invisible area boundaries
- 3D name labels too small to read

## Not covered / open (honest status)
- **Windows build**: no `export_presets.cfg` and no export templates in this environment. Phase-1 export was **not executed**. Next step: add a Windows preset and run `--export-release` with templates.
- **Art**: every visual is a labelled PLACEHOLDER (see `docs/ASSET_GAPS.md`). There is no audio.
- **Dialogue**: all text is placeholder (C-10). The final story text must come from the project owner.
- **Manual play-feel tuning** (camera, combat timing) was only checked by automated tests and screenshots, not by a human playtest.
