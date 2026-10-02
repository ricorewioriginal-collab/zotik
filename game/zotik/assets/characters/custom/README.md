# Custom character models – PLACEHOLDER / TEST ONLY

None of these files is final production art (CLAUDE.md rule 6).

## zotik_test.glb – Hunyuan3D-2.1 test model of Zotik
- Source image: `reference/derived/ZOTIK_FRONT_CROP.png` (branch `ccr-44f5f01f-5qpfsm`), cut from the approved Zotik master sheet.
- Generator: the Hugging Face Space `WorldzTech/Hunyuan3D-2.1-Demo`, which runs the model `tencent/Hunyuan3D-2.1`.
  - Settings: seed 1234, randomize_seed off, remove_background on, 30 steps, guidance 5.0, octree 256.
- **Not textured by Hunyuan.** The textured run (`textured=true`) was rejected by ZeroGPU. The anonymous quota is below the requested 270 s of GPU time, and the Space asks for HF PRO.
  - Instead, the shape-only output (same seed) was used, and the reference image was projected onto it as vertex colours by `tools/models/hunyuan_postprocess.py`.
  - Hidden and back-facing areas get a blurred colour of the same image region.
- Post-processing (same script):
  - generated ground plate removed
  - 321,656 → 24,000 triangles
  - feet at y = 0, height 1.0, facing +Z
- Known flaws:
  - the back is guessed by the generator
  - tail, blade and scarf are fused into one surface with the body
  - the projection blurs fine detail

## zotik_test_skinned.res – the same mesh on the shared human skeleton
- Baked by `game/zotik/tools/bake_zotik_test_skin.gd`, using the CC0 Quaternius rig that `ZotikVisual` / `CharacterRig.create_human` also use:
  - The bind pose is Idle_Loop frame 0.
  - Bone rest translations are refitted to Zotik's proportions.
  - Weights come from the CC0 human body (4 nearest vertices, then 3 smoothing passes).
  - Tail, blade, scarf flap and sash are rigid on the pelvis or spine_03.
- Plays every `CharacterRig.HUMAN_STATES` animation. Fused parts (tail, blade) bend with the torso in run and attack.
- Re-bake after any change to `zotik_test.glb`:
  `godot --headless --path game/zotik -s res://tools/bake_zotik_test_skin.gd`

## Licence warning (see docs/CONFLICTS.md C-33)
The Tencent Hunyuan 3D 2.1 Community License does **not** apply in the EU, the UK or South Korea, and §5c forbids using or displaying its outputs there. Do not ship these files in a release before the owner has decided.
