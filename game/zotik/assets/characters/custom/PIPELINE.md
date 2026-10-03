# Zotik custom model – multi-view + rigging preparation (PLACEHOLDER pipeline, nothing integrated)

## 1. Multi-view input (re-cut 2026-10-03)
`multiview/zotik_{front,side,back}.png` – 768x768 RGBA, transparent background, figure centred, cut from
`reference/approved/ZOTIK_MASTER_CHARACTER_SHEET_1.0.png` (crop boxes in the sheet's 1536x1024 pixels:
front 5,125,175,472 · side 345,125,525,472 · back 650,125,845,472; 3x Lanczos upscale, background removed with
rembg `isnet-general-use` for front/side and `isnet-anime` for back, largest blob kept; floor and neighbouring
figures removed). The 3/4 views were dropped (neighbour overlap).
Known flaws: source resolution is low (~170 px per figure); on `back`, the neighbour's tail was erased by a colour
rule, so one boot is missing and the right arm/ear edge is semi-transparent.

Run (TRELLIS Space `trellis-community/TRELLIS`): Multiple Images with `front`, `side`, `back`, algo `stochastic`,
simplify 0.95, texture 1024. Needs an HF token with ZeroGPU quota (not stored in the repo).

## 2. Rigging (not started)
Target: a skeleton the game can animate. Two options:
- **A. Retarget onto the KayKit skeleton** (preferred): `character_rig.gd` plays KayKit clips
  (Idle, Walking_A, Running_A, attacks, Dodge_Forward …). Auto-rig the mesh to a humanoid skeleton
  (UniRig `VAST-AI/UniRig`, MIT, or Mixamo upload – manual, Adobe login), export GLB, then in Godot
  use a BoneMap + `SkeletonProfileHumanoid` retarget so the existing clips apply. Tail and ears need extra
  bones (tail 4-5 chain, ear 2x2); they are not covered by humanoid clips and can be animated procedurally.
- **B. Mixamo animations** on the Mixamo-rigged mesh (own clip set; more work in `STATES`).

Third-party auto-rig Spaces exist on the Hub (`jasongzy/UniRig`, `Faisal786U/unirig-api`), but uploading the
asset there publishes it, so it needs owner approval first.

## 3. Integration gate (unchanged)
Integrate only if: has skeleton + all `STATES` clips play, height matches `MODEL_HEIGHT` scaling,
no base disc, back side textured, file size sane for Android (< ~5 MB, 1024 texture), and it looks
better than the current rig in a side-by-side render. Keep labelled placeholder until then.

## 4. Result of the multi-view run (2026-10-03)
`zotik_trellis_mv.glb` (front + side + back, seed 42, simplify 0.95, 1024 texture; preview `zotik_trellis_mv_preview.png`).
Better than the bust: full body with legs and boots. Still not integrable:
- square slab under the feet (floor of the source crops), no skeleton/animations,
- tail small and torn, sword on the back is a thin spike, back side nearly black,
- low source resolution (~170 px per view).
Next: re-cut the three views with floor/neighbours removed (transparent background), re-run, then rig.

## 5. Licensing gate
The TRELLIS GLB output is non-commercial/unverified (see `assets/LICENSES.md`). Before any release integration, re-generate with a commercially cleared texture-baking path or get written clearance.
