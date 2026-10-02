extends TestCase

var game: GameRoot
var queen: Boss


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()
	for f in ["FLAG_LUN_CHAPTER_COMPLETE", "FLAG_ELA_ARRIVED", "FLAG_ELA_ROOTS_PARTED", "FLAG_ELA_QUEEN_MET"]:
		GameState.set_flag(f)
	game.enter_area("AREA_ELA_ROOT_ARENA", "default")
	await physics_frames(2)
	queen = game.area.entities["SPAWN_ELA_ARENA_QUEEN"]


func test_intro_plays_once() -> void:
	GameState.flags.erase("FLAG_ELA_QUEEN_MET")
	game.enter_area("AREA_ELA_ROOT_ARENA", "default")
	await physics_frames(2)
	game.player.global_position = game.area.entities["TRIGGER_ELA_QUEEN_INTRO"].global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_ELA_QUEEN_001", "intro")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_ELA_QUEEN_MET"), "once flag")


func test_phases_summons_and_break() -> void:
	eq(queen.max_hp, 520, "boss hp")
	queen.take_hit(219)
	eq(queen.phase, 1, "Dornenkrone below 60%")
	eq(queen.summons.size(), 2, "two Pilzlinge")
	queen.take_hit(160)
	eq(queen.phase, 2, "Wurzelzorn below 30%")
	eq(queen.summons.size(), 3, "plus a Dornenwolf")
	queen.take_hit(10, 200.0)
	check(queen.is_broken(), "boss can be broken")


func test_root_eruption_hits_unless_avoided() -> void:
	var hz: Dictionary = queen.data.phases[1].hazard
	var hp := int(GameState.player.hp)
	game.player.global_position = Vector3(5, 0, 5)
	queen.spawn_hazard(game.player.global_position, hz)
	await tree.create_timer(float(hz.delay) + 0.15).timeout
	eq(hp - int(GameState.player.hp), int(hz.damage), "standing in it deals hazard damage")
	hp = int(GameState.player.hp)
	queen.spawn_hazard(game.player.global_position, hz)
	game.player.global_position = Vector3(12, 0, 5)
	await tree.create_timer(float(hz.delay) + 0.15).timeout
	eq(int(GameState.player.hp), hp, "stepping out avoids it")
	eq(queen.hazards.size(), 0, "hazards cleaned up")


func test_hazards_start_in_phase_two_only() -> void:
	game.player.global_position = queen.global_position + Vector3(0, 0, 6)
	game.player.invulnerable_time = 999.0
	await physics_frames(200)
	eq(queen.hazards.size(), 0, "no eruptions in phase 1")
	queen.take_hit(219)
	await physics_frames(30)
	check(queen.hazards.size() >= 1, "eruptions in phase 2")


func test_defeat_vision_and_return_to_town() -> void:
	Quests.start("QUEST_MAIN_ELA_001")
	GameState.quests.QUEST_MAIN_ELA_001.step = 9
	queen.take_hit(219)
	var adds := queen.summons.duplicate()
	queen.take_hit(999)
	check(queen.is_dead(), "defeated")
	check(GameState.has_flag("FLAG_BOSS_ELA_QUEEN_DEFEATED"), "flag")
	eq(Conditions.quest_step("QUEST_MAIN_ELA_001"), 10, "quest: return to Mara")
	eq(Dialogue.active_id, "CUT_ELA_QUEEN_DEFEAT_001", "memory vision")
	await finish_dialogues()
	await frames(2)
	await physics_frames(3)
	eq(game.area.area_id, "AREA_ELA_TOWN", "back in town")
	check(adds.all(func(a): return not is_instance_valid(a)), "summons removed")


func test_death_resets_fight_and_hazards() -> void:
	queen.take_hit(219)
	queen.spawn_hazard(Vector3(3, 0, 3), queen.data.phases[1].hazard)
	while not game.player.dead:
		game.player.invulnerable_time = 0.0
		game.player.take_damage(999)
	await tree.create_timer(1.7).timeout
	await physics_frames(2)
	eq(queen.hp, queen.max_hp, "hp reset")
	eq(queen.phase, 0, "phase reset")
	eq(queen.hazards.size(), 0, "hazards cleared")
