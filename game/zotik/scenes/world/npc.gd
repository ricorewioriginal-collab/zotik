class_name Npc
extends Interactable
## Talkable NPC (PLACEHOLDER capsule + name). Visibility follows appears_when.

const COLORS := {"NPC_MIRA_001": "#d9a066", "NPC_TOREN_001": "#8a6f5a", "NPC_BORO_001": "#c9a227", "NPC_ELWEN_001": "#9a9ab0", "NPC_FINN_001": "#6fa86f", "NPC_SARI_001": "#c46a8a", "NPC_PROFESSORIUM_001": "#b0b0b0", "NPC_LYRA_001": "#6a8ad9", "NPC_MARA_001": "#8aa0b8", "NPC_ELIO_001": "#b8803a", "NPC_SELA_001": "#a0c070", "NPC_NIA_001": "#d9a03a", "NPC_ROVAN_001": "#7a6a5a", "NPC_HALDOR_001": "#6a6a6a", "NPC_YSME_001": "#8a5ab0", "NPC_LOTTE_001": "#3a7ab0", "NPC_VEYR_001": "#7a3a2a", "NPC_TIBOR_001": "#5a7a7a"}

var npc_id := ""


static func create(entry: Dictionary) -> Npc:
	var n := Npc.new()
	n.npc_id = entry.id
	n.name = entry.id
	n.prompt = "Sprechen mit " + str(Content.get_entry("npcs", entry.id).name)
	var body := MeshInstance3D.new()
	body.name = "PLACEHOLDER_npc"
	var m := CapsuleMesh.new()
	m.radius = 0.35
	m.height = 1.8
	body.mesh = m
	body.position.y = 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.html(COLORS.get(entry.id, "#cccccc"))
	body.material_override = mat
	n.add_child(body)
	var label := Label3D.new()
	label.text = str(Content.get_entry("npcs", entry.id).name)
	label.position.y = 2.2
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	label.outline_size = 12
	label.fixed_size = true
	label.pixel_size = 0.0009
	n.add_child(label)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	cs.shape = shape
	cs.position.y = 0.9
	sb.add_child(cs)
	n.add_child(sb)
	return n


func _ready() -> void:
	EventBus.flag_changed.connect(func(_f, _v): _refresh())
	_refresh()


func _refresh() -> void:
	var npc := Content.get_entry("npcs", npc_id)
	var flag: String = npc.get("appears_when", "")
	var gone: String = npc.get("hidden_when", "")
	var present := (flag == "" or GameState.has_flag(flag)) and (gone == "" or not GameState.has_flag(gone))
	visible = present
	for c in find_children("*", "CollisionShape3D", true, false):
		c.disabled = not present


func can_interact() -> bool:
	return super() and not Dialogue.is_active()


func interact(_player: Node) -> void:
	Dialogue.talk_to(npc_id)
	interacted.emit()
