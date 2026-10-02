class_name TouchControls
extends Control
## On-screen controls for Android / touch screens (A01): a virtual stick on
## the left, camera swipe on the right half, action buttons bottom-right and
## menu buttons top-right. Emits the same input actions as keyboard/gamepad
## (Input.parse_input_event), so gameplay code is unchanged. Hidden during
## dialogue (a tap advances it) and while a menu is open (menus are touchable).

const STICK_RADIUS := 110.0
const CAMERA_SENS := 0.006
const ACTIONS := [
	# [action, label, anchor offset from bottom-right (x, y), radius]
	["attack", "Angriff", Vector2(150, 150), 72.0],
	["strong_attack", "Stark", Vector2(300, 110), 54.0],
	["dodge", "Ausweichen", Vector2(110, 300), 54.0],
	["jump", "Springen", Vector2(260, 260), 50.0],
	["interact", "Benutzen", Vector2(400, 200), 50.0],
	["block", "Block", Vector2(110, 440), 46.0],
	["use_item", "Trank", Vector2(420, 70), 42.0],
]
const MENU_ACTIONS := [["menu", "Menü"], ["inventory", "Inventar"], ["quest_log", "Quests"], ["bestiary", "Bestiarium"]]

var game: Node
var force := false  # tests / settings toggle
var _stick_index := -1
var _stick_origin := Vector2.ZERO
var _stick_vec := Vector2.ZERO
var _camera_index := -1
var _buttons := {}      # touch index -> action
var _rects := []        # [action, center, radius]
var _stick_base: Panel
var _stick_knob: Panel


static func wanted() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or bool(Settings.get_value("touch_controls"))


func _ready() -> void:
	name = "TouchControls"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base = _circle(STICK_RADIUS, Color(1, 1, 1, 0.12))
	_stick_knob = _circle(46.0, Color(1, 1, 1, 0.35))
	for a in ACTIONS:
		var p := _circle(a[3], Color(0.1, 0.12, 0.2, 0.45), a[1])
		p.set_meta("action", a[0])
	var x := 20.0
	for m in MENU_ACTIONS:
		var p := _pill(m[1])
		p.set_meta("action", m[0])
		p.set_meta("menu_x", x)
		x += 150.0
	get_viewport().size_changed.connect(_layout)
	_layout()


func active() -> bool:
	return (force or wanted()) and visible


func _process(_delta: float) -> void:
	var busy: bool = Dialogue.is_active() or (game != null and game.is_menu_open())
	var show: bool = (force or wanted()) and not busy and (game == null or game.player.control_enabled)
	if visible and not show:
		_release_all()
	visible = show
	if game:
		game.hud.touch_mode = force or wanted()


func _layout() -> void:
	var size_v := get_viewport_rect().size
	_rects.clear()
	_stick_base.position = Vector2(60, size_v.y - 60 - STICK_RADIUS * 2.0)
	_center_knob()
	for c in get_children():
		if not c.has_meta("action"):
			continue
		if c.has_meta("menu_x"):
			c.position = Vector2(float(c.get_meta("menu_x")), 96)
			_rects.append([c.get_meta("action"), c.position + c.size / 2.0, -1.0, Rect2(c.position, c.size)])
			continue
		for a in ACTIONS:
			if a[0] == c.get_meta("action"):
				var center: Vector2 = size_v - a[2]
				c.position = center - Vector2(a[3], a[3])
				_rects.append([a[0], center, a[3], Rect2()])


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_on_press(st.index, st.position)
		else:
			_on_release(st.index)
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _stick_index:
			_stick_vec = (sd.position - _stick_origin).limit_length(STICK_RADIUS) / STICK_RADIUS
			_stick_knob.position = _stick_origin + _stick_vec * STICK_RADIUS - _stick_knob.size / 2.0
			_send_stick()
		elif sd.index == _camera_index and game:
			game.player.camera_pivot.rotation.y -= sd.relative.x * CAMERA_SENS


func _on_press(index: int, pos: Vector2) -> void:
	var hit := action_at(pos)
	if hit != "":
		_buttons[index] = hit
		_send(hit, true)
		return
	var size_v := get_viewport_rect().size
	if pos.x < size_v.x * 0.45 and _stick_index == -1:
		_stick_index = index
		_stick_origin = pos
		_stick_base.position = pos - _stick_base.size / 2.0
		_stick_vec = Vector2.ZERO
		_center_knob()
	elif pos.x >= size_v.x * 0.45 and _camera_index == -1:
		_camera_index = index


func _on_release(index: int) -> void:
	if _buttons.has(index):
		_send(_buttons[index], false)
		_buttons.erase(index)
	elif index == _stick_index:
		_stick_index = -1
		_stick_vec = Vector2.ZERO
		_send_stick()
		_layout()
	elif index == _camera_index:
		_camera_index = -1


## Action under a screen position ("" if none).
func action_at(pos: Vector2) -> String:
	for r in _rects:
		if r[2] > 0.0 and pos.distance_to(r[1]) <= r[2]:
			return r[0]
		if r[2] < 0.0 and (r[3] as Rect2).has_point(pos):
			return r[0]
	return ""


func _send(action: String, pressed: bool, strength: float = 1.0) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = strength if pressed else 0.0
	Input.parse_input_event(ev)


func _send_stick() -> void:
	var v := _stick_vec
	for pair in [["move_right", maxf(v.x, 0.0)], ["move_left", maxf(-v.x, 0.0)], ["move_back", maxf(v.y, 0.0)], ["move_forward", maxf(-v.y, 0.0)]]:
		var s: float = pair[1]
		if s > 0.05:
			_send(pair[0], true, s)
		elif Input.is_action_pressed(pair[0]):
			_send(pair[0], false)


func _release_all() -> void:
	for i in _buttons:
		_send(_buttons[i], false)
	_buttons.clear()
	_stick_index = -1
	_camera_index = -1
	_stick_vec = Vector2.ZERO
	_send_stick()


func _center_knob() -> void:
	_stick_knob.position = _stick_base.position + _stick_base.size / 2.0 - _stick_knob.size / 2.0


func _circle(r: float, c: Color, text: String = "") -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size = Vector2(r, r) * 2.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(int(r))
	sb.border_color = Color(1, 1, 1, 0.5)
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	if text != "":
		var l := Label.new()
		l.text = text
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.add_theme_font_size_override("font_size", 22 if r > 50 and text.length() <= 7 else 16)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(l)
	add_child(p)
	return p


func _pill(text: String) -> Panel:
	var p := _circle(28.0, Color(0.1, 0.12, 0.2, 0.55), text)
	p.size = Vector2(140, 56)
	return p
