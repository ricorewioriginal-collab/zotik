class_name TouchControls
extends Control
## On-screen controls for Android / touch screens (A01, reworked in A02): a
## floating stick on the left, camera swipe on the right half and a few
## translucent action buttons bottom-right. Emits the same input actions as
## keyboard/gamepad (Input.parse_input_event), so gameplay code is unchanged.
##
## A02 (owner: "irritierende Flächen", "muss per Touch steuerbar sein"):
## - three big buttons (attack, dodge, jump), three small ones (strong, block,
##   potion); "Benutzen" only appears while something can be used
## - translucent at rest, brighter while pressed; size and opacity are
##   settings (pause menu)
## - tap the world: tap a person, chest or stone to use it, tap an enemy to
##   lock on
## Hidden during dialogue (a tap advances it) and while a menu is open.

const STICK_RADIUS := 100.0
const CAMERA_SENS := 0.006
const TAP_MAX_SEC := 0.25
const TAP_MAX_MOVE := 20.0
const TAP_PICK_RADIUS := 110.0   # screen px around a tapped object
const TAP_REACH := 1.7           # tapped objects must be within INTERACT_RANGE * this
const ACTIONS := [
	# [action, label, anchor offset from bottom-right (x, y), radius, kind]
	["attack", "Angriff", Vector2(150, 150), 62.0, "main"],
	["dodge", "Ausweichen", Vector2(300, 90), 44.0, "main"],
	["jump", "Springen", Vector2(100, 285), 44.0, "main"],
	["strong_attack", "Stark", Vector2(285, 215), 36.0, "minor"],
	["block", "Block", Vector2(405, 80), 32.0, "minor"],
	["use_item", "Trank", Vector2(215, 340), 32.0, "minor"],
	["interact", "Benutzen", Vector2(345, 320), 50.0, "context"],
]

var game: Node
var force := false  # tests / settings toggle
var _stick_index := -1
var _stick_origin := Vector2.ZERO
var _stick_vec := Vector2.ZERO
var _camera_index := -1
var _buttons := {}      # touch index -> action
var _rects := []        # [action, center, radius, Rect2]
var _panels := {}       # action -> Panel
var _stick_down := {}     # move action -> true while the stick holds it
var _removed_mouse := {}  # action -> mouse-button events removed in touch mode
var _starts := {}         # touch index -> [time msec, position] (tap detection)
var _stick_base: Panel
var _stick_knob: Panel
var _applied := [-1.0, -1.0]  # scale / opacity the layout was built for


static func wanted() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or bool(Settings.get_value("touch_controls"))


func _ready() -> void:
	name = "TouchControls"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base = _circle(STICK_RADIUS, Color(1, 1, 1, 0.12))
	_stick_knob = _circle(44.0, Color(1, 1, 1, 0.35))
	for a in ACTIONS:
		_panels[a[0]] = _circle(a[3], Color(0.05, 0.09, 0.2, 0.6), a[1])
	get_viewport().size_changed.connect(_layout)
	_layout()


func active() -> bool:
	return (force or wanted()) and visible


func ui_scale() -> float:
	return clampf(float(Settings.get_value("touch_scale")), 0.6, 1.6)


func ui_opacity() -> float:
	return clampf(float(Settings.get_value("touch_opacity")), 0.15, 1.0)


func _process(_delta: float) -> void:
	var busy: bool = Dialogue.is_active() or (game != null and game.is_menu_open())
	var show: bool = (force or wanted()) and not busy and (game == null or game.player.control_enabled)
	if visible and not show:
		_release_all()
	visible = show
	_set_touch_bindings(force or wanted())
	if game:
		game.hud.touch_mode = force or wanted()
	if _applied != [ui_scale(), ui_opacity()]:
		_layout()
	_update_context()


