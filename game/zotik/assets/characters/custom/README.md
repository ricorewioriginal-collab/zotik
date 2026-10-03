# custom/ – Zotik TRELLIS test model (PLACEHOLDER, not integrated)

- `zotik_trellis.glb` – textured mesh generated with TRELLIS (MIT license, Space `trellis-community/TRELLIS`)
  from `reference/derived/ZOTIK_FRONT_CROP.png` (cut from `reference/approved/ZOTIK_MASTER_CHARACTER_SHEET_1.0.png`; defaults, simplify 0.95, 1024 texture).
- `zotik_trellis_preview.png` – front / side / back render (three.js, neutral light).
- Status: concept/test placeholder, NOT final production art. This folder is excluded from all export presets (`export_presets.cfg`).

## Evaluation vs. current in-game Zotik (KayKit rig + customization)
Not integrated. Reasons:
1. Static mesh: no skeleton, no animations (idle/walk/attack/dodge cannot play); `character_rig.gd` and
   `customization.gd` need a rigged model.
2. The front crop is a bust, so the model ends in a fused disc-shaped base; legs/feet are missing.
3. Back side is nearly black (no source image of the back); the tail is thin and detached.
4. Face/fur read better than the in-game model, so it is useful as a look reference or portrait.

Re-evaluate for integration only after rigging (e.g. Mixamo/UniRig) and a full-body, multi-view input.
