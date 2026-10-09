# ZOTIK – Claude Handoff 1.0

PROJECT: ZOTIK – Die Splitter der Welten
ENGINE TARGET: Godot 4.7
CURRENT PHASE: Phase 4 – Solmera (owner request 2026-10-03, see docs/PHASE_4_PLAN.md)
CURRENT MILESTONE: PHASE_4_COMPLETE (next: Phase 5 plan)
STATUS: Phase 1 PASSED (M00–M15); Phase 2 PASSED (E00–E08); Phase 3 PASSED (V00–V06); Graphics pass PASSED (G01–G05, A01, U01, U02, C01); Phase 4 PASSED (S00–S05)

## Mandatory workflow
1. Audit before implementation. Do not rebuild from scratch.
2. Preserve working code unless it conflicts with the current master specification.
3. Work on exactly one milestone at a time. Do not automatically begin the next milestone.
4. Never report a test as passed unless it was actually executed.
5. Final art and gameplay are parallel tracks. Approved placeholders may unblock gameplay.
6. Never report placeholder/concept art as final production art.
7. Log specification conflicts in `docs/CONFLICTS.md` instead of silently inventing a resolution.
8. Phase 2 is not authorized by completion of Phase 1; explicit project-owner approval is required.
   Update 2026-10-02: the project owner granted standing approval to continue with further phases without asking ("Mache weiter, auch ohne meine Freigabe in Zukunft"). Each phase still gets a written plan, logged assumptions and full regression.

## Canonical player character
Zotik is NOT human. Zotik is an anthropomorphic orange fantasy creature with fox/feline-like visual traits, upright humanoid posture, large pointed ears, green eyes, light muzzle/chest fur, a large expressive bushy tail and modular adventurer clothing. The approved Zotik master sheet in `reference/approved/` is the primary visual reference.

## Canonical Lyra / Mira decision
Lyra and Mira are separate characters.
- **Mira** is a Lunaris resident and early-story NPC: emotionally close to Zotik, knowledgeable about local moon/rift lore, and deliberately withholds part of what she knows. She is important to Lunaris but is NOT a replacement for Lyra.
- **Lyra** remains the permanent main-party researcher/mage from the legacy master story. Her family connection to Weltenkern research and her long-form relationship arc with Zotik remain canon.
- Phase 1 introduces Mira early. Lyra appears at/after the climax as the bridge into the wider journey. Do not merge, rename, or overwrite either character.

## Specification precedence
1. `CLAUDE.md`
2. `docs/02_DEVELOPMENT_CONTRACT.md`
3. `docs/06_IMPLEMENTATION_ORDER.md`
4. `docs/00_MASTER_DESIGN.md`
5. `docs/01_LUNARIS_VERTICAL_SLICE.md`
6. `docs/03_CONTENT_DATA_SPEC.md`
7. `docs/04_LUNARIS_CONTENT_BIBLE.md`
8. `docs/05_ASSET_SCENE_MANIFEST.md`
9. legacy documents retained in numbered folders

## First assignment: M00 only
Do not implement gameplay yet. Audit `game/legacy_starter/` and the full repository. Produce `docs/PHASE_1_AUDIT.md` with: project validity, actual Godot version, scenes, scripts, autoloads, input map, saves, player, combat, quests, dialogue, puzzles, assets, tests, build errors, reusable systems, conflicts and recommended migration actions. STOP after the audit.
