# Third-party assets

| Path | Source | License |
|---|---|---|
| `assets/textures/*` | Poly Haven (polyhaven.com): leafy_grass, forrest_ground_01, cobblestone_floor_01, castle_brick_07, painted_plaster_wall, wood_planks, rock_wall_08, bark_brown_02, roof_tiles_14. Downscaled to 512 px. | CC0 |

All other visuals are generated in code (placeholders or procedural shapes).
| `assets/characters/kaykit/*` | KayKit Adventurers Character Pack 1.0 by Kay Lousberg (kaylousberg.com), rigged and animated | CC0 (see `LICENSE.txt` there) |
| `assets/world/kaykit/*` | KayKit Medieval Hexagon Pack 1.0 by Kay Lousberg (kaylousberg.com): buildings, trees, props (curated subset) | CC0 (see `LICENSE.txt` there) |
| `assets/fonts/Cinzel.ttf`, `assets/fonts/Exo2.ttf` | Google Fonts (Cinzel, Exo 2) | SIL Open Font License 1.1 (see `OFL_*.txt`) |
| `assets/ui/title_bg.jpg`, `assets/ui/portraits/*` | Cut from the owner's party poster (`reference/concept_2026-10-02/20_party_poster.jpg`) | Owner's own concept art – interim UI art, not approved final art |
| `assets/characters/quaternius/*` | Quaternius: Universal Base Characters [Standard], Modular Character Outfits – Fantasy [Standard], Universal Animation Library [Standard] (quaternius.com / itch.io; textures downscaled to 1024 px; animations extracted into `ual_anims.res`) | CC0 |
| `assets/characters/custom/*` | Test/placeholder meshes and crops generated with TRELLIS (MIT, `trellis-community/TRELLIS`) from the owner's approved Zotik master sheet (`reference/approved/ZOTIK_MASTER_CHARACTER_SHEET_1.0.png`; front crop tracked at `reference/derived/ZOTIK_FRONT_CROP.png`). Not integrated, excluded from exports | Owner's own character design. TRELLIS code/model is MIT, but the GLB export (texture baking, nvdiffrast / diff-gaussian-rasterization in `to_glb`) is reported as non-commercial (microsoft/TRELLIS issue 41): treat the generated GLBs as **non-commercial / unverified, NOT cleared for release**. Generator: Space `trellis-community/TRELLIS` @ `91c1b5afbf24094b3ec7d8a27ae2e49608bd668f`, run 2026-10-03. Not final production art |
