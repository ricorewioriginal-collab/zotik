class_name Look
extends RefCounted
## Visual style of the world (graphics pass G01): sky, light, fog and glow per
## world, CC0 surface textures (assets/textures, Poly Haven) and procedural
## shapes for houses, trees, water and crystals. Purely cosmetic: collision
## and node names stay as the layout defines them.

const TEX := "res://assets/textures/%s_%s.jpg"
const INDOOR_KEYS := ["CAVE", "DUNGEON", "CANALS", "CISTERN", "FLOODGATE", "HOME"]

## sky_top, sky_horizon, sun colour, sun energy, sun pitch, fog colour, floor texture, boundary kind
const WORLDS := {
	"WORLD_LUNARIS": {"sky_top": "#1d2b66", "sky_horizon": "#b49ad8", "sun": "#dfe6ff", "sun_energy": 1.0, "pitch": -48.0, "fog": "#7a72b8", "floor": "grass", "boundary": "hedge"},
	"WORLD_ELARIS": {"sky_top": "#2f74d6", "sky_horizon": "#cdeeff", "sun": "#fff0c8", "sun_energy": 1.25, "pitch": -58.0, "fog": "#a8d8b0", "floor": "forest", "boundary": "hedge"},
	"WORLD_VALDORIA": {"sky_top": "#2b4c9c", "sky_horizon": "#ffc48e", "sun": "#ffd8a0", "sun_energy": 1.2, "pitch": -35.0, "fog": "#e6b892", "floor": "cobble", "boundary": "wall"},
	"WORLD_SOLMERA": {"sky_top": "#3b82d9", "sky_horizon": "#ffe0ae", "sun": "#fff2c8", "sun_energy": 1.5, "pitch": -55.0, "fog": "#f2d4a0", "floor": "sand", "boundary": "wall"},
}

## prop name keyword -> shape/material kind (first match wins)
const PROP_KINDS := [
	["water", ["stream", "canal_water", "flooded_channel", "water_basin"]],
	["glow", ["rift_glow", "great_rift", "resonance_bridge", "professorium_machine"]],
	["tree", ["tree"]],
	["roots", ["root_"]],
	["house", ["house", "shop_", "research_hall", "workshop", "smithy", "guild_hall", "library", "casino", "valve_house"]],
	["wood", ["bed", "table", "crates", "fence", "pier", "banner", "stands", "stall", "drained_channel"]],
	["stone", []],
]

const EXIT_GAP := 6.0
## texture repeats per metre on floors (keeps cobbles/planks at a believable size)
const FLOOR_SCALE := {"cobble": 0.55, "wood": 0.6, "rock": 0.3, "grass": 0.25, "forest": 0.25, "sand": 0.2}

## CC0 KayKit Medieval Hexagon models (assets/world/kaykit), G04
const MODEL_DIR := "res://assets/world/kaykit/%s.gltf"
const WORLD_COLOR := {"WORLD_LUNARIS": "blue", "WORLD_ELARIS": "green", "WORLD_VALDORIA": "red", "WORLD_SOLMERA": "red"}
## prop name keyword -> building model ("%s" = world colour variant)
const BUILDINGS := [["smithy", "building_blacksmith_red"], ["workshop", "building_blacksmith_red"], ["market", "building_market_red"], ["shop_", "building_market_red"], ["library", "building_church_red"], ["research_hall", "building_church_red"], ["guild_hall", "building_tavern_%s"], ["house", "building_home_%s"]]
## backdrop beyond the area border: [inner row models, outer row models]
const BACKDROP := {
	"WORLD_LUNARIS": [["trees_A_medium", "tree_single_A", "trees_A_large", "tree_single_B"], ["trees_A_large", "trees_A_medium"]],
	"WORLD_ELARIS": [["trees_B_large", "trees_B_medium", "tree_single_B", "trees_A_large"], ["trees_B_large", "trees_A_large"]],
	"WORLD_VALDORIA": [["building_home_A_red", "building_home_B_red", "building_tavern_red", "building_tower_A_red", "building_home_A_red"], ["trees_A_large", "trees_B_large"]],
	"WORLD_SOLMERA": [["rock_single_A", "rock_single_B", "tent", "rock_single_C", "building_tower_A_red"], ["rock_single_A", "rock_single_C", "rock_single_B"]],
}

