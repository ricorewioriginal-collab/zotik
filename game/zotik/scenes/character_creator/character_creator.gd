extends Control
## "Mein Zotik" character creator with live 3D preview. Cosmetic only.

const LABELS := {"fur_shade": "Fellton", "scarf": "Schal", "outfit": "Kleidung"}

var preview: ZotikVisual
var value_labels := {}
var confirm_button: Button


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
	vpc.custom_minimum_size = Vector2(520, 640)
	row.add_child(vpc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vpc.add_child(vp)
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
	preview = ZotikVisual.new()
	preview.rotation.y = PI  # face the preview camera
	vp.add_child(preview)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.75, 2.3)
	vp.add_child(cam)
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
	_refresh()
	confirm_button.grab_focus.call_deferred()


func _process(delta: float) -> void:
	preview.rotation.y += delta * 0.6


func change(option: String, step: int) -> void:
	Customization.cycle(option, step)
	_refresh()


func _refresh() -> void:
	for opt in value_labels:
		value_labels[opt].text = str(Content.get_entry("cosmetics", GameState.customization[opt]).name).get_slice(": ", 1)
	preview.apply_customization()


func confirm() -> void:
	App.goto_scene(App.SCENE_GAME_ROOT)
