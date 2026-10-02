# Content Data Spec
Stable namespaces: QUEST_, DLG_, NPC_, ENEMY_, BOSS_, PUZ_, CHEST_, ITEM_, WEAPON_, COS_, CUT_, MUS_, SFX_, VFX_, FLAG_.

All cross-references must validate at build/test time. Unique rewards (especially WEAPON_WORLD_BLADE_001) must be idempotent. Quest progression is event/condition driven; UI controls cannot directly force completion. Puzzle state includes initial/current/completed plus manual reset and save/reload behavior.
