extends TestCase
## S02: the dunes of Solmera. Nuri opens the Dünentor, desert enemies,
## sandstorm look, savepoint and chest.

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
	GameState.set_flag("FLAG_SOL_ARRIVED")


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func test_nuri_opens_the_dune_gate() -> void:
	game.enter_area("AREA_SOL_OASIS", "default")
	await physics_frames(2)
	check(not game.area.is_exit_open("AREA_SOL_DUNES"), "dunes closed at first")
	eq(Dialogue.select_for_npc("NPC_NURI_001"), "DLG_NURI_LEAD_001", "Nuri offers to lead")
	Dialogue.talk_to("NPC_NURI_001")
	await finish_dialogues()
	check(game.area.is_exit_open("AREA_SOL_DUNES"), "dunes open")
	check(not game.area.find_child("PLACEHOLDER_dune_gate", true, false).visible, "gate prop gone")
	eq(Dialogue.select_for_npc("NPC_NURI_001"), "DLG_NURI_IDLE_001", "idle afterwards")
	eq(Navigator.next_hop("AREA_SOL_BAZAAR", "AREA_SOL_DUNES"), "AREA_SOL_OASIS", "route from the bazaar")


func test_dunes_content_and_sandstorm() -> void:
	GameState.set_flag("FLAG_SOL_DUNES_OPEN")
	game.enter_area("AREA_SOL_DUNES", "AREA_SOL_OASIS")
	await physics_frames(2)
	for k in ["SPAWN_SOL_DUNES_SKORPION_1", "SPAWN_SOL_DUNES_SKORPION_2", "SPAWN_SOL_DUNES_GEIST_1", "SPAWN_SOL_DUNES_GEIST_2", "CHEST_SOL_001", "SAVEPOINT_SOL_DUNES_001"]:
		check(game.area.entities.has(k), k)
	var we := game.area.find_child("WorldEnvironment", true, false) as WorldEnvironment
	check(we != null and we.environment.fog_density > 0.015, "sandstorm: dense fog")
	game.enter_area("AREA_SOL_OASIS", "default")
	await physics_frames(2)
	var calm := game.area.find_child("WorldEnvironment", true, false) as WorldEnvironment
	check(calm.environment.fog_density < 0.01, "no sandstorm in the oasis")
	check(not game.area.is_exit_open("AREA_SOL_DUNES") or GameState.has_flag("FLAG_SOL_DUNES_OPEN"), "gate follows the flag")


func test_enemies_defeatable_and_in_bestiary() -> void:
	GameState.set_flag("FLAG_SOL_DUNES_OPEN")
	game.enter_area("AREA_SOL_DUNES", "AREA_SOL_OASIS")
	await physics_frames(2)
	for spawn in ["SPAWN_SOL_DUNES_SKORPION_1", "SPAWN_SOL_DUNES_GEIST_1"]:
		var e: Enemy = game.area.entities[spawn]
		check(e.max_hp > 0, spawn + " has HP")
		e.take_hit(99999)
		check(e.is_dead(), spawn + " defeated")
	eq(Guild.kills("ENEMY_SANDSKORPION_001"), 1, "scorpion in the bestiary")
	eq(Guild.kills("ENEMY_SANDGEIST_001"), 1, "spirit in the bestiary")
	check(Inventory.count("ITEM_SUN_DUST_001") >= 3, "Sonnenstaub drops")
	for id in ["ENEMY_SANDSKORPION_001", "ENEMY_SANDGEIST_001"]:
		check(CreatureVisual.ARCHETYPES.has(id), id + " has a model")


func test_savepoint_and_chest() -> void:
	GameState.set_flag("FLAG_SOL_DUNES_OPEN")
	game.enter_area("AREA_SOL_DUNES", "AREA_SOL_OASIS")
	await physics_frames(2)
	GameState.player.hp = 10
	game.area.entities["SAVEPOINT_SOL_DUNES_001"].interact(game.player)
	eq(int(GameState.player.hp), int(GameState.player.max_hp), "anchor heals")
	game.save_menu.save(1)
	game.save_menu.close_menu()
	eq(SaveSystem.load_slot(1), SaveSystem.Status.OK, "saved at the anchor")
	var money := GameState.currency
	game.area.entities["CHEST_SOL_001"].interact(game.player)
	eq(GameState.currency, money + 90, "chest gold")
	eq(Inventory.count("ITEM_HI_POTION_001"), 2, "chest potions")
	game.area.entities["CHEST_SOL_001"].interact(game.player)
	eq(GameState.currency, money + 90, "chest opens once")
