extends TestCase
## W04: rigged enemy models (CC0 Quaternius) and random encounters (layout "roamers").

var game: GameRoot


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves/"
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	WorldArea.roamers_force = true
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()


func after_each() -> void:
	WorldArea.roamers_force = false
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func test_every_model_loads_and_animates() -> void:
	for id in CreatureVisual.MODELS:
		var v := CreatureVisual.create(id, Color.WHITE)
		tree.root.add_child(v)
		check(v.archetype == "model", id + " uses a model")
		check(v.ap != null and v.clips.has("idle"), id + " has an idle clip")
		check(v.clips.has("attack"), id + " has an attack clip")
		v.animate(1, 3.0, 0.1)
		v.lunge()
		v.animate(3, 0.0, 0.016)
		check(v.root.position.z < -0.2, id + " lunges forward")
		v.set_tint(Color.RED, Color(1, 0.3, 0.3))
		check(v._meshes[0].material_overlay != null, id + " flashes on wind-up")
		v.set_tint(Color.WHITE, Color.WHITE)
		check(v._meshes[0].material_overlay == null, id + " flash ends")
		v.queue_free()


func test_roamers_are_placed_on_free_ground() -> void:
	for area in ["AREA_LUN_FOREST", "AREA_SOL_DUNES", "AREA_IGN_ASH"]:
		game.enter_area(area, "default")
		await physics_frames(2)
		var cfg: Dictionary = game.area.layout.roamers
		eq(game.area.roamers.size(), int(cfg.count), area + " roamer count")
		for r in game.area.roamers:
			var e := r as Enemy
			check(e.roam > 0.0 and not e.persistent, area + " roamer is non-persistent and roams")
			check(e.enemy_id in cfg.pool, area + " roamer from the pool")
			check(not game.area.entities.has(e.spawn_id), area + " roamers stay out of the entity list")
			for k in game.area.layout.get("spawns", {}):
				check(Vector2(e.position.x, e.position.z).distance_to(Vector2(game.area.spawn_point(k).x, game.area.spawn_point(k).z)) >= 9.9, area + " roamer far from entry " + k)


func test_no_roamers_in_hubs_and_when_disabled() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	eq(game.area.roamers.size(), 0, "village is safe")
	WorldArea.roamers_force = false
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	eq(game.area.roamers.size(), 0, "headless runs have no random encounters")


func test_roamer_wanders_and_fights() -> void:
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	var e: Enemy = game.area.roamers[0]
	game.player.global_position = Vector3(-200, 0, -200)
	var start := e.position
	var moved := false
	for i in 1200:
		await physics_frames(1)
		if e.position.distance_to(start) > 0.5:
			moved = true
			break
	check(moved, "an idle roamer strolls around")
	var before := GameState.currency
	e.take_hit(9999)
	check(e.is_dead(), "roamer can be defeated")
	check(GameState.currency > before, "roamer pays out")
	check(not GameState.defeated.has(e.spawn_id), "a roamer is not remembered as defeated")
