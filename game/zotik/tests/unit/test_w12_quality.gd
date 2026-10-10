extends TestCase
## W12: graphics quality for phones and browsers (render scale, shadows, frame cap).


func after_each() -> void:
	Settings.set_value("graphics", "")


func test_levels_trade_sharpness_for_speed() -> void:
	Settings.set_value("graphics", "low")
	check(not Quality.shadows() and Quality.render_scale() < 0.7 and Quality.max_fps() == 30, "low: no shadows, smaller picture, 30 fps")
	Settings.set_value("graphics", "medium")
	check(Quality.shadows() and Quality.render_scale() < 1.0 and Quality.max_fps() == 0, "medium: shadows, slightly smaller picture")
	Settings.set_value("graphics", "high")
	check(Quality.shadows() and is_equal_approx(Quality.render_scale(), 1.0), "high: full picture")


func test_automatic_follows_the_device_and_the_menu_cycles_through() -> void:
	Settings.set_value("graphics", "")
	check(Quality.is_auto(), "automatic by default")
	eq(Quality.level(), "low" if Look.low_end() else "high", "phones and browsers start low, PCs high")
	var seen := []
	for i in 4:
		Quality.cycle()
		seen.append(str(Settings.get_value("graphics")))
	eq(seen, ["low", "medium", "high", ""], "low, medium, high, then automatic again")


func test_the_sun_follows_the_quality() -> void:
	Settings.set_value("graphics", "low")
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	tree.root.add_child(sun)
	Quality.apply(tree)  # headless: does nothing
	sun.shadow_enabled = Quality.shadows()
	check(not sun.shadow_enabled, "low turns the shadows off")
	sun.queue_free()


func test_performance_read_out_is_off_by_default_and_readable() -> void:
	check(not Settings.DEFAULTS.perf_overlay, "off by default")
	Settings.set_value("graphics", "low")
	eq(PerfOverlay.report(30, 0.5, 0.05, 321), "60 fps | 17 ms (max 50) | 321 draws | Niedrig", "report line")


func test_low_halves_the_physics_work_and_stops_catch_up_bursts() -> void:
	Settings.set_value("graphics", "low")
	check(Quality.physics_rate() == 30 and Quality.max_physics_steps() == 2, "low: 30 physics ticks, at most 2 steps per frame")
	Settings.set_value("graphics", "high")
	check(Quality.physics_rate() == 60 and Quality.max_physics_steps() == 8, "high: the engine defaults")


func test_low_hides_fine_zotik_details_but_the_creator_keeps_them() -> void:
	var v := ZotikVisual.new()
	tree.root.add_child(v)
	v.set_detail(false)
	check(not v.parts["PLACEHOLDER_tuft_0"].visible and not v.parts["PLACEHOLDER_tail_tuft_3"].visible, "tufts hidden")
	check(v.parts["PLACEHOLDER_head"].visible and v.parts["PLACEHOLDER_tail"].visible and v.parts["PLACEHOLDER_eye_l"].visible, "head, tail and eyes stay")
	v.set_detail(true)
	check(v.parts["PLACEHOLDER_tuft_0"].visible, "and back")
	v.queue_free()
	var c := ZotikVisual.new()
	c.add_to_group("creator_preview")
	tree.root.add_child(c)
	check(not c.is_in_group("zotik_visual"), "the creator preview is never reduced")
	c.queue_free()
