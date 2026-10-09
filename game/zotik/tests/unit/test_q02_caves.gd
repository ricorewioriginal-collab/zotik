extends TestCase
## Q02: the coral caves of Aqualis. Mirael opens the Korallentor, sea enemies,
## drifting-current look, anchor and chest.

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
	GameState.set_flag("FLAG_AQU_ARRIVED")


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func test_mirael_opens_the_coral_gate() -> void:
	game.enter_area("AREA_AQU_DOME", "default")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_AQU_CAVES"), "caves closed at first")
	eq(Dialogue.select_for_npc("NPC_MIRAEL_001"), "DLG_MIRAEL_LEAD_001", "Mirael offers to lead")
	Dialogue.talk_to("NPC_MIRAEL_001")
	await finish_dialogues()
	check(game.area.is_exit_open("AREA_AQU_CAVES"), "caves open")
	check(not game.area.find_child("PLACEHOLDER_cave_gate", true, false).visible, "gate prop gone")
	eq(Dialogue.select_for_npc("NPC_MIRAEL_001"), "DLG_MIRAEL_IDLE_001", "idle afterwards")
	eq(Navigator.next_hop("AREA_AQU_HARBOUR", "AREA_AQU_CAVES"), "AREA_AQU_DOME", "route from the harbour")


func test_caves_content_and_current() -> void:
	GameState.set_flag("FLAG_AQU_CAVES_OPEN")
	game.enter_area("AREA_AQU_CAVES", "AREA_AQU_DOME")
	await physics_frames(2)
	for k in ["SPAWN_AQU_CAVES_KRABBE_1", "SPAWN_AQU_CAVES_KRABBE_2", "SPAWN_AQU_CAVES_QUALLE_1", "SPAWN_AQU_CAVES_QUALLE_2", "CHEST_AQU_001", "SAVEPOINT_AQU_CAVES_001"]:
		check(game.area.entities.has(k), k)
	var we := game.area.find_child("WorldEnvironment", true, false) as WorldEnvironment
	check(we != null and we.environment.fog_density > 0.02, "drifting current: thick water")
	check(game.area.find_child("PLACEHOLDER_reef_gate", true, false).visible, "reef gate sealed until Q03")
	game.enter_area("AREA_AQU_DOME", "default")
	await physics_frames(2)
	var calm := game.area.find_child("WorldEnvironment", true, false) as WorldEnvironment
	check(calm.environment.fog_density < 0.02, "calmer water in the dome city")


func test_enemies_defeatable_and_in_bestiary() -> void:
	GameState.set_flag("FLAG_AQU_CAVES_OPEN")
	game.enter_area("AREA_AQU_CAVES", "AREA_AQU_DOME")
	await physics_frames(2)
	for spawn in ["SPAWN_AQU_CAVES_KRABBE_1", "SPAWN_AQU_CAVES_QUALLE_1"]:
		var e: Enemy = game.area.entities[spawn]
		check(e.max_hp > 0, spawn + " has HP")
		e.take_hit(99999)
		check(e.is_dead(), spawn + " defeated")
	eq(Guild.kills("ENEMY_RIFFKRABBE_001"), 1, "crab in the bestiary")
	eq(Guild.kills("ENEMY_LEUCHTQUALLE_001"), 1, "jellyfish in the bestiary")
	check(Inventory.count("ITEM_PEARL_001") >= 3, "pearl drops")
	for id in ["ENEMY_RIFFKRABBE_001", "ENEMY_LEUCHTQUALLE_001"]:
		check(CreatureVisual.ARCHETYPES.has(id), id + " has a model")
		check(Enemy.SIZES.has(id), id + " has a size")


func test_savepoint_and_chest() -> void:
	GameState.set_flag("FLAG_AQU_CAVES_OPEN")
	game.enter_area("AREA_AQU_CAVES", "AREA_AQU_DOME")
	await physics_frames(2)
	GameState.player.hp = 10
	game.area.entities["SAVEPOINT_AQU_CAVES_001"].interact(game.player)
	eq(int(GameState.player.hp), int(GameState.player.max_hp), "anchor heals")
	game.save_menu.save(1)
	game.save_menu.close_menu()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "saved at the anchor")
	var money := GameState.currency
	game.area.entities["CHEST_AQU_001"].interact(game.player)
	eq(GameState.currency, money + 100, "chest gold")
	eq(Inventory.count("ITEM_HI_POTION_001"), 2, "chest potions")
	eq(Inventory.count("ITEM_PEARL_001"), 3, "chest pearls")
	game.area.entities["CHEST_AQU_001"].interact(game.player)
	eq(GameState.currency, money + 100, "chest opens once")
