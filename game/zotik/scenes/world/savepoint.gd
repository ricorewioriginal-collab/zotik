class_name Savepoint
extends Interactable
## Weltenanker savepoint: full heal, savepoint event, opens the save menu.

var savepoint_id := ""


static func create(entry: Dictionary) -> Savepoint:
	var s := Savepoint.new()
	s.savepoint_id = entry.id
	s.name = entry.id
	s.prompt = "%s berühren" % Content.savepoint(entry.id).get("name", "Speicherpunkt")
	var mi := MeshInstance3D.new()
	mi.name = "PLACEHOLDER_savepoint"
	var m := CylinderMesh.new()
	m.top_radius = 0.2
	m.bottom_radius = 0.6
	m.height = 2.4
	mi.mesh = m
	mi.position.y = 1.2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.85, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 1.0)
	mi.material_override = mat
	s.add_child(mi)
	return s


func interact(player: Node) -> void:
	if Content.savepoint(savepoint_id).get("heals", false) and player.has_method("revive_full"):
		player.revive_full()
	EventBus.savepoint_used.emit(savepoint_id)
	var root := get_tree().get_first_node_in_group("game_root")
	if root:
		root.open_save_menu()
	interacted.emit()
