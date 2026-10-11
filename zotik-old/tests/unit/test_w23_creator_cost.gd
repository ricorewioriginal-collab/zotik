extends TestCase
## W23: on low-end devices the character creator redraws its preview at a reduced rate with a still pose.

var creator: Control


func before_each() -> void:
	Look._force_low = true
	GameState.reset_new_game()
	App.goto_scene(App.SCENE_CHARACTER_CREATOR)
	await frames(8)
	creator = tree.current_scene


func after_each() -> void:
	Look._force_low = false


func test_preview_is_throttled_and_still_on_low() -> void:
	check(creator.preview != null, "preview built")
	check(not creator.preview.rig.anim.is_playing(), "pose is still (no per-frame skeleton update)")
	check(creator._viewport.render_target_update_mode in [SubViewport.UPDATE_DISABLED, SubViewport.UPDATE_ONCE], "redraw is driven by hand")


func test_turning_still_works_on_low() -> void:
	var before: float = creator.preview.rotation.y
	creator.turn(0.5)
	check(not is_equal_approx(creator.preview.rotation.y, before), "turned")
