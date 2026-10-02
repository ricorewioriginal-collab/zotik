# ZOTIK – Claude Code Handoff

## Mandatory starting point
1. Read `CLAUDE.md` completely.
2. Read the current milestone/status files.
3. Perform **M00 Repository Audit only**.
4. Do not implement M01 or later milestones until M00 is reviewed and explicitly released.
5. Preserve working code and existing specifications. Do not rebuild the project from scratch.

## Canonical visual rule
Zotik is **not human**. Zotik is the orange anthropomorphic fantasy creature defined by the approved master references: upright humanoid posture, large pointed ears, green eyes, light muzzle/chest fur, large expressive tail and modular adventurer clothing.

The large generated boards under `reference/approved/production_2026-09-26/` are art-direction/production references. Numerical labels in generated imagery (sizes, polygon counts, camera distances, etc.) are not authoritative unless separately confirmed in a text specification and tested.

## M00 deliverables
Create/update:
- `docs/PHASE_1_AUDIT.md`
- `docs/CONFLICTS.md`
- `docs/ASSET_GAPS.md`
- `mcp/project_manifest.json`
- `mcp/asset_index.json`
- `mcp/test_results.json`

Audit Godot files, scenes, scripts, autoloads, input actions, save code, gameplay systems, documentation, assets/references and tests.

Set M00 to PASSED only when the repository state is reproducibly documented. Then **STOP**.