## "Benutzen" is only offered while the player stands next to something usable.
func _update_context() -> void:
	var p: Panel = _panels.get("interact")
	if p == null:
		return
	var can: bool = game != null and game.player.current_interactable != null
	if p.visible != can:
		p.visible = can
		_rebuild_rects()
		if not can:
			for i in _buttons.keys():
				if _buttons[i] == "interact":
					_send("interact", false)
					_buttons.erase(i)
	if can:
		var pulse := 0.85 + 0.15 * sin(Time.get_ticks_msec() / 220.0)
		if not _buttons.values().has("interact"):
			p.modulate = Color(1, 1, 1, minf(1.0, ui_opacity() + 0.25) * pulse)


## Touch screens turn every tap into an emulated left click. Mouse-button
## bindings (attack = LMB, block = RMB) are therefore removed in touch mode,
## otherwise every stick or camera touch would also attack. Restored when
## touch mode is switched off.
func _set_touch_bindings(on: bool) -> void:
	if on and _removed_mouse.is_empty():
		for action in InputMap.get_actions():
			for ev in InputMap.action_get_events(action):
				if ev is InputEventMouseButton:
					_removed_mouse.get_or_add(action, []).append(ev)
					InputMap.action_erase_event(action, ev)
		if _removed_mouse.is_empty():
			_removed_mouse["_none"] = []
	elif not on and not _removed_mouse.is_empty():
		for action in _removed_mouse:
			for ev in _removed_mouse[action]:
				InputMap.action_add_event(action, ev)
		_removed_mouse.clear()


func _exit_tree() -> void:
	_set_touch_bindings(false)


func _layout() -> void:
	var size_v := get_viewport_rect().size
	var s := ui_scale()
	var op := ui_opacity()
	_applied = [s, op]
	_stick_base.scale = Vector2.ONE * s
	_stick_knob.scale = Vector2.ONE * s
	_stick_base.pivot_offset = _stick_base.size / 2.0
	_stick_knob.pivot_offset = _stick_knob.size / 2.0
	# the scaled circle keeps a 60 px margin to the screen corner
	_stick_base.position = Vector2(60 + STICK_RADIUS * (s - 1.0), size_v.y - 60 - STICK_RADIUS * (s + 1.0))
	_stick_base.modulate.a = op * 0.55
	_stick_knob.modulate.a = op
	_center_knob()
	for a in ACTIONS:
		var p: Panel = _panels[a[0]]
		var center: Vector2 = size_v - Vector2(a[2]) * s
		p.pivot_offset = p.size / 2.0
		p.scale = Vector2.ONE * s
		p.position = center - p.size / 2.0
		p.modulate = Color(1, 1, 1, op if a[4] != "minor" else op * 0.8)
		if a[4] == "context":
			p.visible = false
	_rebuild_rects()


func _rebuild_rects() -> void:
	_rects.clear()
	var size_v := get_viewport_rect().size
	var s := ui_scale()
	for a in ACTIONS:
		var p: Panel = _panels[a[0]]
		if p.visible:
			_rects.append([a[0], size_v - Vector2(a[2]) * s, a[3] * s, Rect2()])


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_on_press(st.index, st.position)
		else:
			_on_release(st.index, st.position)
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _stick_index:
			_stick_vec = (sd.position - _stick_origin).limit_length(STICK_RADIUS * ui_scale()) / (STICK_RADIUS * ui_scale())
			_stick_knob.position = _stick_origin + _stick_vec * STICK_RADIUS * ui_scale() - _stick_knob.size / 2.0
			_stick_knob.modulate.a = minf(1.0, ui_opacity() + 0.3)
			_send_stick()
		elif sd.index == _camera_index and game:
			game.player.camera_pivot.rotation.y -= sd.relative.x * CAMERA_SENS


func _on_press(index: int, pos: Vector2) -> void:
	if game and game.hud.is_ui_at(pos):
		return  # HUD buttons (menus) get the tap
	var hit := action_at(pos)
	if hit != "":
		_buttons[index] = hit
		_send(hit, true)
		var p: Panel = _panels[hit]
		p.modulate = Color(1.35, 1.35, 1.35, minf(1.0, ui_opacity() + 0.4))
		return
	_starts[index] = [Time.get_ticks_msec(), pos]
	var size_v := get_viewport_rect().size
	if pos.x < size_v.x * 0.45 and _stick_index == -1:
		_stick_index = index
		_stick_origin = pos
		_stick_base.position = pos - _stick_base.size / 2.0
		_stick_vec = Vector2.ZERO
		_stick_base.modulate.a = minf(1.0, ui_opacity() * 0.9)
		_center_knob()
	elif pos.x >= size_v.x * 0.45 and _camera_index == -1:
		_camera_index = index


