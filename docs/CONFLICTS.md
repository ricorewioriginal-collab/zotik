# Open Conflicts / Questions

Format: ID – description – status / interim handling. Interim handling is the least destructive option and can be changed by the project owner.

- C-01 – Exact canonical heights remain intentionally unfrozen; use relative scale until in-engine camera/collision testing. – OPEN
- C-02 – Legacy `BUILD_01.md` and the new focused vertical slice differ in encounter order and breadth. New Phase-1 order wins; legacy systems/content are preserved for later integration. – RESOLVED (by spec)
- C-03 – The exact implementation status of Timeline/Break and other starter systems must be determined by M00, not assumed from documentation. – RESOLVED by M00: prototypes only, with defects (see `PHASE_1_AUDIT.md` §2.3).
- C-04 – Engine version: `CLAUDE.md`/`mcp/project_manifest.json` target Godot 4.7; legacy `README.md`, `PROJECT_MANIFEST.json` and `ARCHITECTURE.md` say "Godot 4.x"; starter declares 4.3. – Interim: Godot 4.7 (highest precedence document).
- C-05 – Art direction: `11_ASSETS/ASSET_POLICY.md` asks for low-poly, small textures, optional 4:3, 1990s retro feel; `docs/09_ART_STYLE_BIBLE.md` asks for stylized PBR, scalable Windows/Android/Web. – Interim: `docs/09` wins (spec precedence). Low texture budgets from the asset policy are kept as performance guidance. Owner decision requested.
- C-06 – Renderer: starter uses `gl_compatibility`; stylized PBR target would favour Forward+ on Windows, Compatibility is required for Web. – Interim: keep `gl_compatibility` for Phase 1 (runs on all target platforms and headless CI); revisit with real assets.
- C-07 – Legacy input: README says dodge = F/F12, project binds F/Right-arrow; block additionally bound to Shift. – Interim: new project uses F + gamepad for dodge; Right-arrow binding dropped.
- C-08 – Legacy item IDs (`healing_potion`, `moon_pendant`, `moonblade`, `rift_shard`) are outside the canonical namespaces of `docs/03_CONTENT_DATA_SPEC.md`. – Interim: migrate to `ITEM_HEALING_POTION_001`, `ITEM_MOON_PENDANT_001`, `WEAPON_MOONBLADE_001`, `ITEM_RIFT_SHARD_001`; legacy file left unchanged.
- C-09 – Location of the Phase-1 project is not specified. – Interim: new project `game/zotik/`; `game/legacy_starter/` stays read-only.
- C-10 – Story-critical final dialogue is a separate artifact that must not be invented (`10_CLAUDE/CLAUDE_MASTER_PROMPT.md`), but Phase 1 needs playable dialogue. – Interim: dialogue lines are stored as data with `placeholder: true` and paraphrase only facts from `docs/04_LUNARIS_CONTENT_BIBLE.md`; final text to be delivered by the owner.
- C-11 – Unique reward: legacy Build 01 grants "Mondklinge" in the dungeon; Phase 1 grants `WEAPON_WORLD_BLADE_001` (Weltenklinge) after Orun. – Interim: Weltenklinge is the Phase-1 unique reward; Mondklinge kept as a regular shop/chest weapon.
