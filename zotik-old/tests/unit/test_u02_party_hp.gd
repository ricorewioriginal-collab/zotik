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
	for m in ["PARTY_LYRA_001", "PARTY_NIA_001", "PARTY_ROVAN_001"]:
		Effects.apply({"type": "join_party", "id": m})
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func test_companions_take_damage_and_get_knocked_out() -> void:
	var rovan: Companion = game.companions["PARTY_ROVAN_001"]
	eq(rovan.hp(), 190, "full hp")
	var dmg := rovan.take_damage(40)
	check(dmg > 0 and rovan.hp() == 190 - dmg, "damage reduced by defense")
	rovan.take_damage(9999)
	check(rovan.dead and rovan.hp() == 0, "knocked out")
	eq(rovan.take_damage(10), 0, "no damage while down")
	await physics_frames(10)
	var f: Control = game.hud.party_box.get_child(2)
	eq((f.get_meta("hp_label") as Label).text, "k.o.", "HUD shows k.o.")


func test_knocked_out_recovers_after_the_fight() -> void:
	var nia: Companion = game.companions["PARTY_NIA_001"]
	nia.take_damage(9999)
	nia._ko_quiet = Companion.KO_RECOVER_SEC
	await physics_frames(2)
	check(not nia.dead, "back up when no fight is near")
	check(nia.hp() >= int(ceil(nia.max_hp() * Companion.KO_RECOVER_FRACTION)), "with at least 30 % hp (Lyra may heal right after)")


func test_full_heal_restores_party_and_hp_is_saved() -> void:
	var lyra: Companion = game.companions["PARTY_LYRA_001"]
	lyra.take_damage(60)
	var hurt := lyra.hp()
	SaveSystem.save_slot(1)
	GameState.reset_new_game()
	SaveSystem.load_slot(1)
	eq(int(GameState.party_hp.PARTY_LYRA_001), hurt, "party hp persists")
	game.player.revive_full()
	eq(lyra.hp(), lyra.max_hp(), "full heal (savepoint/respawn) heals companions")


func test_enemies_attack_the_nearest_member() -> void:
	var rovan: Companion = game.companions["PARTY_ROVAN_001"]
	var e := Enemy.create({"enemy": "ENEMY_RIFTLING_001", "spawn": "SPAWN_TEST_PHP", "pos": [0, 0, 0]})
	game.area.add_child(e)
	e.global_position = rovan.global_position + Vector3(1.0, 0, 0)
	game.player.global_position = rovan.global_position + Vector3(0, 0, 12)
	eq(e._choose_target(), rovan, "closest companion is targeted")
	rovan.take_damage(9999)
	check(e._choose_target() != rovan, "knocked-out members are ignored")
	e.queue_free()


func test_healer_heals_the_weakest_member() -> void:
	var lyra: Companion = game.companions["PARTY_LYRA_001"]
	var rovan: Companion = game.companions["PARTY_ROVAN_001"]
	rovan.take_damage(150)
	var before := rovan.hp()
	lyra.heal_cd = 0.0
	lyra._heal_weakest()
	check(rovan.hp() > before, "Lyra heals Rovan")