static var _cache := {}
static var _models := {}   # name -> [PackedScene, AABB]


## Android and the browser use the compatibility renderer: cheaper shadows.
static func low_end() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web")


static func world_of(area_id: String) -> String:
	return str(Content.get_entry("areas", area_id).get("world", "WORLD_LUNARIS"))


static func is_indoor(area_id: String, layout: Dictionary) -> bool:
	if layout.has("indoor"):
		return bool(layout.indoor)
	return INDOOR_KEYS.any(func(k): return area_id.contains(k))


static func style(area_id: String) -> Dictionary:
	return WORLDS.get(world_of(area_id), WORLDS.WORLD_LUNARIS)


static func prop_kind(prop_name: String) -> String:
	for entry in PROP_KINDS:
		if entry[1].any(func(k): return prop_name.contains(k)):
			return entry[0]
	return "stone"


static func floor_texture(area_id: String, layout: Dictionary) -> String:
	if layout.has("floor_tex"):
		return layout.floor_tex
	if area_id.contains("HOME"):
		return "wood"
	if area_id.contains("CAVE") or area_id.contains("DUNGEON") or area_id.contains("RUINS"):
		return "rock"
	if is_indoor(area_id, layout):
		return "cobble"
	return style(area_id).floor


## Environment + sun for an area.
static func build_environment(parent: Node, area_id: String, layout: Dictionary) -> void:
	var st := style(area_id)
	var indoor := is_indoor(area_id, layout)
	var ambient := Color.html(layout.get("ambient", "#ffffff"))
	var env := Environment.new()
	if indoor:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color.html(layout.get("ground", "#222222")).darkened(0.7)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = ambient
		env.ambient_light_energy = 0.75
		env.fog_enabled = true
		env.fog_light_color = ambient.darkened(0.6)
		env.fog_density = 0.025
	else:
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color.html(st.sky_top)
		sky_mat.sky_horizon_color = Color.html(st.sky_horizon)
		sky_mat.ground_horizon_color = Color.html(st.sky_horizon)
		sky_mat.ground_bottom_color = Color.html(st.sky_top).darkened(0.5)
		sky_mat.sun_angle_max = 20.0
		var sky := Sky.new()
		sky.sky_material = sky_mat
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = 0.55
		env.ambient_light_color = ambient
		env.ambient_light_energy = 0.9
		env.fog_enabled = true
		env.fog_light_color = Color.html(st.fog)
		env.fog_density = 0.006
		env.fog_sky_affect = 0.2
		if layout.get("sandstorm", false):
			# drifting sand: dense, warm fog that swallows the horizon
			env.fog_light_color = Color.html(st.fog).darkened(0.12)
			env.fog_density = 0.02
			env.fog_sky_affect = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.ssao_enabled = true  # Forward+ only; ignored by the web renderer
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	parent.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(float(st.pitch), -25, 0)
	sun.light_color = Color.html(st.sun)
	sun.light_energy = float(st.sun_energy) * (0.45 if indoor else 1.0)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 35.0 if low_end() else 60.0
	parent.add_child(sun)


## Tiled, world-space material; `tint` lightly colours the texture so the
## layout's art-direction colours survive.
static func surface(tex: String, tint: Color, scale: float = 0.25) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [tex, tint.to_html(), scale]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(TEX % [tex, "albedo"])
	m.normal_enabled = true
	m.normal_texture = load(TEX % [tex, "normal"])
	m.albedo_color = tint.lerp(Color.WHITE, 0.45)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[key] = m
	return m


