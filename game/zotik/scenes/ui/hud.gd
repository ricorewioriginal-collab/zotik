class_name Hud
extends Control
## In-game HUD (U01 look): character frame with portrait, HP and Lun (top
## left), minimap, area name and quest box (top right), boss bar (top
## centre), interaction prompt and menu icon bar (bottom centre), short
## notifications and the optional keyboard help.

## [action, label, icon kind, key hint]
## painted portraits cut from the owner's party poster (concept art, interim)
const PORTRAITS := {"zotik": "res://assets/ui/portraits/zotik.png", "PARTY_LYRA_001": "res://assets/ui/portraits/lyra.png", "PARTY_NIA_001": "res://assets/ui/portraits/nia.png", "PARTY_ROVAN_001": "res://assets/ui/portraits/rovan.png"}
const ROLES := {"PARTY_LYRA_001": "Lichtmagierin", "PARTY_NIA_001": "Bogenjägerin", "PARTY_ROVAN_001": "Wächter"}
const MENU_ICONS := [["inventory", "Inventar", "bag", "I"], ["quest_log", "Quests", "scroll", "L"], ["bestiary", "Bestiarium", "book", "B"]]

var game: Node
var hp_bar: ProgressBar
var hp_label: Label
var lun_label: Label
var area_label: Label
var objective_label: Label
var quest_box: PanelContainer
var prompt_label: Label
var prompt_box: PanelContainer
var notify_label: Label
var boss_label: Label
var boss_bar: ProgressBar
var boss_box: Control
var gear: IconButton  # top-left tile: help and settings
var touch_mode := false  # icon bar moves to the top while touch controls are shown
var hurt_flash: ColorRect
var minimap: Minimap
var icon_bar: HBoxContainer
var portrait: TextureRect
var party_box: VBoxContainer
var _party_ids: Array = []
var _notify_time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_character_frame()
	_build_top_right()
	_build_boss_bar()
	_build_bottom()
	notify_label = _label(24)
	notify_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	notify_label.offset_top = 230
	notify_label.offset_bottom = 270
	notify_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notify_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.7))
	gear = IconButton.create_tile("menu", "gear", "Hilfe & Einstellungen (Esc / F1)")
	gear.position = Vector2(16, 132)
	add_child(gear)
	hurt_flash = ColorRect.new()
	hurt_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hurt_flash.color = Color(0.9, 0.1, 0.1, 0.0)
	hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hurt_flash)
	EventBus.notify.connect(show_notification)


# --- layout ---------------------------------------------------------------

func _build_character_frame() -> void:
	var frame := Panel.new()
	frame.name = "CharacterFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = Vector2(16, 14)
	frame.size = Vector2(340, 104)
	add_child(frame)
	var ring := Panel.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.position = Vector2(10, 10)
	ring.size = Vector2(84, 84)
	ring.add_theme_stylebox_override("panel", UiStyle.frame(UiStyle.GOLD, Color(0.12, 0.2, 0.35), 42, 3))
	frame.add_child(ring)
	portrait = TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.position = Vector2(4, 4)
	portrait.size = Vector2(76, 76)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.material = _circle_mask()
	ring.add_child(portrait)
	var name_l := UiStyle.title("Zotik", 22)
	name_l.position = Vector2(106, 8)
	frame.add_child(name_l)
	lun_label = _label(16, frame)
	lun_label.position = Vector2(230, 12)
	lun_label.size = Vector2(98, 24)
	lun_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lun_label.add_theme_color_override("font_color", UiStyle.GOLD)
	var hp_tag := _label(14, frame)
	hp_tag.text = "HP"
	hp_tag.position = Vector2(106, 46)
	hp_tag.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	hp_bar = ProgressBar.new()
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.style_bar(hp_bar, Color(0.25, 0.8, 0.4))
	hp_bar.position = Vector2(134, 48)
	hp_bar.size = Vector2(192, 18)
	frame.add_child(hp_bar)
	hp_label = _label(14, frame)
	hp_label.position = Vector2(134, 70)
	hp_label.size = Vector2(192, 20)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	area_label = _label(14, frame)  # kept for tests/older code; area name shows under the minimap
	area_label.visible = false
	portrait.texture = load(PORTRAITS.zotik)
	party_box = VBoxContainer.new()
	party_box.name = "Party"
	party_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	party_box.position = Vector2(16, 126)
	party_box.add_theme_constant_override("separation", 6)
	add_child(party_box)


