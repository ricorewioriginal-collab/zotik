class_name BountyBoard
extends Interactable
## Guild bounty board: opens the bounty menu. PLACEHOLDER.


static func create(entry: Dictionary) -> BountyBoard:
	var b := BountyBoard.new()
	b.name = entry.id
	b.prompt = "Kopfgeldtafel der Gilde"
	var mi := MeshInstance3D.new()
	mi.name = "PLACEHOLDER_bounty_board"
	var m := BoxMesh.new()
	m.size = Vector3(2.0, 1.6, 0.15)
	mi.mesh = m
	mi.position.y = 1.3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.4, 0.25)
	mi.material_override = mat
	b.add_child(mi)
	return b


func interact(_player: Node) -> void:
	var root := get_tree().get_first_node_in_group("game_root")
	if root:
		root.open_menu(root.bounty_menu)
	interacted.emit()
