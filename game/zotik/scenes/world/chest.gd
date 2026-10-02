class_name Chest
extends Interactable
## Persistent chest (PLACEHOLDER box). Opens once per save.

var chest_id := ""
var lid: MeshInstance3D


static func create(entry: Dictionary) -> Chest:
	var c := Chest.new()
	c.chest_id = entry.id
	c.name = entry.id
	c.prompt = "Truhe öffnen"
	var base := MeshInstance3D.new()
	base.name = "PLACEHOLDER_chest"
	var m := BoxMesh.new()
	m.size = Vector3(1.0, 0.6, 0.7)
	base.mesh = m
	base.position.y = 0.3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.35, 0.15)
	base.material_override = mat
	c.add_child(base)
	c.lid = MeshInstance3D.new()
	c.lid.name = "PLACEHOLDER_chest_lid"
	var lm := BoxMesh.new()
	lm.size = Vector3(1.05, 0.15, 0.75)
	c.lid.mesh = lm
	c.lid.position.y = 0.68
	c.lid.material_override = mat
	c.add_child(c.lid)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 0.8, 0.7)
	cs.shape = shape
	cs.position.y = 0.4
	sb.add_child(cs)
	c.add_child(sb)
	return c


func _ready() -> void:
	_refresh()


func is_open() -> bool:
	return GameState.chests_opened.has(chest_id)


func can_interact() -> bool:
	return super() and not is_open()


func interact(_player: Node) -> void:
	if is_open():
		return
	var data := Content.get_entry("chests", chest_id)
	var got := []
	for c in data.get("contents", []):
		var n := Inventory.add(c.id, int(c.count))
		if n > 0:
			got.append("%dx %s" % [n, Content.item(c.id).name])
	if int(data.get("currency", 0)) > 0:
		Inventory.add_currency(int(data.currency))
		got.append("%d Lun" % int(data.currency))
	GameState.chests_opened[chest_id] = true
	EventBus.chest_opened.emit(chest_id)
	EventBus.notify.emit("Erhalten: " + ", ".join(got))
	_refresh()
	interacted.emit()


func _refresh() -> void:
	lid.rotation_degrees.x = -70.0 if is_open() else 0.0
	lid.position.z = 0.3 if is_open() else 0.0