func _build_top_right() -> void:
	var col := VBoxContainer.new()
	col.name = "TopRight"
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	col.offset_left = -316
	col.offset_right = -16
	col.offset_top = 14
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(col)
	minimap = Minimap.new()
	minimap.hud = self
	minimap.custom_minimum_size = Vector2(170, 170)
	minimap.size_flags_horizontal = Control.SIZE_SHRINK_END
	col.add_child(minimap)
	var area_title := UiStyle.title("", 20)
	area_title.name = "AreaTitle"
	area_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(area_title)
	quest_box = PanelContainer.new()
	quest_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_box.add_theme_stylebox_override("panel", UiStyle.frame(UiStyle.GOLD_DARK, Color(0.04, 0.07, 0.15, 0.78), 8, 1))
	col.add_child(quest_box)
	var qv := VBoxContainer.new()
	quest_box.add_child(qv)
	qv.add_child(UiStyle.title("Aktuelles Ziel", 16))
	objective_label = _label(16, qv)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	objective_label.custom_minimum_size = Vector2(276, 0)


func _build_boss_bar() -> void:
	boss_box = Panel.new()
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boss_box.offset_left = -290
	boss_box.offset_right = 290
	boss_box.offset_top = 14
	boss_box.offset_bottom = 84
	boss_box.add_theme_stylebox_override("panel", UiStyle.frame(Color(0.8, 0.45, 1.0), Color(0.06, 0.03, 0.12, 0.85), 12, 2))
	add_child(boss_box)
	boss_label = UiStyle.title("", 20, Color(0.95, 0.85, 1.0))
	boss_label.position = Vector2(0, 6)
	boss_label.size = Vector2(580, 28)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(boss_label)
	boss_bar = ProgressBar.new()
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.style_bar(boss_bar, Color(0.7, 0.3, 0.95))
	boss_bar.position = Vector2(24, 40)
	boss_bar.size = Vector2(532, 18)
	boss_box.add_child(boss_bar)
	boss_box.visible = false


func _build_bottom() -> void:
	icon_bar = HBoxContainer.new()
	icon_bar.name = "IconBar"
	icon_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	icon_bar.offset_left = -200
	icon_bar.offset_right = 200
	icon_bar.offset_top = -98
	icon_bar.offset_bottom = -12
	icon_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	icon_bar.add_theme_constant_override("separation", 10)
	add_child(icon_bar)
	for m in MENU_ICONS:
		var b := IconButton.create(m[0], m[1], m[2], m[3])
		icon_bar.add_child(b)
	prompt_box = PanelContainer.new()
	prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_box.offset_left = -220
	prompt_box.offset_right = 220
	prompt_box.offset_top = -160
	prompt_box.offset_bottom = -112
	prompt_box.add_theme_stylebox_override("panel", UiStyle.frame(UiStyle.CRYSTAL, Color(0.04, 0.08, 0.16, 0.85), 22, 2))
	add_child(prompt_box)
	prompt_label = _label(18, prompt_box)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_box.visible = false


func _process(delta: float) -> void:
	var hp := int(GameState.player.get("hp", 0))
	var mx := maxi(1, int(GameState.player.get("max_hp", 1)))
	hp_bar.max_value = mx
	hp_bar.value = hp
	(hp_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.25, 0.8, 0.4) if hp * 3 > mx else Color(0.9, 0.25, 0.2)
	hp_label.text = "%d / %d" % [hp, mx]
	lun_label.text = "%d Lun" % GameState.currency
	area_label.text = str(Content.get_entry("areas", GameState.player.get("area", "")).get("name", ""))
	(find_child("AreaTitle", true, false) as Label).text = area_label.text
	var boss: Boss = null
	for n in get_tree().get_nodes_in_group("enemy"):
		if n is Boss and n.engaged():
			boss = n
	boss_bar.visible = boss != null
	boss_label.visible = boss != null
	boss_box.visible = boss != null
	if boss:
		boss_label.text = "%s – %s" % [boss.data.name, boss.data.phases[boss.phase].name]
		boss_bar.max_value = boss.max_hp
		boss_bar.value = boss.hp
	quest_box.visible = objective_label.text != ""
	var busy: bool = Dialogue.is_active()
	_sync_party()
	icon_bar.visible = not busy
	_place_icon_bar()
	prompt_box.visible = prompt_label.text != "" and not busy
	hurt_flash.color.a = maxf(0.0, hurt_flash.color.a - delta * 1.2)
	gear.visible = not busy
	gear.position = Vector2(16, _below_party())
	if _notify_time > 0.0:
		_notify_time -= delta
		if _notify_time <= 0.0:
			notify_label.text = ""


