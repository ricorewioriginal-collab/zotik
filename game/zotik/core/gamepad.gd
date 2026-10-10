class_name Gamepad
extends RefCounted
## Controller support (Xbox-style layout, also phone clip-on controllers over Bluetooth/USB).
## Joypad events are added to the named input actions at start-up, so gameplay code keeps
## using the actions only. `active` is true while the last input came from a controller:
## the touch overlay hides then and the help shows the controller layout.
##
##   left stick: move            right stick: camera (also up/down)
##   A: use / talk / confirm     B: dodge / back      X: attack     Y: strong attack (Break)
##   LB or LT: block             RB: target            RT: attack    right stick click: jump
##   D-pad up: healing potion    left: inventory       right: quests down: bestiary
##   Start: help & settings      Back/Select: puzzle hint            left stick click: reset puzzle

const STICK_DEADZONE := 0.25
const HELP := "Controller: linker Stick laufen · rechter Stick Kamera · A sprechen/benutzen · B ausweichen · X angreifen · Y starker Angriff (Break)\nLB/LT blocken · RB anvisieren · RT angreifen · Stick-Klick rechts springen\nSteuerkreuz: oben Heiltrank · links Inventar · rechts Quests · unten Bestiarium\nStart Hilfe & Einstellungen · Select Rätsel-Hinweis · linker Stick-Klick Rätsel zurücksetzen\nMenüs: Steuerkreuz oder Stick wählen, A bestätigen, B zurück"

static var active := false
static var _installed := false


static func install() -> void:
	if _installed:
		return
	_installed = true
	for a in ["camera_up", "camera_down"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a, STICK_DEADZONE)
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_axis("camera_left", JOY_AXIS_RIGHT_X, -1.0)
	_axis("camera_right", JOY_AXIS_RIGHT_X, 1.0)
	_axis("camera_up", JOY_AXIS_RIGHT_Y, -1.0)
	_axis("camera_down", JOY_AXIS_RIGHT_Y, 1.0)
	_axis("attack", JOY_AXIS_TRIGGER_RIGHT, 1.0, 0.5)
	_axis("block", JOY_AXIS_TRIGGER_LEFT, 1.0, 0.5)
	_button("interact", JOY_BUTTON_A)
	_button("dodge", JOY_BUTTON_B)
	_button("attack", JOY_BUTTON_X)
	_button("strong_attack", JOY_BUTTON_Y)
	_button("block", JOY_BUTTON_LEFT_SHOULDER)
	_button("lock_on", JOY_BUTTON_RIGHT_SHOULDER)
	_button("jump", JOY_BUTTON_RIGHT_STICK)
	_button("puzzle_reset", JOY_BUTTON_LEFT_STICK)
	_button("puzzle_hint", JOY_BUTTON_BACK)
	_button("use_item", JOY_BUTTON_DPAD_UP)
	_button("inventory", JOY_BUTTON_DPAD_LEFT)
	_button("quest_log", JOY_BUTTON_DPAD_RIGHT)
	_button("bestiary", JOY_BUTTON_DPAD_DOWN)
	_button("menu", JOY_BUTTON_START)
	_button("help", JOY_BUTTON_GUIDE)


static func _button(action: String, button: JoyButton) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	InputMap.action_add_event(action, e)


static func _axis(action: String, axis: JoyAxis, value: float, deadzone := STICK_DEADZONE) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	InputMap.action_add_event(action, e)
	if deadzone != STICK_DEADZONE:
		InputMap.action_set_deadzone(action, deadzone)


## Called with every input event: the last device decides whether controller hints show.
static func note_event(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.6):
		active = true
	elif event is InputEventScreenTouch or (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		active = false


## Short rumble on every connected controller (hits taken), only while a controller is in use.
static func rumble(weak: float, strong: float, seconds: float) -> void:
	if not active:
		return
	for id in Input.get_connected_joypads():
		Input.start_joy_vibration(id, weak, strong, seconds)