static func water(tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(tint.r, tint.g, tint.b, 0.78)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.2
	m.roughness = 0.05
	m.emission_enabled = true
	m.emission = tint * 0.25
	return m


static func glow(tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(tint.r, tint.g, tint.b, maxf(tint.a, 0.85))
	if tint.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = 1.2
	return m


static func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, nm: String = "Mesh") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


## Builds the visible shape of a layout prop inside `root` (size = collision box).
static func build_prop(root: Node3D, prop_name: String, size: Vector3, color: Color, world_style: Dictionary) -> void:
	match prop_kind(prop_name):
		"water":
			var b := BoxMesh.new()
			b.size = size
			_mesh(root, b, Vector3.ZERO, water(color))
		"glow":
			var b := BoxMesh.new()
			b.size = size
			_mesh(root, b, Vector3.ZERO, glow(color))
		"tree":
			if not _model_tree(root, prop_name, size):
				_tree(root, size, color)
		"roots":
			var b := BoxMesh.new()
			b.size = size
			_mesh(root, b, Vector3.ZERO, surface("bark", color, 0.4))
		"house":
			if not _model_building(root, prop_name, size, world_style):
				_house(root, size, color)
		"wood":
			var b := BoxMesh.new()
			b.size = size
			_mesh(root, b, Vector3.ZERO, surface("wood", color, 0.35))
		_:
			var b := BoxMesh.new()
			b.size = size
			_mesh(root, b, Vector3.ZERO, surface("brick" if world_style.get("boundary", "") == "wall" else "rock", color, 0.3))


## Instance of a KayKit model plus its unscaled bounds (cached per name).
static func model(name: String) -> Array:
	if not _models.has(name):
		var path := MODEL_DIR % name
		if not ResourceLoader.exists(path):
			_models[name] = [null, AABB()]
		else:
			var scene: PackedScene = load(path)
			var probe: Node3D = scene.instantiate()
			var box := AABB()
			var first := true
			for mi in probe.find_children("*", "MeshInstance3D", true, false):
				var a: AABB = (mi as MeshInstance3D).transform * (mi as MeshInstance3D).get_aabb()
				box = a if first else box.merge(a)
				first = false
			probe.free()
			_models[name] = [scene, box]
	var entry: Array = _models[name]
	return [(entry[0] as PackedScene).instantiate() if entry[0] else null, entry[1]]


static func _place(parent: Node3D, name: String, pos: Vector3, scl: float, yaw: float = 0.0) -> Node3D:
	var m: Array = model(name)
	if m[0] == null:
		return null
	var n: Node3D = m[0]
	n.scale = Vector3.ONE * scl
	n.rotation.y = yaw
	n.position = pos - Vector3(0, (m[1] as AABB).position.y * scl, 0)
	parent.add_child(n)
	return n


static func building_for(prop_name: String, world_style: Dictionary) -> String:
	var colour: String = WORLD_COLOR.get(_world_key(world_style), "red")
	for b in BUILDINGS:
		if prop_name.contains(b[0]):
			var nm: String = b[1]
			if nm == "building_home_%s":
				return "building_home_%s_%s" % ["A" if prop_name.hash() % 2 == 0 else "B", colour]
			return nm % colour if nm.contains("%s") else nm
	return ""


static func _world_key(world_style: Dictionary) -> String:
	for k in WORLDS:
		if WORLDS[k] == world_style:
			return k
	return "WORLD_LUNARIS"


## Building model fitted to the prop's footprint (never beyond its collision).
static func _model_building(root: Node3D, prop_name: String, size: Vector3, world_style: Dictionary) -> bool:
	var nm := building_for(prop_name, world_style)
	if nm == "":
		return false
	var box: AABB = model(nm)[1]
	var scl := minf(size.x / box.size.x, size.z / box.size.z)
	var n := _place(root, nm, Vector3(0, -size.y / 2.0, 0), scl)
	if n:
		n.name = "Building"
	return n != null


static func _model_tree(root: Node3D, prop_name: String, size: Vector3) -> bool:
	var nm := "tree_single_B" if prop_name.contains("living") or prop_name.hash() % 2 == 0 else "tree_single_A"
	var n := _place(root, nm, Vector3(0, -size.y / 2.0, 0), size.y / 1.1)
	if n:
		n.name = "Tree"
	return n != null


## Scenery beyond the walkable border (outdoors only): a row of trees or
## town houses close to the wall and hills/mountains further out, chosen
## deterministically per area. Purely visual; leaves exit openings free.
static func build_backdrop(parent: Node3D, area_id: String, layout: Dictionary, size: Vector2) -> void:
	if is_indoor(area_id, layout):
		return
	var rows: Array = BACKDROP.get(world_of(area_id), BACKDROP.WORLD_LUNARIS)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(area_id)
	var root := Node3D.new()
	root.name = "Backdrop"
	parent.add_child(root)
	var exits: Array = layout.get("exits", []).map(func(x): return Vector2(float(x.pos[0]), float(x.pos[2])))
	var town := world_of(area_id) == "WORLD_VALDORIA"
	# [models, distance beyond the edge, spacing, min scale, max scale]
	var specs := [[rows[0], 5.0, 7.5, 4.5 if not town else 6.0, 6.5 if not town else 8.0], [rows[1], 18.0, 16.0 if low_end() else 10.0, 7.0, 10.0]]
	for spec in specs:
		var hx := size.x / 2.0 + float(spec[1])
		var hz := size.y / 2.0 + float(spec[1])
		var skip: Array = layout.get("backdrop_skip", [])  # e.g. "south" for a harbour
		for side in [[Vector2(-hx, -hz), Vector2(hx, -hz), "north"], [Vector2(-hx, hz), Vector2(hx, hz), "south"], [Vector2(-hx, -hz), Vector2(-hx, hz), "west"], [Vector2(hx, -hz), Vector2(hx, hz), "east"]]:
			if side[2] in skip:
				continue
			var a: Vector2 = side[0]
			var b: Vector2 = side[1]
			var steps := maxi(1, int(a.distance_to(b) / float(spec[2])))
			for i in steps + 1:
				var p := a.lerp(b, float(i) / steps) + Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5))
				if exits.any(func(e: Vector2): return Vector2(clampf(p.x, -size.x / 2.0, size.x / 2.0), clampf(p.y, -size.y / 2.0, size.y / 2.0)).distance_to(e) < 7.0):
					continue
				var models: Array = spec[0]
				var nm: String = models[rng.randi() % models.size()]
				var yaw := atan2(-p.x, -p.y) if town else rng.randf() * TAU
				_place(root, nm, Vector3(p.x, -0.05, p.y), rng.randf_range(spec[3], spec[4]), yaw)


