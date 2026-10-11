class_name CasinoEntrance
extends Interactable
## Entrance of the Golden Star Casino. Closed when the family option is off.


static func create(entry: Dictionary) -> CasinoEntrance:
	var c := CasinoEntrance.new()
	c.name = entry.id
	var mi := MeshInstance3D.new()
	mi.name = "PLACEHOLDER_casino_sign"
	var m := BoxMesh.new()
	m.size = Vector3(2.4, 1.2, 0.2)
	mi.mesh = m
	mi.position.y = 1.6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.75, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.45, 0.1)
	mi.material_override = mat
	c.add_child(mi)
	return c


func can_interact() -> bool:
	prompt = "Golden Star Casino (nur virtuelle Lun)" if Casino.enabled() else "Casino geschlossen (Familienoption)"
	return super() and Casino.enabled() and not Dialogue.is_active()


func interact(_player: Node) -> void:
	if not Casino.enabled():
		return
	EventBus.menu_requested.emit("casino")
	interacted.emit()
