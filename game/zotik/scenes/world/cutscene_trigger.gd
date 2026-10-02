class_name CutsceneTrigger
extends Area3D
## Plays a cutscene once when the player enters (once_flag persists it).

var cutscene_id := ""
var once_flag := ""


static func create(entry: Dictionary) -> CutsceneTrigger:
	var t := CutsceneTrigger.new()
	t.name = entry.id
	t.cutscene_id = entry.cutscene
	t.once_flag = entry.once_flag
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = WorldArea._v(entry.get("size", [4, 3, 4]))
	cs.shape = shape
	t.add_child(cs)
	t.body_entered.connect(t._on_body)
	return t


func _on_body(body: Node) -> void:
	if not body.is_in_group("player") or GameState.has_flag(once_flag):
		return
	GameState.set_flag(once_flag)
	EventBus.cutscene_requested.emit(cutscene_id)
