class_name Npc
extends Interactable
## Talkable NPC (interim animated CC0 human, styled per NPC, + name).
## Visibility follows appears_when.

const COLORS := {"NPC_MIRA_001": "#d9a066", "NPC_TOREN_001": "#8a6f5a", "NPC_BORO_001": "#c9a227", "NPC_ELWEN_001": "#9a9ab0", "NPC_FINN_001": "#6fa86f", "NPC_SARI_001": "#c46a8a", "NPC_PROFESSORIUM_001": "#b0b0b0", "NPC_LYRA_001": "#6a8ad9", "NPC_MARA_001": "#8aa0b8", "NPC_ELIO_001": "#b8803a", "NPC_SELA_001": "#a0c070", "NPC_NIA_001": "#d9a03a", "NPC_ROVAN_001": "#7a6a5a", "NPC_HALDOR_001": "#6a6a6a", "NPC_YSME_001": "#8a5ab0", "NPC_LOTTE_001": "#3a7ab0", "NPC_VEYR_001": "#7a3a2a", "NPC_TIBOR_001": "#5a7a7a", "NPC_KASIMIR_001": "#b05a2a"}

## interim look per NPC (C01, CC0 Quaternius humans): [spec, height]
const LOOKS := {
	"NPC_MIRA_001": [{"outfit": "Female_Peasant", "body": "Female", "hair": "Hair_Long", "hair_color": Color(0.3, 0.18, 0.12), "tint": Color(0.88, 0.82, 1.0)}, 1.68],
	"NPC_TOREN_001": [{"outfit": "Male_Ranger", "body": "Male", "hair": "Hair_Buzzed", "hide": ["Male_Ranger_Head_Hood"], "right": "sword"}, 1.82],
	"NPC_BORO_001": [{"outfit": "Male_Peasant", "body": "Male", "hair": "Hair_Buzzed", "beard": true, "hair_color": Color(0.35, 0.22, 0.12), "tint": Color(1.0, 0.92, 0.75)}, 1.8],
	"NPC_ELWEN_001": [{"outfit": "Male_Peasant", "body": "Male", "hair": "Hair_SimpleParted", "beard": true, "hair_color": Color(0.92, 0.92, 0.9), "tint": Color(0.8, 0.85, 1.0), "right": "staff"}, 1.7],
	"NPC_FINN_001": [{"outfit": "Male_Peasant", "body": "Male", "hair": "Hair_SimpleParted", "hair_color": Color(0.75, 0.5, 0.25)}, 1.35],
	"NPC_SARI_001": [{"outfit": "Female_Peasant", "body": "Female", "hair": "Hair_Buns", "hair_color": Color(0.7, 0.3, 0.15), "tint": Color(1.0, 0.85, 0.85)}, 1.66],
	"NPC_PROFESSORIUM_001": [{"outfit": "Male_Peasant", "body": "Male", "hair": "Hair_SimpleParted", "beard": true, "hair_color": Color(0.95, 0.95, 0.95), "tint": Color(0.85, 0.8, 0.65)}, 1.74],
	"NPC_LYRA_001": [{"outfit": "Female_Peasant", "body": "Female", "hair": "Hair_Long", "hair_color": Color(0.35, 0.6, 1.0), "tint": Color(0.78, 0.82, 1.0), "right": "staff"}, 1.72],
	"NPC_MARA_001": [{"outfit": "Female_Peasant", "body": "Female", "hair": "Hair_Long", "hair_color": Color(0.55, 0.5, 0.45), "tint": Color(0.82, 1.0, 0.85)}, 1.7],
	"NPC_ELIO_001": [{"outfit": "Male_Ranger", "body": "Male", "hair": "Hair_Buzzed"}, 1.78],
	"NPC_SELA_001": [{"outfit": "Female_Ranger", "body": "Female", "hair": "Hair_Long", "hair_color": Color(0.85, 0.7, 0.4), "hide": ["Female_Ranger_Head_Hood"]}, 1.66],
	"NPC_NIA_001": [{"outfit": "Female_Ranger", "body": "Female", "hair": "Hair_Buns", "hair_color": Color(0.5, 0.34, 0.22), "hide": ["Female_Ranger_Head_Hood"], "right": "crossbow"}, 1.68],
	"NPC_ROVAN_001": [{"outfit": "Male_Ranger", "body": "Male", "hair": "Hair_SimpleParted", "beard": true, "hair_color": Color(0.22, 0.16, 0.11), "hide": ["Male_Ranger_Head_Hood"], "right": "axe", "left": "shield"}, 1.86],
	"NPC_HALDOR_001": [{"outfit": "Male_Peasant", "body": "Male", "hair": "Hair_Buzzed", "beard": true, "hair_color": Color(0.2, 0.15, 0.1), "tint": Color(0.82, 0.74, 0.66), "right": "sword"}, 1.86],
	"NPC_NURI_001": [{"outfit": "Female_Peasant", "body": "Female", "hair": "Hair_Long", "hair_color": Color(0.12, 0.08, 0.06), "tint": Color(1.0, 0.85, 0.6), "right": "staff"}, 1.72],
	"NPC_ZEYD_001": [{"outfit": "Male_Peasant", "body": "Male", "hair": "Hair_SimpleParted", "beard": true, "hair_color": Color(0.9, 0.9, 0.88), "tint": Color(0.95, 0.88, 0.7), "right": "staff"}, 1.68],
	"NPC_AMANI_001": [{"outfit": "Female_Peasant", "body": "Female", "hair": "Hair_Buns", "hair_color": Color(0.1, 0.07, 0.05), "tint": Color(0.85, 0.65, 0.5), "right": "sword"}, 1.74],
	"NPC_JABIR_001": [{"outfit": "Male_Peasant", "body": "Male", "hair": "Hair_Buzzed", "beard": true, "hair_color": Color(0.15, 0.1, 0.07), "tint": Color(0.7, 0.55, 0.85)}, 1.78],
	"NPC_YSME_001": [{"outfit": "Female_Peasant", "body": "Female", "hair": "Hair_Buns", "hair_color": Color(0.25, 0.18, 0.32), "tint": Color(0.88, 0.78, 1.0)}, 1.7],
	"NPC_LOTTE_001": [{"outfit": "Female_Ranger", "body": "Female", "hair": "Hair_Long", "hair_color": Color(0.2, 0.14, 0.1), "hide": ["Female_Ranger_Head_Hood"], "tint": Color(0.8, 0.9, 1.0)}, 1.7],
	"NPC_VEYR_001": [{"outfit": "Male_Ranger", "body": "Male", "beard": true, "hair_color": Color(0.3, 0.25, 0.2), "right": "sword"}, 1.86],
	"NPC_TIBOR_001": [{"outfit": "Male_Peasant", "body": "Male", "hair": "Hair_Buzzed", "beard": true, "hair_color": Color(0.6, 0.6, 0.58), "tint": Color(0.8, 0.88, 0.9)}, 1.76],
	"NPC_KASIMIR_001": [{"outfit": "Male_Ranger", "body": "Male", "hair": "Hair_Buzzed", "hide": ["Male_Ranger_Head_Hood"], "right": "sword", "left": "shield"}, 1.86],
}

var npc_id := ""


static func create(entry: Dictionary) -> Npc:
	var n := Npc.new()
	n.npc_id = entry.id
	n.name = entry.id
	n.prompt = "Sprechen mit " + str(Content.get_entry("npcs", entry.id).name)
	var look: Array = LOOKS.get(entry.id, [{"outfit": "Male_Peasant", "body": "Male", "hair": "Hair_Buzzed"}, 1.75])
	var rig := CharacterRig.create_human(look[0], float(look[1]))
	n.add_child(rig)
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
