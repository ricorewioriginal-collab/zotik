extends TestCase

var game: GameRoot
var wolf: Enemy


func before_each() -> void:
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
	game.enter_area("AREA_LUN_RIFT_CAVE", "AREA_LUN_ORUN_ARENA")
	await physics_frames(2)
	wolf = game.area.entities["SPAWN_LUN_CAVE_MOONWOLF_1"]
	game.player.invulnerable_time = 999.0


func _strike(strong: bool) -> int:
	game.player.global_position = wolf.global_position + Vector3(0, 0, 1.4)
	game.player.face(wolf.global_position - game.player.global_position)
	game.player.attack_cooldown = 0.0
	return game.player.attack(strong)


func test_light_and_strong_drain_break() -> void:
	eq(wolf.break_value, 60.0, "full gauge")
	_strike(false)
	eq(wolf.break_value, 52.0, "light -8")
	_strike(true)
	eq(wolf.break_value, 27.0, "strong -25")
	eq(wolf.hp, 80 - 7 - 13, "strong hits harder: 10*1.6=16-3")


func test_full_break_stuns_and_amplifies_damage_once() -> void:
	var starts := []
	var ends := []
	wolf.break_started.connect(func(e): starts.append(e))
	wolf.break_ended.connect(func(e): ends.append(e))
	_strike(true)
	_strike(true)
	_strike(true)
	check(wolf.is_broken(), "broken after 3 strong hits")
	eq(starts.size(), 1, "break_started once")
	var hp := wolf.hp
	_strike(false)
	eq(hp - wolf.hp, 11, "light hit 7 * 1.5 while broken")
	_strike(true)
	eq(starts.size(), 1, "no second break while broken")
	var hp2 := int(GameState.player.hp)
	game.player.invulnerable_time = 0.0
	game.player.global_position = wolf.global_position + Vector3(0, 0, 1.2)
	await physics_frames(60)
	eq(int(GameState.player.hp), hp2, "broken enemy does not attack")
	game.player.invulnerable_time = 999.0
	await physics_frames(int(3.0 * 60) + 10)
	check(not wolf.is_broken(), "recovers after break duration")
	eq(ends.size(), 1, "break_ended once")
	eq(wolf.break_value, 60.0, "gauge refilled")


func test_strong_attack_interrupts_telegraph() -> void:
	game.player.global_position = wolf.global_position + Vector3(0, 0, 1.6)
	var guard := 0
	while wolf.state != Enemy.State.WINDUP and guard < 200:
		await physics_frames(1)
		guard += 1
	eq(wolf.state, Enemy.State.WINDUP, "wolf winds up")
	_strike(false)
	eq(wolf.state, Enemy.State.WINDUP, "light attack does not interrupt")
	var before := wolf.break_value
	_strike(true)
	eq(wolf.state, Enemy.State.RECOVER, "strong attack interrupts")
	eq(before - wolf.break_value, 40.0, "interrupt bonus 25+15")


func test_unbreakable_and_party_break() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var dummy: Enemy = game.area.entities["SPAWN_LUN_DUMMY_001"]
	dummy.take_hit(5, 100.0, true)
	check(not dummy.is_broken(), "dummy has no Break gauge")
	game.enter_area("AREA_LUN_RIFT_CAVE", "AREA_LUN_ORUN_ARENA")
	await physics_frames(2)
	wolf = game.area.entities["SPAWN_LUN_CAVE_MOONWOLF_1"]
	wolf.take_hit(7, float(Content.combat().break_party))
	eq(wolf.break_value, 54.0, "party hit -6")


func test_strong_attack_key_and_death_while_broken() -> void:
	game.player.global_position = wolf.global_position + Vector3(0, 0, 1.4)
	game.player.face(wolf.global_position - game.player.global_position)
	game.player.attack_cooldown = 0.0
	Input.action_press("strong_attack")
	await physics_frames(2)
	Input.action_release("strong_attack")
	eq(wolf.break_value, 35.0, "strong attack via key")
	var ends := []
	wolf.break_ended.connect(func(e): ends.append(e))
	_strike(true)
	_strike(true)
	check(wolf.is_broken(), "broken")
	while not wolf.is_dead():
		_strike(false)
	eq(ends.size(), 1, "break ends with death")
