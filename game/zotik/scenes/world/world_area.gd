class_name WorldArea
extends Node3D
## Builds one greybox area from data/layouts.json. Entities are created by
## factories supplied by the game root (type -> Callable(entry) -> Node3D).

signal exit_requested(target_area: String)

const WALL_HEIGHT := 5.0
## Exits ignore the player for this long after the area was built, so a
## stale position from the previous area can never chain a transition.
const EXIT_GRACE_MSEC := 250
## Random encounters (layout "roamers") are off in headless runs (tests) unless forced on.
static var roamers_force := false

var area_id := ""
var layout := {}
var exits := {}          # target -> {trigger, barrier, gate_flag}
var flag_props := []     # [{node, body, flag}]
var entities := {}       # spawn/id -> node
var skipped := []
var roamers := []        # random-encounter enemies (not part of `entities`)
var _built_msec := 0


func build(id: String, factories: Dictionary) -> void:
	area_id = id
	name = id
	_built_msec = Time.get_ticks_msec()
	layout = Content.layout(id)
	_environment()
	var size: Array = layout.get("size", [20, 20])
	var floors: Array = layout.get("floors", [{"pos": [0, -0.5, 0], "size": [size[0], 1, size[1]]}])
	var floor_tex := Look.floor_texture(area_id, layout)
	var floor_mat := Look.surface(floor_tex, Look.ground_tint(area_id, layout), Look.FLOOR_SCALE.get(floor_tex, 0.25))
	for f in floors:
		var fl := _box("PLACEHOLDER_floor", _v(f.pos), _v(f.size), Color.html(layout.get("ground", "#555555")), true)
		fl.add_to_group("ground")
		(fl.get_child(1) as MeshInstance3D).material_override = floor_mat
	var hx: float = size[0] / 2.0
	var hz: float = size[1] / 2.0
	for w in [[Vector3(0, WALL_HEIGHT / 2, -hz), Vector3(size[0], WALL_HEIGHT, 1)], [Vector3(0, WALL_HEIGHT / 2, hz), Vector3(size[0], WALL_HEIGHT, 1)], [Vector3(-hx, WALL_HEIGHT / 2, 0), Vector3(1, WALL_HEIGHT, size[1])], [Vector3(hx, WALL_HEIGHT / 2, 0), Vector3(1, WALL_HEIGHT, size[1])]]:
		_collider(w[0], w[1])
	Look.build_boundary(self, area_id, layout, Vector2(size[0], size[1]), WALL_HEIGHT)
	Look.build_backdrop(self, area_id, layout, Vector2(size[0], size[1]))
	Look.build_sky_features(self, area_id, layout, Vector2(size[0], size[1]))
	Look.build_flora(self, area_id, layout, Vector2(size[0], size[1]))
	Look.build_dressing(self, area_id, layout)
	Look.build_weather(self, area_id, layout, Vector2(size[0], size[1]))
	Look.build_decor(self, layout, area_id)
	for p in layout.get("props", []):
		var node := _prop("PLACEHOLDER_" + str(p.name), str(p.name), _v(p.pos), _v(p.size), Color.html(p.color), p.get("collision", true))
		if p.has("requires_flag"):
			flag_props.append({"node": node, "flag": p.requires_flag, "invert": false})
		elif p.has("hidden_by_flag"):
			flag_props.append({"node": node, "flag": p.hidden_by_flag, "invert": true})
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
	_spawn_roamers(factories)
	EventBus.flag_changed.connect(_on_flag_changed)
	refresh_gates()


## Random encounters: a few non-persistent wanderers from the layout's pool, placed on free ground
## away from the entries, exits, props and the fixed enemies. New each time the area is built.
func _spawn_roamers(factories: Dictionary) -> void:
	var cfg: Dictionary = layout.get("roamers", {})
	var make: Callable = factories.get("enemy", Callable())
	if cfg.is_empty() or not make.is_valid():
		return
	if DisplayServer.get_name() == "headless" and not roamers_force:
		return
	var size: Array = layout.get("size", [20, 20])
	var blocked := Look._blocked_rects(layout)
	var keep_out: Array[Vector2] = []
	for k in layout.get("spawns", {}):
		var sp := spawn_point(k)
		keep_out.append(Vector2(sp.x, sp.z))
	for x in layout.get("exits", []):
		keep_out.append(Vector2(float(x.pos[0]), float(x.pos[2])))
	for en in layout.get("entities", []):
		if en.type != "puzzle" and en.type != "savepoint" and en.type != "chest":
			continue
		keep_out.append(Vector2(float(en.pos[0]), float(en.pos[2])))
	var pool: Array = cfg.pool
	var n := 0
	for i in int(cfg.get("count", 2)):
		for attempt in 30:
			var p := Vector2(randf_range(-size[0] / 2.0 + 5.0, size[0] / 2.0 - 5.0), randf_range(-size[1] / 2.0 + 5.0, size[1] / 2.0 - 5.0))
			if not _roamer_spot_ok(p, blocked, keep_out):
				continue
			var e = make.call({"enemy": pool[randi() % pool.size()], "spawn": "SPAWN_ROAM_%d" % n, "pos": [p.x, 0, p.y]})
			if e == null:
				break
			e.roam = float(cfg.get("radius", 7.0))
			e.position = Vector3(p.x, 0, p.y)
			add_child(e)
			roamers.append(e)
			n += 1
			break


func _roamer_spot_ok(p: Vector2, blocked: Array[Rect2], keep_out: Array[Vector2]) -> bool:
	for r in blocked:
		if r.grow(1.5).has_point(p):
			return false
	for k in keep_out:
		if k.distance_squared_to(p) < 100.0:
			return false
	var floors: Array = layout.get("floors", [])
	if not floors.is_empty():
		var on_floor := false
		for f in floors:
			if absf(p.x - float(f.pos[0])) < float(f.size[0]) / 2.0 - 2.0 and absf(p.y - float(f.pos[2])) < float(f.size[2]) / 2.0 - 2.0:
				on_floor = true
				break
		if not on_floor:
			return false
	for e in roamers:
		if Vector2(e.position.x, e.position.z).distance_squared_to(p) < 36.0:
			return false
	return true


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
		var on: bool = GameState.has_flag(fp.flag) != fp.invert
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
	if not body.is_in_group("player") or Time.get_ticks_msec() - _built_msec < EXIT_GRACE_MSEC:
		return
	if is_exit_open(target):
		exit_requested.emit(target)
	else:
		EventBus.notify.emit("Der Weg ist versperrt.")


func _environment() -> void:
	Look.build_environment(self, area_id, layout)


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


## Layout prop: collision box as defined, visible shape from Look.
func _prop(nm: String, prop_name: String, pos: Vector3, size: Vector3, color: Color, collide: bool) -> Node3D:
	var root: Node3D = StaticBody3D.new() if collide else Node3D.new()
	root.name = nm
	root.position = pos
	if collide:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		root.add_child(cs)
	Look.build_prop(root, prop_name, size, color, Look.style(area_id))
	add_child(root)
	return root


func _collider(pos: Vector3, size: Vector3) -> void:
	var body := _box("PLACEHOLDER_boundary", pos, size, Color.html(layout.get("ground", "#555555")).darkened(0.45), true)
	body.name = "BoundaryCollider"
	body.get_child(1).visible = false  # the visible border comes from Look.build_boundary


static func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
