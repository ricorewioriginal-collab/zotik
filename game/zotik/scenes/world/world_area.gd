class_name WorldArea
extends Node3D
## Builds one greybox area from data/layouts.json. Entities are created by
## factories supplied by the game root (type -> Callable(entry) -> Node3D).

signal exit_requested(target_area: String)

const WALL_HEIGHT := 5.0

var area_id := ""
var layout := {}
var exits := {}          # target -> {trigger, barrier, gate_flag}
var flag_props := []     # [{node, body, flag}]
var entities := {}       # spawn/id -> node
var skipped := []


func build(id: String, factories: Dictionary) -> void:
	area_id = id
	name = id
	layout = Content.layout(id)
	_environment()
	var size: Array = layout.get("size", [20, 20])
	var floors: Array = layout.get("floors", [{"pos": [0, -0.5, 0], "size": [size[0], 1, size[1]]}])
	for f in floors:
		_box("PLACEHOLDER_floor", _v(f.pos), _v(f.size), Color.html(layout.get("ground", "#555555")), true).add_to_group("ground")
	var hx: float = size[0] / 2.0
	var hz: float = size[1] / 2.0
	for w in [[Vector3(0, WALL_HEIGHT / 2, -hz), Vector3(size[0], WALL_HEIGHT, 1)], [Vector3(0, WALL_HEIGHT / 2, hz), Vector3(size[0], WALL_HEIGHT, 1)], [Vector3(-hx, WALL_HEIGHT / 2, 0), Vector3(1, WALL_HEIGHT, size[1])], [Vector3(hx, WALL_HEIGHT / 2, 0), Vector3(1, WALL_HEIGHT, size[1])]]:
		_collider(w[0], w[1])
	for p in layout.get("props", []):
		var node := _box("PLACEHOLDER_" + str(p.name), _v(p.pos), _v(p.size), Color.html(p.color), p.get("collision", true))
		if p.has("requires_flag"):
			flag_props.append({"node": node, "flag": p.requires_flag})
	for x in layout.get("exits", []):
		_exit(x)
	for en in layout.get("entities", []):
		var f: Callable = factories.get(en.type, Callable())
		if not f.is_valid():
			skipped.append(en)
			continue
		var node: Node3D = f.call(en)
		if node == null:
			continue
		add_child(node)
		node.position = _v(en.pos)
		entities[en.get("spawn", en.get("id", ""))] = node
	EventBus.flag_changed.connect(_on_flag_changed)
	refresh_gates()


func spawn_point(key: String) -> Vector3:
	var s: Dictionary = layout.get("spawns", {})
	return _v(s.get(key, s.get("default", [0, 0, 0])))


func is_exit_open(target: String) -> bool:
	var flag: String = Content.get_entry("areas", area_id).get("gate", {}).get(target, "")
	return flag == "" or GameState.has_flag(flag)


func refresh_gates() -> void:
	for target in exits:
		var open := is_exit_open(target)
		var b: StaticBody3D = exits[target].barrier
		b.visible = not open
		b.process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHERIT
		(b.get_child(0) as CollisionShape3D).disabled = open
	for fp in flag_props:
		var on := GameState.has_flag(fp.flag)
		fp.node.visible = on
		for c in fp.node.find_children("*", "CollisionShape3D", true, false):
			c.disabled = not on


func _on_flag_changed(_id: String, _v2: bool) -> void:
	refresh_gates()


func _exit(x: Dictionary) -> void:
	var trig := Area3D.new()
	trig.name = "Exit_" + str(x.to)
	trig.position = _v(x.pos) + Vector3(0, 1.5, 0)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5, 3, 1.5)
	cs.shape = shape
	trig.add_child(cs)
	add_child(trig)
	trig.body_entered.connect(_on_exit_body.bind(str(x.to)))
	var marker := _box("PLACEHOLDER_exit_marker", _v(x.pos) + Vector3(0, 0.02, 0), Vector3(5, 0.04, 1.5), Color(1, 0.9, 0.5), false)
	marker.name = "ExitMarker_" + str(x.to)
	var barrier := _box("PLACEHOLDER_barrier", _v(x.pos) + Vector3(0, 1.5, 0.9 * (1 if x.pos[2] < 0 else -1)), Vector3(5, 3, 0.4), Color(0.55, 0.3, 0.7, 0.8), true)
	barrier.name = "Barrier_" + str(x.to)
	exits[x.to] = {"trigger": trig, "barrier": barrier}


func _on_exit_body(body: Node, target: String) -> void:
	if not body.is_in_group("player"):
		return
	if is_exit_open(target):
		exit_requested.emit(target)
	else:
		EventBus.notify.emit("Der Weg ist versperrt.")


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.html(layout.get("ambient", "#ffffff"))
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 0.9
	add_child(sun)


func _box(nm: String, pos: Vector3, size: Vector3, color: Color, collide: bool) -> Node3D:
	var root: Node3D = StaticBody3D.new() if collide else Node3D.new()
	root.name = nm
	root.position = pos
	if collide:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		root.add_child(cs)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	root.add_child(mi)
	add_child(root)
	return root


func _collider(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "Boundary"
	body.position = pos
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


static func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
