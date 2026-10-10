extends TestCase
## W06: controller support (phone clip-on pads, Bluetooth/USB gamepads).


func after_each() -> void:
	Gamepad.active = false


func _has_joy(action: String) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton or e is InputEventJoypadMotion:
			return true
	return false


func test_every_gameplay_action_has_a_controller_binding() -> void:
	for a in ["move_left", "move_right", "move_forward", "move_back", "camera_left", "camera_right",
			"camera_up", "camera_down", "interact", "dodge", "attack", "strong_attack", "block",
			"lock_on", "jump", "use_item", "inventory", "quest_log", "bestiary", "menu"]:
		check(InputMap.has_action(a), "action exists: " + a)
		check(_has_joy(a), "controller binding: " + a)


func test_install_is_idempotent() -> void:
	var before := InputMap.action_get_events("interact").size()
	Gamepad.install()
	eq(InputMap.action_get_events("interact").size(), before, "no duplicate events")


func test_last_device_decides() -> void:
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_A
	b.pressed = true
	Gamepad.note_event(b)
	check(Gamepad.active, "pad active")
	var m := InputEventJoypadMotion.new()
	m.axis = JOY_AXIS_LEFT_X
	m.axis_value = 0.1
	Gamepad.active = false
	Gamepad.note_event(m)
	check(not Gamepad.active, "stick drift is ignored")
	Gamepad.active = true
	var k := InputEventKey.new()
	k.keycode = KEY_W
	k.pressed = true
	Gamepad.note_event(k)
	check(not Gamepad.active, "keyboard switches back")


func test_help_text_is_plain() -> void:
	check(Gamepad.HELP.length() > 50, "help present")
