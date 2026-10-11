class_name LoreBook
extends Interactable
## Readable lore (data/lore.json) shown through the dialogue box. PLACEHOLDER.

var lore_id := ""


static func create(entry: Dictionary) -> LoreBook:
	var b := LoreBook.new()
	b.lore_id = entry.id
	b.name = entry.id
	b.prompt = "Lesen: " + str(Content.get_entry("lore", entry.id).get("title", "Buch"))
	var mi := MeshInstance3D.new()
	mi.name = "PLACEHOLDER_lectern"
	var m := BoxMesh.new()
	m.size = Vector3(0.8, 1.1, 0.6)
	mi.mesh = m
	mi.position.y = 0.55
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.3, 0.2)
	mi.material_override = mat
	b.add_child(mi)
	return b


func can_interact() -> bool:
	return super() and not Dialogue.is_active()


func interact(_player: Node) -> void:
	Dialogue.read_lore(lore_id)
	interacted.emit()
