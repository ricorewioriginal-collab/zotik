# Phase 6 – Visual modernisation and more chapters (owner request 2026-10-10)

Owner: "modernisiere das spiel nach github vorlage, optik muss erweitert werden, echte 3d welten, echte schöne charaktere … erweitere dann die kapitel".
The "Vorlage" is the concept art in `reference/concept_2026-10-02/` and `19_VISUAL_REFERENCES/` (night Lunaris with a huge moon and floating islands, glowing flora, painted look, expressive fox hero).

## What this environment can and cannot do (honest scope)
- Can: procedural sky/atmosphere, lighting, particles, shaders, scattered flora (MultiMesh), free CC0 model packs that can be downloaded, full code/data content, tests, screenshots through a software renderer.
- Cannot: hand-modelled, hand-textured hero characters or concept-art-quality worlds. Zotik, Lyra etc. stay a modular placeholder rig (Quaternius CC0 base + fox head/tail) with better shading until real models exist (owner/artist, or an image-to-3D tool with a usable licence – earlier tests were not usable, C-33).
- Web/Android stay light: everything new has a cheaper `low_end()` variant.

## Milestones
| ID | Content |
|---|---|
| R01 | Atmosphere: night sky shader with moon, stars and aurora for Lunaris; moonlit ground tint; grass tufts and glowing flowers; lantern lights (PC) |
| R02 | Light and colour per world (Elaris golden light, Valdoria dusk, Solmera heat haze, Aqualis caustics), fireflies/particles, flora for every outdoor world |
| R03 | Character look: rim light + outline shader on people/enemies, richer hair/outfit variety, stronger tail/fur read |
| R04 | Props and water: more CC0 models where the licence allows, animated water/waterfalls |
| R05 | Chapter 6 (Frosthain / Kryothorn): world, areas, quests, boss, tests |
| R06+ | Further chapters from `04_WORLDS/WORLDS_MASTER.md` (Ignara, Noctaris, Astralis), each with full regression |

Rules: one milestone at a time, screenshots as evidence, full regression before every merge, placeholder art is never reported as final (CLAUDE.md rule 6).
