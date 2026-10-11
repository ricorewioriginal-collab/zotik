extends TestCase

var game: GameRoot
var orun: Boss


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()
	GameState.set_flag("FLAG_LUN_ORUN_MET")
	game.enter_area("AREA_LUN_ORUN_ARENA", "default")
	await physics_frames(2)
	orun = game.area.entities["SPAWN_LUN_ARENA_ORUN"]


func _hit(n: int, atk: int = 14) -> void:
	for i in n:
		orun.take_hit(atk)


func test_three_phases_with_summons() -> void:
	eq(orun.phase, 0, "phase 1")
	var c0 := orun.base_color()
	_hit(10)
	eq(orun.hp, 200, "10 hits of 10")
	eq(orun.phase, 0, "200/300 = 66.7% is still phase 1")
	_hit(1)
	eq(orun.phase, 1, "phase 2 below 66%")
	eq(orun.summons.size(), 2, "two riftlings summoned")
	eq(orun.attack_mult, 1.1, "phase 2 attack")
	check(orun.base_color() != c0, "state-driven colour")
	_hit(9)
	eq(orun.phase, 1, "100/300 is still phase 2")
	_hit(1)
	eq(orun.phase, 2, "phase 3 below 33%")
	eq(orun.cooldown_mult, 0.75, "faster in phase 3")
	eq(orun.summons.size(), 2, "no extra summons in phase 3")


func test_big_hit_skips_through_phases_once() -> void:
	orun.take_hit(220)
	eq(orun.phase, 2, "jumped to phase 3")
	eq(orun.summons.size(), 2, "phase 2 summons still happened once")


func test_defeat_sets_flag_persists_and_clears_summons() -> void:
	_hit(11)
	var adds := orun.summons.duplicate()
	eq(adds.size(), 2, "summons exist before defeat")
	var events := []
	EventBus.enemy_defeated.connect(func(id): events.append(id))
	_hit(30)
	check(orun.is_dead(), "defeated")
	check(GameState.has_flag("FLAG_BOSS_LUN_ORUN_DEFEATED"), "flag via on_defeat")
	check(GameState.defeated.has("SPAWN_LUN_ARENA_ORUN"), "persistent")
	check(events.has("BOSS_ORUN_001"), "event")
	await frames(2)
	check(adds.all(func(a): return not is_instance_valid(a)), "summons removed")
	game.enter_area("AREA_LUN_ORUN_ARENA", "default")
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_LUN_ARENA_ORUN"), "does not respawn")


func test_death_during_boss_resets_fight() -> void:
	_hit(25)
	eq(orun.phase, 2, "phase 3 reached")
	var adds := orun.summons.duplicate()
	while not game.player.dead:
		game.player.invulnerable_time = 0.0
		game.player.take_damage(999)
	await tree.create_timer(1.7).timeout
	await physics_frames(2)
	eq(orun.hp, orun.max_hp, "boss hp reset")
	eq(orun.phase, 0, "boss phase reset")
	check(adds.all(func(a): return not is_instance_valid(a)), "summons cleared")
	check(not GameState.has_flag("FLAG_BOSS_LUN_ORUN_DEFEATED"), "not defeated")


func test_boss_passive_during_cutscene_and_hud_bar() -> void:
	game.player.global_position = orun.global_position + Vector3(0, 0, 2.5)
	Dialogue.play_cutscene("CUT_LUN_ORUN_001")
	var hp := int(GameState.player.hp)
	await physics_frames(120)
	eq(int(GameState.player.hp), hp, "no damage during cutscene")
	await finish_dialogues()
	await physics_frames(5)
	check(game.hud.boss_bar.visible, "boss bar visible once engaged")
	check(game.hud.boss_label.text.begins_with("Orun"), "boss name")


func test_arena_intro_trigger_plays_once() -> void:
	GameState.flags.erase("FLAG_LUN_ORUN_MET")
	game.enter_area("AREA_LUN_ORUN_ARENA", "default")
	await physics_frames(2)
	var trig: Node3D = game.area.entities["TRIGGER_LUN_ORUN_INTRO"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_LUN_ORUN_001", "intro plays")
	await finish_dialogues()
	game.player.global_position = trig.global_position + Vector3(0, -1, 5)
	await physics_frames(3)
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	check(not Dialogue.is_active(), "not again")