## Bottom centre with keyboard/mouse; top left under the character frame in
## touch mode (the bottom corners belong to the stick and action buttons).
func _place_icon_bar() -> void:
	if touch_mode:
		icon_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
		icon_bar.offset_left = 90
		icon_bar.offset_right = 490
		icon_bar.offset_top = _below_party()
		icon_bar.offset_bottom = icon_bar.offset_top + 86
		icon_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	else:
		icon_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		icon_bar.offset_left = -200
		icon_bar.offset_right = 200
		icon_bar.offset_top = -98
		icon_bar.offset_bottom = -12
		icon_bar.alignment = BoxContainer.ALIGNMENT_CENTER


func _below_party() -> float:
	return 126.0 + _party_ids.size() * 68.0 + 4.0


## True if a screen position lies on a HUD button (touch controls ignore it).
func is_ui_at(pos: Vector2) -> bool:
	return (icon_bar.visible and icon_bar.get_global_rect().has_point(pos)) or (gear.visible and gear.get_global_rect().has_point(pos))


func flash_hurt() -> void:
	hurt_flash.color.a = 0.35


func set_prompt(target: Interactable) -> void:
	prompt_label.text = ("[Enter]  " if not touch_mode else "") + target.prompt if target else ""


func set_objective(text: String) -> void:
	objective_label.text = text


func show_notification(text: String) -> void:
	notify_label.text = text
	_notify_time = 2.5 + text.length() * 0.03


# --- helpers ----------------------------------------------------------------

func _label(size: int, parent: Node = null) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	(parent if parent else self).add_child(l)
	return l


static func _circle_mask() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat d = distance(UV, vec2(0.5));\n\tc.a *= 1.0 - smoothstep(0.47, 0.5, d);\n\tCOLOR = c;\n}\n"
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


## One small frame per companion: painted portrait, name, role, HP (k.o. at
## zero) and a thin readiness bar (time until the next attack / spell).
func _sync_party() -> void:
	var ids: Array = Array(GameState.party)
	if ids != _party_ids:
		_party_ids = ids
		for c in party_box.get_children():
			c.queue_free()
		for id in ids:
			party_box.add_child(_party_frame(id))
	if game == null:
		return
	for f in party_box.get_children():
		var comp = game.companions.get(f.get_meta("id"))
		if comp == null or not is_instance_valid(comp):
			continue
		var bar: ProgressBar = f.get_meta("bar")
		var hpb: ProgressBar = f.get_meta("hp_bar")
		var cd := float(comp.data.get("attack_cooldown", 1.0))
		bar.value = 0.0 if comp.dead else 1.0 - clampf(comp.attack_cd / maxf(cd, 0.01), 0.0, 1.0)
		hpb.max_value = comp.max_hp()
		hpb.value = comp.hp()
		(hpb.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.25, 0.8, 0.4) if comp.hp() * 3 > comp.max_hp() else Color(0.9, 0.25, 0.2)
		(f.get_meta("hp_label") as Label).text = "k.o." if comp.dead else "%d / %d" % [comp.hp(), comp.max_hp()]
		f.modulate = Color(0.6, 0.6, 0.65) if comp.dead else Color.WHITE


func _party_frame(id: String) -> Panel:
	var f := Panel.new()
	f.set_meta("id", id)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.custom_minimum_size = Vector2(250, 62)
	f.add_theme_stylebox_override("panel", UiStyle.frame(UiStyle.GOLD_DARK, Color(0.04, 0.07, 0.15, 0.82), 8, 1))
	var pic := TextureRect.new()
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.position = Vector2(6, 6)
	pic.size = Vector2(44, 44)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.material = _circle_mask()
	if PORTRAITS.has(id):
		pic.texture = load(PORTRAITS[id])
	f.add_child(pic)
	var n := UiStyle.title(str(Content.get_entry("party", id).get("name", id)), 16)
	n.position = Vector2(58, 2)
	f.add_child(n)
	var role := _label(12, f)
	role.text = ROLES.get(id, "")
	role.position = Vector2(150, 6)
	role.size = Vector2(92, 18)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	role.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	var hpb := ProgressBar.new()
	hpb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.style_bar(hpb, Color(0.25, 0.8, 0.4))
	hpb.position = Vector2(58, 28)
	hpb.size = Vector2(120, 12)
	f.add_child(hpb)
	f.set_meta("hp_bar", hpb)
	var hpl := _label(12, f)
	hpl.position = Vector2(182, 25)
	hpl.size = Vector2(62, 16)
	hpl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	f.set_meta("hp_label", hpl)
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.style_bar(bar, Color(0.3, 0.6, 1.0))
	bar.position = Vector2(58, 45)
	bar.size = Vector2(184, 6)
	bar.max_value = 1.0
	bar.value = 1.0
	f.add_child(bar)
	f.set_meta("bar", bar)
	return f