func _on_release(index: int, pos: Vector2 = Vector2(-1, -1)) -> void:
	if _buttons.has(index):
		_send(_buttons[index], false)
		_restore_button(_buttons[index])
		_buttons.erase(index)
	elif index == _stick_index:
		_stick_index = -1
		_stick_vec = Vector2.ZERO
		_send_stick()
		_layout()
	elif index == _camera_index:
		_camera_index = -1
	if _starts.has(index):
		var st: Array = _starts[index]
		_starts.erase(index)
		var moved: float = (st[1] as Vector2).distance_to(pos) if pos.x >= 0.0 else 0.0
		if Time.get_ticks_msec() - int(st[0]) <= TAP_MAX_SEC * 1000.0 and moved <= TAP_MAX_MOVE and pos.x >= 0.0:
			tap_world(pos)


func _restore_button(action: String) -> void:
	var p: Panel = _panels.get(action)
	if p == null:
		return
	for a in ACTIONS:
		if a[0] == action:
			p.modulate = Color(1, 1, 1, ui_opacity() if a[4] != "minor" else ui_opacity() * 0.8)


## A short tap in the world: use the tapped person / chest / stone when close
## enough, or lock on to a tapped enemy. Returns what happened:
## "interact", "far" (too far away), "lock" or "".
func tap_world(pos: Vector2) -> String:
	if game == null or game.player == null or game.player.camera == null:
		return ""
	var cam: Camera3D = game.player.camera
	var player: Node3D = game.player
	var best: Interactable = null
	var best_d := TAP_PICK_RADIUS
	for n in get_tree().get_nodes_in_group("interactable"):
		var it := n as Interactable
		if it == null or not it.can_interact():
			continue
		var d := _screen_distance(cam, it.global_position + Vector3(0, 1.0, 0), pos)
		if d < best_d:
			best_d = d
			best = it
	if best != null:
		if player.global_position.distance_to(best.global_position) <= Interactable.INTERACT_RANGE * TAP_REACH:
			best.interact(player)
			return "interact"
		game.hud.show_notification("Geh näher heran.")
		return "far"
	var foe: Enemy = null
	best_d = TAP_PICK_RADIUS
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Enemy
		if e == null or e.is_dead() or not e.is_visible_in_tree():
			continue
		var d := _screen_distance(cam, e.global_position + Vector3(0, 1.0, 0), pos)
		if d < best_d:
			best_d = d
			foe = e
	if foe != null:
		player.set_lock(foe)
		return "lock"
	return ""


func _screen_distance(cam: Camera3D, world: Vector3, pos: Vector2) -> float:
	if cam.is_position_behind(world):
		return INF
	return cam.unproject_position(world).distance_to(pos)


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
			_stick_down[pair[0]] = true
		elif _stick_down.has(pair[0]):
			_send(pair[0], false)
			_stick_down.erase(pair[0])


func _release_all() -> void:
	for i in _buttons:
		_send(_buttons[i], false)
		_restore_button(_buttons[i])
	_buttons.clear()
	_starts.clear()
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
	sb.border_color = UiStyle.GOLD if text != "" else Color(1, 1, 1, 0.5)
	sb.set_border_width_all(2 if text != "" else 1)
	sb.anti_aliasing = true
	p.add_theme_stylebox_override("panel", sb)
	if text != "":
		var l := Label.new()
		l.text = text
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var size_px := 22 if r > 55 else (16 if r > 40 else 13)
		if text.length() > 8:
			size_px -= 3
		l.add_theme_font_size_override("font_size", size_px)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(l)
	add_child(p)
	return p
