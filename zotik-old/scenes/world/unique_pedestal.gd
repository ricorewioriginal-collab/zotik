class_name UniquePedestal
extends Interactable
## Pedestal for a unique reward (data/world.json "uniques"). Appears when
## requires_flag is set, grants the item exactly once, plays its cutscene and
## runs the "after" effects (e.g. travel home) when the cutscene ends.

var item_id := ""
var cfg := {}
var blade: MeshInstance3D


static func create(entry: Dictionary) -> UniquePedestal:
	var p := UniquePedestal.new()
	p.item_id = entry.id
	p.name = entry.id
	p.cfg = Content.world.uniques[entry.id]
	p.prompt = "%s an dich nehmen" % Content.item(entry.id).name
	var stone := MeshInstance3D.new()
	stone.name = "PLACEHOLDER_pedestal"
	var m := CylinderMesh.new()
	m.top_radius = 0.7
	m.bottom_radius = 0.9
	m.height = 0.8
	stone.mesh = m
	stone.position.y = 0.4
	p.add_child(stone)
	p.blade = MeshInstance3D.new()
	p.blade.name = "PLACEHOLDER_world_blade"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 1.4, 0.04)
	p.blade.mesh = bm
	p.blade.position.y = 1.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.85, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.4, 1.0)
	p.blade.material_override = mat
	p.add_child(p.blade)
	return p


func _ready() -> void:
	EventBus.flag_changed.connect(func(_f, _v): _refresh())
	_refresh()


func available() -> bool:
	return GameState.has_flag(cfg.requires_flag) and not GameState.unique_rewards.has(item_id)


func _refresh() -> void:
	visible = GameState.has_flag(cfg.requires_flag)
	blade.visible = available()


func can_interact() -> bool:
	return super() and available() and not Dialogue.is_active()


func _process(delta: float) -> void:
	if blade.visible:
		blade.rotation.y += delta * 1.5


func interact(_player: Node) -> void:
	if not available():
		return
	Inventory.grant_unique(item_id)
	Inventory.equip(item_id)
	GameState.set_flag(cfg.sets_flag)
	_refresh()
	var cut: String = cfg.get("cutscene", "")
	var after: Array = cfg.get("after", [])
	interacted.emit()
	if cut != "":
		Dialogue.finished.connect(_on_cutscene_finished)
		Dialogue.play_cutscene(cut)
	else:
		Effects.run(after)


func _on_cutscene_finished(id: String) -> void:
	if id != cfg.get("cutscene", ""):
		return
	Dialogue.finished.disconnect(_on_cutscene_finished)
	Effects.run(cfg.get("after", []))