## Small hand-placed dressing from layout "decor" (G05): KayKit models or
## procedural lanterns, with an optional thin collider ("r", metres) so the
## player does not walk through barrels. Scale 1 = hex-pack units × DECOR_SCALE.
const DECOR_SCALE := 5.0


static func build_decor(parent: Node3D, layout: Dictionary) -> void:
	var list: Array = layout.get("decor", [])
	if list.is_empty():
		return
	var root := Node3D.new()
	root.name = "Decor"
	parent.add_child(root)
	for d in list:
		var pos := Vector3(float(d.pos[0]), float(d.pos[1]), float(d.pos[2]))
		var yaw := deg_to_rad(float(d.get("rot", 0.0)))
		var n: Node3D
		if d.model == "lantern":
			n = _lantern(root, pos, yaw)
		elif d.model == "water":
			var plane := PlaneMesh.new()
			plane.size = Vector2(float(d.size[0]), float(d.size[1]))
			n = _mesh(root, plane, pos, water(Color(0.25, 0.5, 0.75)), "Water")
		elif d.model == "path":
			n = _path(root, pos, yaw, Vector2(float(d.size[0]), float(d.size[1])), str(d.get("tex", "cobble")))
		else:
			n = _place(root, d.model, pos, DECOR_SCALE * float(d.get("scale", 1.0)), yaw)
		if n and d.has("r"):
			var body := StaticBody3D.new()
			body.name = "DecorCollider"
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = float(d.r)
			cyl.height = 2.0
			cs.shape = cyl
			cs.position.y = 1.0
			body.add_child(cs)
			body.position = pos
			root.add_child(body)


## Flat road or plaza (visual only) laid just above the floor.
static func _path(parent: Node3D, pos: Vector3, yaw: float, size: Vector2, tex: String) -> Node3D:
	var plane := PlaneMesh.new()
	plane.size = size
	var mi := _mesh(parent, plane, pos + Vector3(0, 0.02, 0), surface(tex, Color(0.92, 0.88, 0.8), FLOOR_SCALE.get(tex, 0.5)), "Path")
	mi.rotation.y = yaw
	return mi


