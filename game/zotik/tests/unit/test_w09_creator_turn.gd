extends TestCase
## W09: the character creator preview can be turned by hand through 360 degrees.

var creator: Control


func before_each() -> void:
	GameState.reset_new_game()
	App.goto_scene(App.SCENE_CHARACTER_CREATOR)
	await frames(5)
	creator = tree.current_scene


func test_dragging_turns_zotik_all_the_way_round() -> void:
	var start: float = creator.preview.rotation.y
	var turned := 0.0
	for i in 40:
		var before: float = creator.preview.rotation.y
		creator.turn(0.2)
		turned += wrapf(creator.preview.rotation.y - before, -PI, PI)
	check(turned > TAU, "more than a full circle turned: %f" % turned)
	check(absf(creator.preview.rotation.y) <= PI + 0.001, "angle stays wrapped")
	creator.turn(-0.3)
	check(creator._idle == 0.0, "manual turning pauses the auto spin")
	creator.preview.rotation.y = start


func test_mouse_drag_events_rotate_the_preview() -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	creator._on_preview_input(down)
	var before: float = creator.preview.rotation.y
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(100, 0)
	creator._on_preview_input(move)
	check(not is_equal_approx(creator.preview.rotation.y, before), "drag turned the model")
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	creator._on_preview_input(up)
	check(not creator._dragging, "drag ended")
