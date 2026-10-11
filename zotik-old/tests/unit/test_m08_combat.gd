extends TestCase

var game: GameRoot


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves/"
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()
	Inventory.add("WEAPON_TRAINING_SWORD_001")
	Inventory.equip("WEAPON_TRAINING_SWORD_001")


func after_each() -> void:
	for a in ["attack", "dodge", "lock_on"]:
		Input.action_release(a)
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _face(e: Node3D) -> void:
	game.player.global_position = e.global_position + Vector3(0, 0, 1.4)
	game.player.face(e.global_position - game.player.global_position)
	await physics_frames(2)


func _hit_until_dead(e: Enemy, max_hits: int = 60) -> int:
	var n := 0
	while not e.is_dead() and n < max_hits:
		game.player.attack_cooldown = 0.0
		game.player.attack()
		n += 1
	return n


func test_dummy_defeated_by_attacks_with_event() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var dummy: Enemy = game.area.entities["SPAWN_LUN_DUMMY_001"]
	await _face(dummy)
	var events := []
	EventBus.enemy_defeated.connect(func(id): events.append(id))
	Input.action_press("attack")
	await physics_frames(2)
	Input.action_release("attack")
	eq(dummy.hp, 10, "attack key hits for 4+6")
	await physics_frames(2)
	eq(_hit_until_dead(dummy), 1, "second hit defeats")
	eq(events, ["ENEMY_TRAINING_DUMMY_001"], "enemy_defeated once")
	game.player.attack_cooldown = 0.0
	eq(game.player.attack(), 0, "dead enemies are not hit")


func test_attack_respects_cone_and_cooldown() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var dummy: Enemy = game.area.entities["SPAWN_LUN_DUMMY_001"]
	await _face(dummy)
	game.player.face(game.player.global_position - dummy.global_position)
	eq(game.player.attack(), 0, "enemy behind is not hit")
	game.player.face(dummy.global_position - game.player.global_position)
	eq(game.player.attack(), 0, "cooldown blocks immediate second attack")
	game.player.attack_cooldown = 0.0
	eq(game.player.attack(), 1, "hit when facing")


func test_riftling_chases_attacks_and_drops() -> void:
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	var r: Enemy = game.area.entities["SPAWN_LUN_FOREST_RIFTLING_1"]
	game.player.global_position = r.global_position + Vector3(0, 0, 6)
	var hp := int(GameState.player.hp)
	await physics_frames(150)
	check(int(GameState.player.hp) < hp, "riftling reached and damaged player (hp %d)" % GameState.player.hp)
	var lun := GameState.currency
	await _face(r)
	_hit_until_dead(r)
	check(r.is_dead(), "riftling defeated")
	eq(Inventory.count("ITEM_MOON_HERB_001"), 1, "drop")
	eq(GameState.currency, lun + 5, "currency drop")


func test_telegraphed_attack_can_be_dodged() -> void:
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	var r: Enemy = game.area.entities["SPAWN_LUN_FOREST_RIFTLING_1"]
	game.player.global_position = r.global_position + Vector3(0, 0, 1.2)
	var guard := 0
	while r.state != Enemy.State.WINDUP and guard < 120:
		await physics_frames(1)
		guard += 1
	eq(r.state, Enemy.State.WINDUP, "windup telegraphed")
	var hp := int(GameState.player.hp)
	while r.timer > 0.1:
		await physics_frames(1)
	game.player.start_dodge(Vector3(0, 0, 1))
	await physics_frames(20)
	eq(int(GameState.player.hp), hp, "dodge i-frames avoid strike")


func test_lock_on_picks_nearest() -> void:
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	var r3: Enemy = game.area.entities["SPAWN_LUN_FOREST_RIFTLING_3"]
	game.player.global_position = r3.global_position + Vector3(0, 0, 3)
	await physics_frames(1)
	Input.action_press("lock_on")
	await physics_frames(2)
	Input.action_release("lock_on")
	eq(game.player.lock_target, r3, "nearest locked")


func test_persistent_and_respawning_enemies() -> void:
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	var r: Enemy = game.area.entities["SPAWN_LUN_FOREST_RIFTLING_1"]
	await _face(r)
	_hit_until_dead(r)
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	check(not game.area.entities["SPAWN_LUN_FOREST_RIFTLING_1"].is_dead(), "regular enemy respawns on re-entry")
	game.enter_area("AREA_LUN_RIFT_CAVE", "AREA_LUN_ORUN_ARENA")
	await physics_frames(2)
	var wolf: Enemy = game.area.entities["SPAWN_LUN_CAVE_MOONWOLF_1"]
	Inventory.add("WEAPON_MOONBLADE_001")
	Inventory.equip("WEAPON_MOONBLADE_001")
	await _face(wolf)
	_hit_until_dead(wolf)
	check(wolf.is_dead(), "wolf defeated")
	SaveSystem.save_slot(1)
	GameState.reset_new_game()
	App.continue_game(1)
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_LUN_CAVE_MOONWOLF_1"), "persistent enemy stays defeated after load")


func test_death_resets_encounter_and_keeps_progress() -> void:
	GameState.set_flag("FLAG_LUN_FOREST_UNLOCKED")
	GameState.set_flag("FLAG_LUN_INTRO_SEEN")
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	var r: Enemy = game.area.entities["SPAWN_LUN_FOREST_RIFTLING_2"]
	r.take_hit(10)
	check(r.hp < r.max_hp, "damaged")
	while not game.player.dead:
		game.player.invulnerable_time = 0.0
		game.player.take_damage(999)
	await tree.create_timer(1.7).timeout
	await physics_frames(2)
	check(not game.player.dead, "revived")
	eq(int(GameState.player.hp), Stats.max_hp(), "full hp")
	eq(r.hp, r.max_hp, "encounter reset")
	check(GameState.has_flag("FLAG_LUN_FOREST_UNLOCKED"), "progress kept")
	check(game.player.global_position.distance_to(game.area.spawn_point("default")) < 1.0, "respawned at area entry")
