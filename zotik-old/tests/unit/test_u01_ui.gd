extends TestCase

var game: GameRoot


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()


func test_project_theme_is_in_sync() -> void:
	eq(ProjectSettings.get_setting("gui/theme/custom"), UiStyle.THEME_PATH, "project theme set")
	var saved: Theme = load(UiStyle.THEME_PATH)
	var built := UiStyle.build_theme()
	for item in [["normal", "Button"], ["hover", "Button"], ["panel", "PanelContainer"], ["fill", "ProgressBar"]]:
		var a := saved.get_stylebox(item[0], item[1]) as StyleBoxFlat
		var b := built.get_stylebox(item[0], item[1]) as StyleBoxFlat
		check(a != null and a.bg_color.is_equal_approx(b.bg_color) and a.border_color.is_equal_approx(b.border_color), "%s/%s matches UiStyle (regenerate zotik_theme.tres)" % item)
	check(saved.default_font != null, "theme font")


func test_hud_shows_frame_minimap_quest_and_icons() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	await frames(2)
	var hud := game.hud
	check(hud.find_child("CharacterFrame", true, false) != null, "character frame")
	eq(hud.lun_label.text, "%d Lun" % GameState.currency, "currency shown")
	check(hud.minimap.is_visible_in_tree(), "minimap")
	check(hud.quest_box.visible and hud.objective_label.text != "", "quest box with objective")
	eq(hud.icon_bar.get_child_count(), 3, "three menu icons plus the gear tile")
	check(hud.gear != null and hud.gear.icon_kind == "gear", "gear tile")
	(hud.icon_bar.get_node("Icon_inventory") as IconButton).pressed.emit()
	await frames(2)
	check(game.inventory_menu.visible, "icon opens the inventory")
	game.inventory_menu.close_menu()


func test_dialogue_box_name_plate() -> void:
	Dialogue.talk_to("NPC_MIRA_001")
	await frames(1)
	check(game.dialogue_box.plate.visible, "speaker plate for NPCs")
	await finish_dialogues()
