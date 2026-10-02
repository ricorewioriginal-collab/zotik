# Phase 3 – Valdoria: "Die Stadt, die niemals schläft"

Standing approval from the project owner (2026-10-02). There is no dedicated specification. This plan is derived from:
- `01_MASTER` (chapter 3 = Valdoria)
- `04_WORLDS`: large hub with market, smithy, alchemist, monster hunter guild, library, casino, arena, harbour, apartments and canals; dungeon "Die vergessenen Kanäle"; boss "Kanalwächter"
- `05_GAMEPLAY`: bestiary fields, puzzle type "Wasser", dungeon pattern
- `06_SYSTEMS`: Lun, shops

Assumptions are logged from C-20 in `docs/CONFLICTS.md`.

## Goal
Playable chapter 3 reachable from a chapter-2 save:
1. Travel to Valdoria and explore the districts.
2. Take bounties at the guild, fill the bestiary, fight arena waves.
3. Drain the forgotten canals with a valve puzzle.
4. Defeat the Kanalwächter and return.

## Milestones
| ID | Milestone | Acceptance (summary) |
|---|---|---|
| V00 | Plan | this document, conflicts logged |
| V01 | Valdoria hub | districts (Markt & Hafen, Gildenviertel & Bibliothek, Kanaltor), NPCs, smithy/alchemist shops, readable library books, world unlocked by chapter 2 |
| V02 | Guild bounties + bestiary | data-driven bounties (defeat N × enemy) with rewards; bestiary records every enemy (name, region, drops, description, kills); bestiary UI |
| V03 | Arena | data-driven wave battles with rewards, safe defeat (no game over), rematch |
| V04 | Forgotten canals | dungeon areas, valve puzzle (water channels block paths until drained), canal enemies, miniboss |
| V05 | Chapter-3 quests + boss Kanalwächter | main quest, side quest, multi-phase boss with water surge hazard |
| V06 | Chapter-3 regression | golden path from a chapter-2 save + restart check for all chapters |

Casino delivered in V03 (C-20 resolved). Deferred: apartments/housing, harbour travel (Nautilux arrives in Solmera), crafting (Ignara).
