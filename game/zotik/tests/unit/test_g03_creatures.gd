extends TestCase


func test_every_enemy_has_an_archetype() -> void:
	for id in Content.table("enemies"):
		check(CreatureVisual.ARCHETYPES.has(id), "archetype for " + id)


func test_creature_reacts_to_state() -> void:
	var v := CreatureVisual.create("ENEMY_RIFTLING_001", Color(0.3, 0.2, 0.4))
	tree.root.add_child(v)
	check(v.legs.size() == 2 and v.arms.size() == 2, "imp limbs")
	v.animate(1, 3.0, 0.1)
	check(absf(v.legs[0].rotation.x) > 0.0, "walk cycle when moving")
	v.lunge()
	v.animate(3, 0.0, 0.016)
	check(v.root.position.z < -0.2, "strike lunge forward (-Z)")
	v.animate(2, 0.0, 0.016)
	check(v.root.rotation.x > 0.0, "wind-up rears back")
	v.set_tint(Color.RED)
	eq(v.skin.albedo_color, Color.RED, "tint for hit/wind-up feedback")
	v.queue_free()


func test_enemy_uses_creature_visual() -> void:
	var e := Enemy.create({"enemy": "BOSS_ORUN_001", "spawn": "SPAWN_TEST_ORUN", "pos": [0, 0, 0]})
	tree.root.add_child(e)
	check(e.body_mesh is CreatureVisual and e.body_mesh.archetype == "golem", "Orun is a golem")
	e.queue_free()
