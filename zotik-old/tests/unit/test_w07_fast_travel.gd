extends TestCase
## W07: touched Weltenanker become fast-travel targets on the world map.

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


func after_each() -> void:
	SaveSystem.save_dir = "user://saves/"


func test_every_anchor_is_in_a_world_and_has_a_default_spawn() -> void:
	for id in Content.world.savepoints:
		var area: String = Content.world.savepoints[id].area
		check(Content.world_of(area) != "", id + " belongs to a world")
		check(Content.layout(area).spawns.has("default"), id + " area has a default spawn")


func test_touching_an_anchor_remembers_it() -> void:
	var world := Content.world_of("AREA_LUN_RIFT_CAVE")
	eq(Content.anchors_of(world).size(), 0, "none before")
	game.enter_area("AREA_LUN_RIFT_CAVE", "default")
	await physics_frames(2)
	var sp: Node = game.area.entities["SAVEPOINT_LUN_RIFT_001"]
	sp.interact(game.player)
	await frames(1)
	check(GameState.has_flag(Content.anchor_flag("SAVEPOINT_LUN_RIFT_001")), "flag set")
	eq(Content.anchors_of(world).size(), 1, "listed afterwards")


func test_world_map_offers_visited_anchors_and_travels() -> void:
	GameState.set_flag(Content.anchor_flag("SAVEPOINT_LUN_RIFT_001"))
	var map := WorldMap.new()
	game.add_child(map)
	map.refresh()
	var found := false
	for b in map.find_children("*", "Button", true, false):
		if (b as Button).text == "Reisen":
			found = true
	check(found, "has travel buttons")
	map.travel_to_area("AREA_LUN_RIFT_CAVE")
	await physics_frames(3)
	eq(GameState.player.area, "AREA_LUN_RIFT_CAVE", "arrived at the anchor area")
	map.queue_free()
