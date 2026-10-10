extends TestCase
## R11: endgame after the finale: the Weltenriss hub, seven Weltenbrecher superbosses
## with unique EX rewards, and the Halle der 100 (ten ranks of ten trials).

var game: GameRoot
const KEYS := ["WAECHTER", "WURZEL", "KOLOSS", "SANDKOENIG", "ABYSS", "FROSTHERZ", "FEUERKERN"]


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


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _clear_wave() -> void:
	for e in game.arena_run.alive.duplicate():
		e.take_hit(99999)
	await frames(2)


func test_weltenriss_unlocks_with_the_finale() -> void:
	check(not Content.world_unlocked("WORLD_WELTENRISS"), "locked before the finale")
	GameState.set_flag("FLAG_GAME_COMPLETE")
	check(Content.world_unlocked("WORLD_WELTENRISS"), "unlocked after the finale")
	game.enter_area("AREA_END_HUB", "travel")
	await physics_frames(3)
	await finish_dialogues()
	eq(game.area.exits.size(), 7, "seven superboss gates")
	for k in KEYS:
		check(game.area.exits.has("AREA_END_" + k) and game.area.is_exit_open("AREA_END_" + k), "gate to " + k)
		check("AREA_END_HUB" in Content.get_entry("areas", "AREA_END_" + k).exits, k + " leads back")


func test_superbosses_are_defined_with_phases_and_rewards() -> void:
	for k in KEYS:
		var b := Content.enemy("BOSS_END_%s_001" % k)
		eq(b.phases.size(), 3, k + " phases")
		check(b.hp >= 1700 and b.hp <= 2400, k + " hp")
		var reward: String = b.on_defeat[1].id
		check(Content.item(reward).get("unique", false), k + " reward is unique")
		check(CreatureVisual.ARCHETYPES.has("BOSS_END_%s_001" % k), k + " has a look")


func test_superboss_gives_its_ex_reward_once() -> void:
	GameState.set_flag("FLAG_GAME_COMPLETE")
	for round in 2:
		game.enter_area("AREA_END_WAECHTER", "default")
		await physics_frames(3)
		var boss: Boss = game.area.entities["SPAWN_END_WAECHTER_BOSS"]
		boss.take_hit(99999)
		await finish_dialogues()
	check(GameState.has_flag("FLAG_END_WAECHTER_DEFEATED"), "defeat flag")
	eq(Inventory.count("WEAPON_WORLD_BLADE_EX_001"), 1, "Weltenklinge EX only once")
	check(Inventory.count("ITEM_RIFT_ESSENCE_001") >= 8, "essence from both fights")


func test_halle_der_100_has_ten_ranks_of_ten_trials() -> void:
	var ids := Content.table("arena").keys().filter(func(i): return str(i).begins_with("ARENA_HALL_"))
	ids.sort()
	eq(ids.size(), 10, "ten ranks")
	var waves := 0
	for id in ids:
		waves += Content.get_entry("arena", id).waves.size()
	eq(waves, 100, "one hundred trials")
	check(not ArenaRun.unlocked("ARENA_HALL_001"), "locked before the finale")
	GameState.set_flag("FLAG_GAME_COMPLETE")
	check(ArenaRun.unlocked("ARENA_HALL_001"), "rank 1 open after the finale")
	check(not ArenaRun.unlocked("ARENA_HALL_002"), "rank 2 needs rank 1")


func test_halle_rank_one_and_the_last_shard() -> void:
	GameState.set_flag("FLAG_GAME_COMPLETE")
	game.enter_area("AREA_END_HUB", "travel")
	await physics_frames(3)
	await finish_dialogues()
	check(game.start_arena("ARENA_HALL_001"), "rank 1 starts")
	for i in 10:
		await _clear_wave()
	check(not game.arena_run.active(), "rank 1 finished")
	check(GameState.has_flag("FLAG_END_HALL_1"), "rank 1 flag")
	check(ArenaRun.unlocked("ARENA_HALL_002"), "rank 2 open")
	for r in range(2, 10):
		GameState.set_flag("FLAG_END_HALL_%d" % r)
	check(game.start_arena("ARENA_HALL_010"), "final rank starts")
	for i in 10:
		await _clear_wave()
	eq(Inventory.count("ITEM_LAST_SHARD_001"), 1, "the last shard")


func test_endgame_dungeons_are_rift_runs_with_modifiers() -> void:
	var ids := Content.table("arena").keys().filter(func(i): return str(i).begins_with("ARENA_DUNGEON_"))
	ids.sort()
	eq(ids.size(), 7, "seven endgame dungeons")
	var kinds := {}
	for id in ids:
		var a := Content.get_entry("arena", id)
		kinds[a.rift_kind] = true
		eq(a.waves.size(), 5, str(id) + " has five waves")
	for k in ["klein", "tief", "erinnerung", "instabil", "welten"]:
		check(kinds.has(k), "rift kind " + k)
	GameState.set_flag("FLAG_GAME_COMPLETE")
	check(ArenaRun.unlocked("ARENA_DUNGEON_001") and not ArenaRun.unlocked("ARENA_DUNGEON_002"), "dungeons unlock in order")


func test_rift_modifier_toughens_enemies() -> void:
	GameState.set_flag("FLAG_GAME_COMPLETE")
	game.enter_area("AREA_END_HUB", "travel")
	await physics_frames(3)
	await finish_dialogues()
	check(game.start_arena("ARENA_DUNGEON_001"), "first dungeon starts")
	var e: Enemy = game.arena_run.alive[0]
	var base := int(Content.enemy(e.enemy_id).hp)
	eq(e.max_hp, int(round(base * 1.0)), "small rift: normal hp")
	game.arena_run.lose()
	await tree.create_timer(0.1).timeout
	for i in range(1, 6):
		GameState.set_flag("FLAG_END_DUNGEON_%d" % i)
	game.enter_area("AREA_END_HUB", "travel")
	await physics_frames(3)
	check(game.start_arena("ARENA_DUNGEON_006"), "Elyndra Vorher starts")
	var w: Enemy = game.arena_run.alive[0]
	var wb := int(Content.enemy(w.enemy_id).hp)
	eq(w.max_hp, int(round(wb * 1.9)), "world rift: 1.9x hp")
	eq(w.attack_mult, 1.5, "world rift: 1.5x attack")


func test_walkable_endgame_dungeons_open_after_the_superbosses() -> void:
	GameState.set_flag("FLAG_GAME_COMPLETE")
	for i in KEYS.size():
		var arena: String = "AREA_END_" + KEYS[i]
		var dungeon: String = "AREA_END_D%d" % (i + 1)
		game.enter_area(arena, "default")
		await physics_frames(2)
		check(not game.area.is_exit_open(dungeon), KEYS[i] + ": dungeon closed while the boss stands")
		GameState.set_flag("FLAG_END_%s_DEFEATED" % KEYS[i])
		check(game.area.is_exit_open(dungeon), KEYS[i] + ": dungeon open after the boss")
		game.enter_area(dungeon, arena)
		await physics_frames(2)
		var enemies := 0
		for k in game.area.entities:
			if game.area.entities[k] is Enemy:
				enemies += 1
		eq(enemies, 7, dungeon + " has seven enemies")
		check(game.area.entities.has("CHEST_END_D%d_2" % (i + 1)) and game.area.entities.has("SAVEPOINT_END_D%d_001" % (i + 1)), dungeon + " has chests and a savepoint")
