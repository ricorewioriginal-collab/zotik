class_name PuzzleNode
extends Node3D
## In-world puzzle: dials + activation plate, or a row of resonance
## crystals. puzzle_reset / puzzle_hint work within RANGE. PLACEHOLDER visuals.

const RANGE := 9.0
const PHASE_COLORS := [Color(0.15, 0.15, 0.25), Color(0.55, 0.6, 0.8), Color(0.95, 0.95, 1.0), Color(0.6, 0.55, 0.8)]
const PHASE_NAMES := ["Neumond", "zunehmend", "Vollmond", "abnehmend"]

var puzzle_id := ""
var parts: Array[Interactable] = []
var meshes: Array[MeshInstance3D] = []


static func create(entry: Dictionary) -> PuzzleNode:
	var p := PuzzleNode.new()
	p.puzzle_id = entry.id
	p.name = entry.id
	return p


func _ready() -> void:
	var d := PuzzleLogic.data(puzzle_id)
	var n := int(d.dial_count) if d.kind == "dials" else int(d.nodes)
	for i in n:
		var it := Interactable.new()
		it.name = "Part_%d" % i
		it.position = Vector3(-2.0 * (n - 1) / 2.0 + 2.0 * i, 0, 0)
		var labels: Array = d.get("node_labels", [])
		if d.kind == "dials":
			it.prompt = "Mondscheibe drehen"
		elif i < labels.size():
			it.prompt = "Symbolsäule „%s“ aktivieren" % labels[i]
			var sym := Label3D.new()
			sym.text = labels[i]
			sym.font_size = 72
			sym.outline_size = 14
			sym.position.y = 2.2
			sym.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			it.add_child(sym)
		else:
			it.prompt = "Kristall %d anschlagen" % (i + 1)
		it.interacted.connect(_on_part.bind(i))
		add_child(it)
		parts.append(it)
		var mi := MeshInstance3D.new()
		mi.name = "PLACEHOLDER_puzzle_part"
		var m: Mesh = CylinderMesh.new() if d.kind == "dials" else PrismMesh.new()
		mi.mesh = m
		mi.position.y = 1.0
		mi.material_override = StandardMaterial3D.new()
		it.add_child(mi)
		meshes.append(mi)
	if d.kind == "dials":
		var plate := Interactable.new()
		plate.name = "Activate"
		plate.position = Vector3(0, 0, 2.5)
		plate.prompt = "Mondtor aktivieren"
		plate.interacted.connect(func(): PuzzleLogic.submit(puzzle_id); refresh())
		add_child(plate)
		var pm := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.5, 0.1, 1.5)
		pm.mesh = box
		plate.add_child(pm)
		parts.append(plate)
	EventBus.puzzle_solved.connect(func(_id): refresh())
	refresh()


func _on_part(i: int) -> void:
	if PuzzleLogic.data(puzzle_id).kind == "dials":
		PuzzleLogic.rotate(puzzle_id, i)
		EventBus.notify.emit("Scheibe %d: %s" % [i + 1, PHASE_NAMES[int(PuzzleLogic.state(puzzle_id).current[i])]])
	else:
		PuzzleLogic.strike(puzzle_id, i)
	refresh()


func refresh() -> void:
	var d := PuzzleLogic.data(puzzle_id)
	var s := PuzzleLogic.state(puzzle_id)
	var solved: bool = s.state == "SOLVED"
	for p in parts:
		p.enabled = not solved
	for i in meshes.size():
		var mat := meshes[i].material_override as StandardMaterial3D
		if d.kind == "dials":
			mat.albedo_color = PHASE_COLORS[int(s.current[i])]
			meshes[i].rotation_degrees.y = 90.0 * int(s.current[i])
		else:
			mat.albedo_color = Color(0.5, 0.9, 1.0) if i in s.current else Color(0.25, 0.35, 0.6)


func player_in_range() -> bool:
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	return pl != null and pl.global_position.distance_to(global_position) <= RANGE


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range() or PuzzleLogic.is_solved(puzzle_id) or Dialogue.is_active():
		return
	if event.is_action_pressed("puzzle_reset"):
		PuzzleLogic.reset(puzzle_id)
		EventBus.notify.emit("%s zurückgesetzt." % PuzzleLogic.data(puzzle_id).name)
		refresh()
	elif event.is_action_pressed("puzzle_hint"):
		EventBus.notify.emit("Hinweis: " + PuzzleLogic.next_hint(puzzle_id))
