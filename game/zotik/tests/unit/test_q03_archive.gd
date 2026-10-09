extends TestCase
## Q03: the Weltenarchiv of Aqualis. The stairs open at the end of the caves,
## the current-valve puzzle opens the vault, the Archivwächter guards it.

const PUZ := "PUZ_AQU_CURRENTS_001"
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
	for f in ["FLAG_AQU_ARRIVED", "FLAG_AQU_CAVES_OPEN"]:
		GameState.set_flag(f)


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _enter_archive() -> void:
	GameState.set_flag("FLAG_AQU_ARCHIVE_OPEN")
	game.enter_area("AREA_AQU_ARCHIVE", "AREA_AQU_CAVES")
	await physics_frames(2)


func test_stairs_open_at_the_end_of_the_caves() -> void:
	game.enter_area("AREA_AQU_CAVES", "AREA_AQU_DOME")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_AQU_ARCHIVE"), "closed at first")
	var trig: Node3D = game.area.entities["TRIGGER_AQU_ARCHIVE"]
	game.player.global_position = trig.global_position - Vector3(0, 1, 0)
	await physics_frames(3)
	eq(Dialogue.active_id, "CUT_AQU_ARCHIVE_001", "stairs scene")
	await finish_dialogues()
	check(GameState.has_flag("FLAG_AQU_ARCHIVE_OPEN"), "flag set")
	check(game.area.is_exit_open("AREA_AQU_ARCHIVE"), "stairs open")
	check(not game.area.find_child("PLACEHOLDER_reef_gate", true, false).visible, "gate prop gone")
	eq(Navigator.next_hop("AREA_AQU_DOME", "AREA_AQU_VAULT"), "AREA_AQU_CAVES", "route to the vault")


func test_archive_content_and_closed_vault() -> void:
	await _enter_archive()
	for k in [PUZ, "SAVEPOINT_AQU_ARCHIVE_001", "CHEST_AQU_002", "LORE_AQU_003", "SPAWN_AQU_ARCHIVE_KRABBE_1", "SPAWN_AQU_ARCHIVE_QUALLE_2"]:
		check(game.area.entities.has(k), k)
	check(not game.area.is_exit_open("AREA_AQU_VAULT"), "vault closed until the currents are calm")
	check(game.area.find_child("PLACEHOLDER_vault_door", true, false).visible, "vault door visible")


func test_current_valves_puzzle() -> void:
	await _enter_archive()
	var node: PuzzleNode = game.area.entities[PUZ]
	eq(node.parts.size(), 4, "four valves")
	eq(int(PuzzleLogic.data(PUZ).channels), 4, "four currents")
	check(PuzzleLogic.valves_solvable(PuzzleLogic.data(PUZ)), "solvable")
	# a wrong valve pair does not solve it
	node.parts[1].interact(game.player)
	check(not PuzzleLogic.is_solved(PUZ), "one wrong valve is not enough")
	node.parts[1].interact(game.player)  # a second turn undoes the first
	eq(Array(PuzzleLogic.state(PUZ).current), [1, 1, 1, 1], "second turn undoes the first")
	node.parts[0].interact(game.player)
	node.parts[2].interact(game.player)
	check(PuzzleLogic.is_solved(PUZ), "valves 1 and 3 calm every current")
	check(GameState.has_flag("FLAG_AQU_CURRENT_DONE"), "flag")
	check(Inventory.count("ITEM_PEARL_001") >= 3, "pearl reward")
	await frames(2)
	check(game.area.is_exit_open("AREA_AQU_VAULT"), "vault open")
	check(not game.area.find_child("PLACEHOLDER_vault_door", true, false).visible, "door gone")
	eq(PuzzleLogic.data(PUZ).hints.size(), 3, "three hints")


func test_archivwaechter_miniboss() -> void:
	GameState.set_flag("FLAG_AQU_CURRENT_DONE")
	game.enter_area("AREA_AQU_VAULT", "AREA_AQU_ARCHIVE")
	await physics_frames(2)
	var w: Enemy = game.area.entities["SPAWN_AQU_VAULT_WAECHTER"]
	check(w.break_max > 0.0, "break gauge")
	w.take_hit(99999)
	check(GameState.has_flag("FLAG_AQU_WAECHTER_DEFEATED"), "defeat flag")
	eq(Guild.kills("ENEMY_ARCHIVWAECHTER_001"), 1, "bestiary")
	check(Inventory.count("ITEM_PEARL_001") >= 5, "drops")
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "save")
	GameState.reset_new_game()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "load")
	game.enter_area("AREA_AQU_VAULT", "AREA_AQU_ARCHIVE")
	await physics_frames(2)
	check(not game.area.entities.has("SPAWN_AQU_VAULT_WAECHTER"), "Archivwächter stays defeated after reload")


func test_anchor_and_chest() -> void:
	await _enter_archive()
	GameState.player.hp = 5
	game.area.entities["SAVEPOINT_AQU_ARCHIVE_001"].interact(game.player)
	eq(int(GameState.player.hp), int(GameState.player.max_hp), "anchor heals")
	game.save_menu.close_menu()
	var money := GameState.currency
	game.area.entities["CHEST_AQU_002"].interact(game.player)
	eq(GameState.currency, money + 130, "chest gold")
	eq(Inventory.count("ITEM_ELIXIR_001"), 1, "chest elixir")
