extends TestCase
## S03: the sunken city of Solmera. The stairs open at the end of the dunes,
## the sun-mirror puzzle opens the Sonnenhalle, the Sandwächter guards it.

const PUZ := "PUZ_SOL_MIRRORS_001"
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
	for f in ["FLAG_SOL_ARRIVED", "FLAG_SOL_DUNES_OPEN"]:
		GameState.set_flag(f)


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _enter_city() -> void:
	GameState.set_flag("FLAG_SOL_RUINS_OPEN")
	game.enter_area("AREA_SOL_SUNKEN", "AREA_SOL_DUNES")
	await physics_frames(2)


func test_stairs_open_at_the_end_of_the_dunes() -> void:
	game.enter_area("AREA_SOL_DUNES", "AREA_SOL_OASIS")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_SOL_SUNKEN"), "closed at first")
	var trig: Node3D = game.area.entities["TRIGGER_SOL_RUINS"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_SOL_RUINS_001", "stairs scene")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_SOL_RUINS_OPEN"), "flag set")
	check(game.area.is_exit_open("AREA_SOL_SUNKEN"), "stairs open")
	check(not game.area.find_child("PLACEHOLDER_ruin_gate", true, false).visible, "gate prop gone")
	eq(Navigator.next_hop("AREA_SOL_OASIS", "AREA_SOL_SUN_HALL"), "AREA_SOL_DUNES", "route to the hall")


func test_city_content_and_closed_hall() -> void:
	await _enter_city()
	for k in [PUZ, "SAVEPOINT_SOL_CITY_001", "CHEST_SOL_002", "LORE_SOL_003", "SPAWN_SOL_CITY_SKORPION_1", "SPAWN_SOL_CITY_GEIST_2"]:
		check(game.area.entities.has(k), k)
	check(not game.area.is_exit_open("AREA_SOL_SUN_HALL"), "hall closed until the mirrors are set")
	check(game.area.find_child("PLACEHOLDER_hall_door", true, false).visible, "hall door visible")


func test_sun_mirrors_puzzle() -> void:
	await _enter_city()
	var node: PuzzleNode = game.area.entities[PUZ]
	eq(node.parts.size(), 5, "four mirrors and the plate")
	check(node.parts[0].prompt.contains("Sonnenspiegel"), "mirror prompt from data")
	check(node.parts[4].prompt.contains("Sonnenlicht"), "plate prompt from data")
	# wrong attempt
	node.parts[0].interact(game.player)
	node.parts[4].interact(game.player)
	check(not PuzzleLogic.is_solved(PUZ), "wrong setting rejected")
	PuzzleLogic.reset(PUZ)
	node.refresh()
	# right setting: 1, 3, 0, 2 quarter turns
	for i in 4:
		for t in [1, 3, 0, 2][i]:
			node.parts[i].interact(game.player)
	node.parts[4].interact(game.player)
	check(PuzzleLogic.is_solved(PUZ), "solved")
	check(GameState.has_flag("FLAG_SOL_MIRRORS_DONE"), "flag")
	check(Inventory.count("ITEM_SUN_DUST_001") >= 3, "Sonnenstaub reward")
	await frames(2)
	check(game.area.is_exit_open("AREA_SOL_SUN_HALL"), "hall open")
	check(not game.area.find_child("PLACEHOLDER_hall_door", true, false).visible, "door gone")
	eq(PuzzleLogic.data(PUZ).hints.size(), 3, "three hints")


func test_sandwaechter_miniboss() -> void:
	GameState.set_flag("FLAG_SOL_MIRRORS_DONE")
	game.enter_area("AREA_SOL_SUN_HALL", "AREA_SOL_SUNKEN")
	await physics_frames(2)
	var w: Enemy = game.area.entities["SPAWN_SOL_HALL_WAECHTER"]
	check(w.break_max > 0.0, "break gauge")
	w.take_hit(99999)
	check(GameState.has_flag("FLAG_SOL_WAECHTER_DEFEATED"), "defeat flag")
	eq(Guild.kills("ENEMY_SANDWAECHTER_001"), 1, "bestiary")
	check(Inventory.count("ITEM_SUN_DUST_001") >= 5, "drops")
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "save")
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "load")
	game.enter_area("AREA_SOL_SUN_HALL", "AREA_SOL_SUNKEN")
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_SOL_HALL_WAECHTER"), "Sandwächter stays defeated after reload")


func test_anchor_and_chest() -> void:
	await _enter_city()
	GameState.player.hp = 5
	game.area.entities["SAVEPOINT_SOL_CITY_001"].interact(game.player)
	eq(int(GameState.player.hp), int(GameState.player.max_hp), "anchor heals")
	game.save_menu.close_menu()
	var money := GameState.currency
	game.area.entities["CHEST_SOL_002"].interact(game.player)
	eq(GameState.currency, money + 120, "chest gold")
	eq(Inventory.count("ITEM_ELIXIR_001"), 1, "chest elixir")
