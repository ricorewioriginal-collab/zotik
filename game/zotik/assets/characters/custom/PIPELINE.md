# Zotik custom model – multi-view + rigging preparation (PLACEHOLDER pipeline, nothing integrated)

## 1. Multi-view input (done)
`multiview/zotik_{front,front34,side,back34,back}.png` – full-body crops (3x Lanczos upscale) from
`reference/approved/ZOTIK_MASTER_CHARACTER_SHEET_1.0.png`. Known flaws: the sheet's source resolution is low
(~170 px per figure), and `front34`, `side`, `back34`, `back` still show slivers of neighbouring figures
at the edges, so remove them (or keep only the largest foreground blob) before/while background removal.

Run (TRELLIS Space `trellis-community/TRELLIS`, MIT):
- Use the **Multiple Images** tab with `front`, `side`, `back` (clean, orthogonal), algo `stochastic`,
  simplify 0.95, texture 1024. The model has full legs/feet now, so no base disc is expected.
- Not run by Claude: the account has no ZeroGPU quota and the MCP `invoke` is disabled. Run it in the browser,
  drop the resulting GLB here as `zotik_trellis_mv.glb`.

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
