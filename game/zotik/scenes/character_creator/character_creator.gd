extends Control
## "Mein Zotik" character creator with live 3D preview. Cosmetic only.

const LABELS := {"fur_shade": "Fellton", "scarf": "Schal", "outfit": "Kleidung"}

var preview: ZotikVisual
var value_labels := {}
var confirm_button: Button
var _viewport: SubViewport
var _loading: Label
var _dragging := false
var _idle := 10.0  # seconds since the player last turned Zotik by hand
const AUTO_SPIN := 0.6
const DRAG_SENS := 0.012
const STICK_SPIN := 3.0
const RESUME_AFTER := 3.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Customization.ensure_valid()
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.13)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_right = -56
	row.add_theme_constant_override("separation", 24)
	add_child(row)
	var vpc := SubViewportContainer.new()
	vpc.stretch = true
	vpc.stretch_shrink = 2 if Quality.level() == "low" else 1  # half the pixels per side on phones
	vpc.custom_minimum_size = Vector2(520, 640)
	row.add_child(vpc)
	vpc.gui_input.connect(_on_preview_input)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.positional_shadow_atlas_size = 0  # no point lights here: skip the shadow atlas
	vpc.add_child(vp)
	_loading = Label.new()
	_loading.text = "Zotik wird geladen ..."
	_loading.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_loading.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vpc.add_child(_loading)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.12, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.7, 0.9)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	vp.add_child(light)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.85, 1.75)
	vp.add_child(cam)
	_viewport = vp
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	row.add_child(box)
	box.add_child(UiStyle.title("Mein Zotik", 36))
	for opt in Customization.options():
		var plate := PanelContainer.new()
		plate.add_theme_stylebox_override("panel", MenuPanel._row_box(UiStyle.NAVY_LIGHT, UiStyle.GOLD_DARK))
		box.add_child(plate)
		var line := HBoxContainer.new()
		plate.add_child(line)
		var name_label := Label.new()
		name_label.text = LABELS.get(opt, opt)
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_label.custom_minimum_size.x = 140
		line.add_child(name_label)
		var prev := Button.new()
		prev.text = "<"
		MenuPanel.style_button(prev)
		prev.custom_minimum_size.x = 56
		prev.pressed.connect(change.bind(opt, -1))
		line.add_child(prev)
		var val := Label.new()
		val.custom_minimum_size.x = 240
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.add_child(val)
		value_labels[opt] = val
		var nxt := Button.new()
		nxt.text = ">"
		MenuPanel.style_button(nxt)
		nxt.custom_minimum_size.x = 56
		nxt.pressed.connect(change.bind(opt, 1))
		line.add_child(nxt)
	confirm_button = Button.new()
	confirm_button.text = "Abenteuer beginnen"
	MenuPanel.style_button(confirm_button, true)
	confirm_button.pressed.connect(confirm)
	box.add_child(confirm_button)
	var hint := Label.new()
	hint.text = "Zotik mit Maus oder Finger ziehen, um ihn um 360 Grad zu drehen (Controller: rechter Stick)."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(1, 1, 1, 0.7)
	box.add_child(hint)
	_refresh()
	confirm_button.grab_focus.call_deferred()
	_build_preview.call_deferred()


## The model is built after the first frame: the buttons show up at once, Zotik follows.
func _build_preview() -> void:
	await get_tree().process_frame
	preview = ZotikVisual.new()
	preview.add_to_group("creator_preview")
	preview.rotation.y = PI  # face the preview camera
	_viewport.add_child(preview)
	if _loading:
		_loading.queue_free()
		_loading = null
	_refresh()


func _process(delta: float) -> void:
	if preview == null:
		return
	var stick := Input.get_axis("camera_left", "camera_right")
	if absf(stick) > 0.1:
		preview.rotation.y += stick * STICK_SPIN * delta
		_idle = 0.0
	_idle += delta
	if not _dragging and _idle > RESUME_AFTER:
		preview.rotation.y += delta * AUTO_SPIN


## Drag with the mouse or a finger to turn Zotik all the way round; the slow spin resumes afterwards.
func _on_preview_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		_idle = 0.0
	elif event is InputEventMouseMotion and _dragging:
		turn(event.relative.x * DRAG_SENS)


func turn(angle: float) -> void:
	if preview == null:
		return
	preview.rotation.y = wrapf(preview.rotation.y + angle, -PI, PI)
	_idle = 0.0


func change(option: String, step: int) -> void:
	Customization.cycle(option, step)
	_refresh()


func _refresh() -> void:
	for opt in value_labels:
		value_labels[opt].text = str(Content.get_entry("cosmetics", GameState.customization[opt]).name).get_slice(": ", 1)
	if preview:
		preview.apply_customization()


func confirm() -> void:
	App.goto_scene(App.SCENE_GAME_ROOT)