static func _lantern(parent: Node3D, pos: Vector3, yaw: float) -> Node3D:
	var n := Node3D.new()
	n.name = "Lantern"
	n.position = pos
	n.rotation.y = yaw
	parent.add_child(n)
	var wood := surface("wood", Color(0.35, 0.25, 0.18), 1.0)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.06
	pole.bottom_radius = 0.09
	pole.height = 2.6
	_mesh(n, pole, Vector3(0, 1.3, 0), wood, "Pole")
	var arm := BoxMesh.new()
	arm.size = Vector3(0.6, 0.07, 0.07)
	_mesh(n, arm, Vector3(0.25, 2.5, 0), wood, "Arm")
	var lamp := BoxMesh.new()
	lamp.size = Vector3(0.16, 0.22, 0.16)
	var amber := glow(Color(1.0, 0.65, 0.3))
	amber.emission_energy_multiplier = 0.9
	_mesh(n, lamp, Vector3(0.5, 2.3, 0), amber, "Lamp")
	var cap := PrismMesh.new()
	cap.size = Vector3(0.26, 0.12, 0.26)
	_mesh(n, cap, Vector3(0.5, 2.47, 0), wood, "Cap")
	return n


## Landmarks far outside the walkable area (outdoor Lunaris/Valdoria): a
## castle on the horizon and floating islands with trees, like the key art.
const SKY_FEATURES := {"WORLD_LUNARIS": "building_castle_blue", "WORLD_VALDORIA": "building_castle_blue"}


