# Phase 2 – Elaris: "Der Wald, der sich erinnert"

Authorised by the project owner on 2026-10-02 ("Phase 2 bitte").
There is no dedicated Phase-2 specification. This plan derives Phase 2 from:
- `01_MASTER` (chapter 2 = Elaris)
- `04_WORLDS` (living forest, city, research quarter, craftsmen, moving paths; dungeon "Der lebende Wald"; boss "Wurzelkönigin")
- `05_GAMEPLAY` (Break, party, regional monsters Dornenwolf / Pilzling / Wurzelkriecher)
- `20_RIDDLES` (binding demo puzzle ELARIS_TURM_01)
- `03_CHARACTERS` / `09_DIALOGUE` (Lyra permanent, Nia, Rovan)

Assumptions are logged as conflicts C-15 and later in `docs/CONFLICTS.md`.

## Goal
Playable chapter 2:
1. After Lunaris, travel to Elaris.
2. Lyra fights at Zotik's side.
3. Explore the city and the living forest, with Break-based combat.
4. Solve the Turm der Erinnerung.
5. Defeat the Wurzelkönigin, return and save.

All of this must be reachable from a Phase-1 save, including saves created before Phase 2.

## Milestones (same rules as Phase 1: one at a time, tested, documented)
| ID | Milestone | Acceptance (summary) |
|---|---|---|
| E00 | Phase-2 plan & audit | this document, conflicts logged |
| E01 | World travel + save schema v2 | Lunaris → Elaris travel unlocked by chapter flag; v1 saves migrate (party, chapter); world map overlay |
| E02 | Party foundation (Lyra) | Lyra follows, fights at range, heals when Zotik is low, cannot block progress, persists |
| E03 | Break system | Break gauge per enemy; strong attack and party hits reduce it; full break → stun window with bonus damage; telegraphs interruptible |
| E04 | Elaris greybox & content | city, research quarter, craftsmen, living forest with moving paths, tower, dungeon, arena; NPCs, enemies, shop — validated data |
| E05 | Puzzles | ELARIS_TURM_01 (Mond → Blatt → Kristall → Flamme, RESET_FAILURE) + moving-path switch puzzle |
| E06 | Chapter-2 quests | main quest QUEST_MAIN_ELA_001, one side quest, party joins (Nia, Rovan per C-16) |
| E07 | Boss Wurzelkönigin | multi-phase boss using Break, root summons, arena hazards |
| E08 | Chapter-2 regression | golden path Elaris + restart check + Phase-1 regression unchanged |

Still deferred, not Phase 2: online/co-op, housing, marketplace, casino, events, crafting/forge (Ignara), Weltenradio, Nautilux.
