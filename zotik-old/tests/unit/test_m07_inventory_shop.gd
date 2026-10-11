extends TestCase

const SHOP := "SHOP_LUN_BORO_001"
var game: GameRoot


func before_each() -> void:
	SaveSystem.save_dir = "user://test_saves/"
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false


func after_each() -> void:
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	SaveSystem.save_dir = "user://saves/"


func _start_game() -> void:
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()


func test_buy_rules() -> void:
	GameState.currency = 25
	eq(Shop.buy(SHOP, "ITEM_HEALING_POTION_001"), Shop.Result.OK, "buy potion")
	eq(GameState.currency, 5, "price deducted")
	eq(Inventory.count("ITEM_HEALING_POTION_001"), 1, "potion added")
	eq(Shop.buy(SHOP, "ITEM_HEALING_POTION_001"), Shop.Result.NOT_ENOUGH_CURRENCY, "insufficient funds")
	eq(GameState.currency, 5, "no deduction on failure")
	eq(Shop.buy(SHOP, "WEAPON_WORLD_BLADE_001"), Shop.Result.NOT_IN_STOCK, "unique not sold")
	GameState.currency = 1000
	eq(Shop.buy(SHOP, "ITEM_MOON_PENDANT_001"), Shop.Result.OK, "pendant")
	eq(Shop.buy(SHOP, "ITEM_MOON_PENDANT_001"), Shop.Result.INVENTORY_FULL, "stack 1")


func test_sell_rules() -> void:
	Inventory.add("WEAPON_MOONBLADE_001")
	Inventory.add("ITEM_RIFT_SHARD_001")
	Inventory.grant_unique("WEAPON_WORLD_BLADE_001")
	GameState.currency = 0
	eq(Shop.sell(SHOP, "WEAPON_MOONBLADE_001"), Shop.Result.OK, "sell moonblade")
	eq(GameState.currency, 60, "half price")
	eq(Shop.sell(SHOP, "ITEM_RIFT_SHARD_001"), Shop.Result.NOT_SELLABLE, "key item")
	eq(Shop.sell(SHOP, "WEAPON_WORLD_BLADE_001"), Shop.Result.NOT_SELLABLE, "unique")
	Inventory.add("WEAPON_TRAINING_SWORD_001")
	eq(Shop.sell(SHOP, "WEAPON_TRAINING_SWORD_001"), Shop.Result.NOT_SELLABLE, "worthless item")


func test_equipped_item_protected() -> void:
	GameState.currency = 500
	Shop.buy(SHOP, "WEAPON_MOONBLADE_001")
	Inventory.equip("WEAPON_MOONBLADE_001")
	eq(Shop.sell(SHOP, "WEAPON_MOONBLADE_001"), Shop.Result.EQUIPPED, "cannot sell equipped last copy")
	eq(GameState.equipment.weapon, "WEAPON_MOONBLADE_001", "still equipped")


func test_use_potion() -> void:
	Inventory.add("ITEM_HEALING_POTION_001", 2)
	var p := Player.new()
	p.stats = Content.player_stats()
	check(not Inventory.use("ITEM_HEALING_POTION_001", p), "no use at full hp")
	eq(Inventory.count("ITEM_HEALING_POTION_001"), 2, "not consumed")
	GameState.player.hp = 30
	check(Inventory.use("ITEM_HEALING_POTION_001", p), "used")
	eq(int(GameState.player.hp), 80, "healed 50")
	eq(Inventory.count("ITEM_HEALING_POTION_001"), 1, "consumed one")
	p.free()


func test_chest_opens_once_and_persists() -> void:
	await _start_game()
	game.enter_area("AREA_LUN_FOREST", "default")
	await physics_frames(2)
	var chest: Chest = game.area.entities["CHEST_LUN_001"]
	var before := GameState.currency
	chest.interact(game.player)
	eq(Inventory.count("ITEM_HEALING_POTION_001"), 2, "contents")
	eq(GameState.currency, before + 30, "currency")
	check(not chest.can_interact(), "cannot reopen")
	chest.interact(game.player)
	eq(Inventory.count("ITEM_HEALING_POTION_001"), 2, "no duplicate loot")
	SaveSystem.save_slot(1)
	GameState.reset_new_game()
	App.continue_game(1)
	await frames(3)
	game = tree.current_scene
	await physics_frames(2)
	check(game.area.entities["CHEST_LUN_001"].is_open(), "chest stays open after load")
	eq(Inventory.count("ITEM_HEALING_POTION_001"), 2, "loot persisted")


func test_boro_dialogue_opens_shop_and_locks_control() -> void:
	await _start_game()
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	Dialogue.talk_to("NPC_BORO_001")
	await finish_dialogues()
	check(game.shop_menu.visible, "shop open after Boro dialogue")
	check(not game.player.control_enabled, "control locked while shop open")
	GameState.currency = 100
	game.shop_menu.buy("ITEM_HEALING_POTION_001")
	eq(Inventory.count("ITEM_HEALING_POTION_001"), 1, "bought via UI")
	game.shop_menu.close_menu()
	check(game.player.control_enabled, "control back after closing")


func test_inventory_menu_equip_changes_stats() -> void:
	await _start_game()
	Inventory.add("WEAPON_MOONBLADE_001")
	Inventory.add("ITEM_MOON_PENDANT_001")
	game.toggle_inventory()
	check(game.inventory_menu.visible and not game.player.control_enabled, "inventory open, control locked")
	var atk := Stats.attack()
	game.inventory_menu.equip("WEAPON_MOONBLADE_001")
	eq(Stats.attack(), atk + 10, "weapon equipped from menu")
	game.inventory_menu.equip("ITEM_MOON_PENDANT_001")
	eq(int(GameState.player.max_hp), 105, "max hp updated")
	game.inventory_menu.unequip("accessory")
	eq(int(GameState.player.max_hp), 100, "max hp after unequip")
	check(int(GameState.player.hp) <= 100, "hp clamped")
	game.toggle_inventory()
	check(game.player.control_enabled, "control restored")