static func build_sky_features(parent: Node3D, area_id: String, layout: Dictionary, size: Vector2) -> void:
	if is_indoor(area_id, layout) or not SKY_FEATURES.has(world_of(area_id)):
		return
	var root := Node3D.new()
	root.name = "SkyFeatures"
	parent.add_child(root)
	var far := size.y / 2.0 + 70.0
	_place(root, SKY_FEATURES[world_of(area_id)], Vector3(-far * 0.9, -6, -far * 1.7), 26.0, 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(area_id + "sky")
	var rock := surface("rock", Color(0.55, 0.5, 0.6), 0.15)
	var grass := surface("grass", Color(0.6, 0.85, 0.6), 0.2)
	for i in (3 if low_end() else 6):
		var ang := lerpf(-1.1, 1.1, float(i) / 5.0) + rng.randf_range(-0.12, 0.12)
		var dist := rng.randf_range(far * 0.8, far * 1.3)
		var island := Node3D.new()
		island.name = "Island"
		island.position = Vector3(sin(ang) * dist, rng.randf_range(24, 46), -cos(ang) * dist)
		root.add_child(island)
		var r := rng.randf_range(5.0, 11.0)
		var under := CylinderMesh.new()
		under.top_radius = r
		under.bottom_radius = 0.0
		under.height = r * 1.6
		_mesh(island, under, Vector3(0, -r * 0.8, 0), rock, "Rock")
		var top := CylinderMesh.new()
		top.top_radius = r * 0.98
		top.bottom_radius = r
		top.height = 0.8
		_mesh(island, top, Vector3.ZERO, grass, "Top")
		for t in 2:
			_place(island, "trees_A_medium", Vector3(rng.randf_range(-r, r) * 0.4, 0.3, rng.randf_range(-r, r) * 0.4), r * 0.55, rng.randf() * TAU)


static func _tree(root: Node3D, size: Vector3, color: Color) -> void:
	var trunk := CylinderMesh.new()
	var r := minf(size.x, size.z) * 0.22
	trunk.top_radius = r * 0.8
	trunk.bottom_radius = r * 1.1
	trunk.height = size.y * 0.6
	_mesh(root, trunk, Vector3(0, -size.y * 0.2, 0), surface("bark", Color(0.55, 0.4, 0.3), 0.5), "Trunk")
	var leaves := surface("grass", color.lightened(0.15), 0.6)
	var cr := maxf(size.x, size.z) * 1.1
	for off in [Vector3(0, size.y * 0.25, 0), Vector3(cr * 0.45, size.y * 0.12, 0.2), Vector3(-cr * 0.4, size.y * 0.1, -0.3), Vector3(0.1, size.y * 0.42, cr * 0.2)]:
		var s := SphereMesh.new()
		s.radius = cr * (0.75 if off.x != 0.0 else 0.95)
		s.height = s.radius * 1.7
		_mesh(root, s, off, leaves, "Canopy")


static func _house(root: Node3D, size: Vector3, color: Color) -> void:
	var body := BoxMesh.new()
	body.size = size
	_mesh(root, body, Vector3.ZERO, surface("plaster", color, 0.3), "Walls")
	var roof := PrismMesh.new()
	roof.size = Vector3(size.x * 1.15, size.y * 0.5, size.z * 1.15)
	_mesh(root, roof, Vector3(0, size.y * 0.75, 0), surface("roof", Color(0.75, 0.35, 0.25), 0.3), "Roof")
	var trim := surface("wood", Color(0.5, 0.33, 0.2), 0.5)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var post := BoxMesh.new()
			post.size = Vector3(0.35, size.y, 0.35)
			_mesh(root, post, Vector3(sx * (size.x / 2.0 - 0.1), 0, sz * (size.z / 2.0 - 0.1)), trim, "Post")


## Visible border of the area (the colliders already exist) plus, outdoors, a
## large ground skirt that fades into the fog.
static func build_boundary(parent: Node3D, area_id: String, layout: Dictionary, size: Vector2, wall_height: float) -> void:
	var st := style(area_id)
	var indoor := is_indoor(area_id, layout)
	var ground := Color.html(layout.get("ground", "#555555"))
	var mat: Material
	var h: float
	if indoor:
		mat = surface("rock" if area_id.contains("CAVE") or area_id.contains("DUNGEON") else "brick", ground.lightened(0.2), 0.25)
		h = wall_height
	elif st.boundary == "wall":
		mat = surface("brick", Color(0.85, 0.78, 0.68), 0.3)
		h = 2.4
	else:
		mat = surface("rock", ground.lightened(0.15), 0.5)
		h = 0.9
	var hx := size.x / 2.0
	var hz := size.y / 2.0
	var root := Node3D.new()
	root.name = "Boundary"
	parent.add_child(root)
	var exits: Array = layout.get("exits", []).map(func(x): return Vector2(float(x.pos[0]), float(x.pos[2])))
	# side: fixed coordinate, axis along the wall (true = runs along x), half length
	for side in [[-hz, true, hx], [hz, true, hx], [-hx, false, hz], [hx, false, hz]]:
		var gaps: Array = []
		for e in exits:
			var across: float = e.y if side[1] else e.x
			if absf(across - float(side[0])) < 4.0:
				gaps.append(e.x if side[1] else e.y)
		for seg in wall_segments(-float(side[2]), float(side[2]), gaps, EXIT_GAP):
			var length: float = seg[1] - seg[0]
			var mid: float = (seg[0] + seg[1]) / 2.0
			var b := BoxMesh.new()
			b.size = Vector3(length, h, 1) if side[1] else Vector3(1, h, length)
			var pos := Vector3(mid, h / 2, float(side[0])) if side[1] else Vector3(float(side[0]), h / 2, mid)
			_mesh(root, b, pos, mat, "Wall")
	if not indoor:
		var skirt := PlaneMesh.new()
		skirt.size = Vector2(size.x + 240, size.y + 240)
		_mesh(root, skirt, Vector3(0, -0.05, 0), surface(floor_texture(area_id, layout), ground.darkened(0.25), 0.25), "Skirt")


## Splits [from, to] into wall pieces that leave `gap`-wide openings at `gaps`.
static func wall_segments(from: float, to: float, gaps: Array, gap: float) -> Array:
	var cuts: Array = gaps.duplicate()
	cuts.sort()
	var out := []
	var start := from
	for c in cuts:
		var a := float(c) - gap / 2.0
		if a > start + 0.1:
			out.append([start, a])
		start = maxf(start, float(c) + gap / 2.0)
	if to > start + 0.1:
		out.append([start, to])
	return out
