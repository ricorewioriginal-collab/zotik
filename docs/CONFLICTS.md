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
- C-12 – `docs/03` lists the namespaces QUEST_ … FLAG_. Phase-1 content also needs areas, shops, savepoints and characters. `docs/07` already uses SAVEPOINT_ and CHAR_. – Interim: additional namespaces `AREA_`, `SHOP_`, `SAVEPOINT_`, `CHAR_`; the registry validates them like the others.
- C-13 – Toren, Boro, Elwen, Finn and Sari have no `NPC_` IDs in `docs/07`. – Interim: `NPC_<NAME>_001`.
- C-14 – Puzzle solutions (Moon Gate phases full/new/waning, Resonance Bridge order) are not specified. – Interim: defined in `data/puzzles.json` and hinted by Elwen's lore line; owner may change the data without code changes.
- C-15 – No Phase-2 specification exists. – Interim: Phase 2 = chapter 2 Elaris plus the party and Break systems (`docs/PHASE_2_PLAN.md`). Owner review requested.
- C-16 – `20_RIDDLES` demo dialogue in the Elaris tower features Nia and Rovan, but no document says when they join. – Interim: Nia (young archer) joins in Elaris town and Rovan (former guardian) joins in the living forest. Both are placeholders until the story owner confirms.
- C-17 – Combat doc lists MP, magic, elements and timeline. – Interim for Phase 2: Break and party AI only; elements, MP and timeline stay deferred.
- C-18 – The legacy village attack (BUILD_01) remains deferred; not part of chapter 2.
- C-19 – Elaris NPC roles are not specified. – Interim: Mara (research quarter), Elio (craftsman/shop) and Sela (townsperson) reuse names from the legacy NPC list. All dialogue is placeholder.
- C-20 – `04_WORLDS` lists a casino in Valdoria. The addendum forbids real-money casinos, and the Phase-1 master design deferred the casino. – Interim: the casino is deferred, and Valdoria shows a closed casino building.
- C-21 – Valdoria NPC roles are not specified. – Interim: names come from the legacy NPC list where possible (Veyr, Elio is already used) plus clearly marked placeholder roles. All dialogue is placeholder.
- C-22 – `06_SYSTEMS` lists armour and headgear slots, but `docs/03` has no armour namespace. – Interim: added `ARMOR_` (slot `armor`) for Valdoria's smithy. Headgear is still deferred.
