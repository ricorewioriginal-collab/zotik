# Phase-1 Acceptance Matrix (docs/08_ACCEPTANCE_TESTS.md)

All tests are executed headless with Godot 4.7-stable: `GODOT=<godot 4.7> tools/run_regression.sh`.
CI runs the same command on every PR update.
Last local run on 2026-10-02 (v0.4.0): **171/171 tests passed + restart check PASS for chapters 1, 2 and 3**.

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

# Phase 2 – Elaris acceptance

Last local run on 2026-10-02: **140/140 tests + restart checks PASS for both chapters.**

## Chapter-2 golden path
`tests/unit/test_e08_golden_elaris.gd` starts from a real **schema-v1 Phase-1 save** (end of chapter 1) and plays through real interactions. Its final save is verified in a **separate process** by `tests/restart_check.gd`, alongside the chapter-1 golden path.

| Step | Covered |
|---|---|
| Load the Phase-1 save via the title (v1 → v2 migration) | title button, migrated party |
| Weltenstein → Weltkarte → Elaris | travel point, world map, arrival scene, Lyra joins, chapter-2 quest starts |
| Mara → Nia joins → Sela's side quest | NPC dialogues, quest step effects |
| Living forest: 3 Pilzlinge, chest, ride the moving path, Rovan joins | melee with light/strong attacks, platform physics |
| Turm der Erinnerung: wrong start resets, Mond → Blatt → Kristall → Flamme | symbol pillars, spec epilogue |
| Heart of the forest: chest, Weltenanker save, Wurzelkriecher | savepoint save menu, miniboss gate |
| Wurzelkönigin: intro, 3-phase fight, memory vision, return to town | boss, travel effect |
| Report to Mara, hand in spores | chapter complete, side quest complete |
| Save → new process → load → identical state | restart check (`golden_expected_ela.json`) |

## Phase-2 systems
| System | Tests |
|---|---|
| World travel, unlocks, cross-world beacon | `test_e01_travel` |
| Save schema v2 + v1 migration | `test_e01_travel::test_v1_save_migrates_to_v2`, chapter-2 golden path |
| Party AI (follow, formation, ranged/melee, heal, passive in dialogue, persistence) | `test_e02_party`, `test_e04_elaris::test_rovan_fights_in_melee` |
| Break (light/strong/party, stun window, interrupts, exactly-once signals) | `test_e03_break` |
| Elaris areas, moving paths, gates, shop, miniboss | `test_e04_elaris`, `test_p02_reachability` |
| ELARIS_TURM_01 per spec | `test_e05_tower` |
| Chapter-2 quests + side quest | `test_e06_quests` |
| Wurzelkönigin incl. root eruptions | `test_e07_queen` |

## Open (Phase 2)
- All art and audio are placeholders. Dialogue is placeholder except the spec epilogue of the tower.
- Story assumptions C-15 to C-19 need owner review: Phase-2 scope, when Nia and Rovan join, NPC roles.

## Chapter-3 golden path
`tests/unit/test_v06_golden_valdoria.gd` starts from a schema-v2 save at the end of chapter 2 (party: Lyra, Nia, Rovan) and plays through real interactions. Its final save is verified in a **separate process** by `tests/restart_check.gd`, alongside chapters 1 and 2 (`golden_expected_val.json`).

| Step | Covered |
|---|---|
| Load the chapter-2 save via the title | party restored |
| Weltenstein → Weltkarte → Valdoria | arrival scene, chapter-3 quest starts |
| Market: Lotte's side quest, one casino spin | NPC quest start, casino entrance + virtual Lun |
| Guild: Veyr, accept a bounty | quest step, bounty board |
| Arena: Kasimir → Bronze (2 waves) | arena menu, waves, first-clear reward |
| Canal gate: Tibor opens the gate | quest-gated dialogue |
| Canals: Krabbe + Schleim, chest, Weltenanker save, valves (a turn undone, then solved) | savepoint save menu, valve puzzle |
| Cistern: Rostgolem | miniboss gate, scrap for Lotte |
| Schleusenkammer: intro, Kanalwächter, defeat scene → canal gate | boss, travel effect |
| Lotte, Veyr | side quest and chapter complete, bestiary entry |
| Save → new process → load → identical state | restart check |

## Phase-3 systems
| System | Tests |
|---|---|
| Valdoria districts, library, armour slot | `test_v01_valdoria` |
| Guild bounties + bestiary | `test_v02_guild` |
| Arena waves, safe defeat, abort on leaving; casino (virtual Lun, odds, family toggle) | `test_v03_arena_casino` |
| Forgotten canals, valve puzzle + validator, Rostgolem | `test_v04_canals`, `test_p02_reachability` |
| Chapter-3 quests, Kanalwächter phases, water surge + hazard validator | `test_v05_chapter3` |
| Companion formation keeps the camera line free | `test_e02_party::test_companions_spread_into_formation` (behind Zotik, no overlap) |

## Open (Phase 3)
- All art and audio are placeholders; all chapter-3 dialogue is placeholder.
- Assumptions C-20 to C-28 need owner review.
- No human playtest of chapter 3 yet; boss and arena tuning is a first pass.
