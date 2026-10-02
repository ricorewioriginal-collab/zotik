class_name TravelPoint
extends Interactable
## Weltenstein: opens the world map for travel between worlds. PLACEHOLDER.


static func create(entry: Dictionary) -> TravelPoint:
	var t := TravelPoint.new()
	t.name = entry.id
	t.prompt = "Weltenstein – Weltkarte öffnen"
	var mi := MeshInstance3D.new()
	mi.name = "PLACEHOLDER_travel_stone"
	var m := PrismMesh.new()
	m.size = Vector3(1.2, 2.4, 1.2)
	mi.mesh = m
	mi.position.y = 1.2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.75, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.5, 0.4)
	mi.material_override = mat
	t.add_child(mi)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 2.4, 1.0)
	cs.shape = shape
	cs.position.y = 1.2
	sb.add_child(cs)
	t.add_child(sb)
	return t


func interact(_player: Node) -> void:
	var root := get_tree().get_first_node_in_group("game_root")
	if root:
		root.open_world_map()
	interacted.emit()
