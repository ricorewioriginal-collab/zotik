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
	"WORLD_LUNARIS": {"sky_top": "#0a1140", "sky_horizon": "#4a3f9a", "sun": "#b8c8ff", "sun_energy": 0.8, "pitch": -48.0, "fog": "#3a3a8a", "floor": "grass", "boundary": "hedge", "night": true, "fog_density": 0.01},
	"WORLD_ELARIS": {"sky_top": "#2f74d6", "sky_horizon": "#cdeeff", "sun": "#fff0c8", "sun_energy": 1.25, "pitch": -58.0, "fog": "#a8d8b0", "floor": "forest", "boundary": "hedge"},
	"WORLD_VALDORIA": {"sky_top": "#2b4c9c", "sky_horizon": "#ffc48e", "sun": "#ffd8a0", "sun_energy": 1.2, "pitch": -35.0, "fog": "#e6b892", "floor": "cobble", "boundary": "wall"},
	"WORLD_SOLMERA": {"sky_top": "#3b82d9", "sky_horizon": "#ffe0ae", "sun": "#fff2c8", "sun_energy": 1.5, "pitch": -55.0, "fog": "#f2d4a0", "floor": "sand", "boundary": "wall"},
	"WORLD_AQUALIS": {"sky_top": "#0a3a6a", "sky_horizon": "#4ad0c8", "sun": "#a8f0ff", "sun_energy": 1.1, "pitch": -70.0, "fog": "#1a8aa8", "floor": "sand", "boundary": "wall", "fog_density": 0.016},
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

## tree models for placed "tree" props
const TREES := ["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "CommonTree_5"]

## CC0 KayKit Medieval Hexagon models (assets/world/kaykit), G04
const MODEL_DIR := "res://assets/world/kaykit/%s.gltf"
## CC0 Quaternius Stylized Nature MegaKit (assets/world/nature), R04: trees, rocks, grass, flowers
const NATURE_DIR := "res://assets/world/nature/%s.gltf"
const WORLD_COLOR := {"WORLD_LUNARIS": "blue", "WORLD_ELARIS": "green", "WORLD_VALDORIA": "red", "WORLD_SOLMERA": "red", "WORLD_AQUALIS": "blue"}
## prop name keyword -> building model ("%s" = world colour variant)
const BUILDINGS := [["smithy", "building_blacksmith_red"], ["workshop", "building_blacksmith_red"], ["market", "building_market_red"], ["shop_", "building_market_red"], ["library", "building_church_red"], ["research_hall", "building_church_red"], ["guild_hall", "building_tavern_%s"], ["house", "building_home_%s"]]
## backdrop beyond the area border: [inner row models, outer row models]
const BACKDROP := {
	"WORLD_LUNARIS": [["CommonTree_1", "CommonTree_3", "CommonTree_5", "Pine_2", "CommonTree_2"], ["TwistedTree_1", "TwistedTree_2", "Pine_1", "TwistedTree_3"]],
	"WORLD_ELARIS": [["CommonTree_2", "CommonTree_4", "Pine_1", "CommonTree_1", "Pine_3"], ["TwistedTree_2", "TwistedTree_3", "Pine_2"]],
	"WORLD_VALDORIA": [["building_home_A_red", "building_home_B_red", "building_tavern_red", "building_tower_A_red", "building_home_A_red"], ["trees_A_large", "trees_B_large"]],
	"WORLD_SOLMERA": [["rock_single_A", "rock_single_B", "tent", "rock_single_C", "building_tower_A_red"], ["rock_single_A", "rock_single_C", "rock_single_B"]],
	"WORLD_AQUALIS": [["building_tower_A_blue", "rock_single_A", "building_home_A_blue", "rock_single_B", "building_home_B_blue"], ["rock_single_A", "rock_single_C", "rock_single_B"]],
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
		var sky := Sky.new()
		if st.get("night", false):
			var night := ShaderMaterial.new()
			night.shader = load("res://assets/shaders/night_sky.gdshader")
			night.set_shader_parameter("sky_top", Color.html(st.sky_top))
			night.set_shader_parameter("sky_horizon", Color.html(st.sky_horizon))
			night.set_shader_parameter("moon_dir", Vector3(-0.3, 0.2, -0.9))
			night.set_shader_parameter("moon_size", 0.075)
			sky.sky_material = night
			sky.radiance_size = Sky.RADIANCE_SIZE_32 if low_end() else Sky.RADIANCE_SIZE_128
		else:
			var sky_mat := ProceduralSkyMaterial.new()
			sky_mat.sky_top_color = Color.html(st.sky_top)
			sky_mat.sky_horizon_color = Color.html(st.sky_horizon)
			sky_mat.ground_horizon_color = Color.html(st.sky_horizon)
			sky_mat.ground_bottom_color = Color.html(st.sky_top).darkened(0.5)
			sky_mat.sun_angle_max = 20.0
			sky.sky_material = sky_mat
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = 0.55
		env.ambient_light_color = ambient
		env.ambient_light_energy = 0.9
		env.fog_enabled = true
		env.fog_light_color = Color.html(st.fog)
		env.fog_density = float(st.get("fog_density", 0.006))
		env.fog_sky_affect = 0.2
		if layout.get("sandstorm", false):
			# drifting sand: dense, warm fog that swallows the horizon
			env.fog_light_color = Color.html(st.fog).darkened(0.12)
			env.fog_density = 0.02
			env.fog_sky_affect = 0.7
		if layout.get("current", false):
			# drifting current: thick, dark teal water that hides the far reef
			env.fog_light_color = Color.html(st.fog).darkened(0.3)
			env.fog_density = 0.026
			env.fog_sky_affect = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	# Android and the browser skip the full-screen glow and colour passes
	env.glow_enabled = not low_end()
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.ssao_enabled = true  # Forward+ only; ignored by the web renderer
	env.adjustment_enabled = not low_end()
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
	if low_end():
		# one shadow split instead of four: the scene is drawn once into the shadow map
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
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
static func _entry(name: String) -> Array:
	if not _models.has(name):
		var path := MODEL_DIR % name
		if not ResourceLoader.exists(path):
			path = NATURE_DIR % name
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
				if path.begins_with("res://assets/world/nature"):
					# the kit bakes autumn colours into the vertices: use the plain green/natural textures
					var mesh := (mi as MeshInstance3D).mesh
					for i in mesh.get_surface_count():
						var sm := mesh.surface_get_material(i)
						if sm is StandardMaterial3D:
							(sm as StandardMaterial3D).vertex_color_use_as_albedo = false
			probe.free()
			_models[name] = [scene, box]
	return _models[name]


## Bounding box of a model (empty AABB if it does not exist); no node is created.
static func model_box(name: String) -> AABB:
	return _entry(name)[1]


static func model(name: String) -> Array:
	var entry: Array = _entry(name)
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


## Like _place, but scales the model to a target height in metres.
static func _place_h(parent: Node3D, name: String, pos: Vector3, height: float, yaw: float = 0.0) -> Node3D:
	var box := model_box(name)
	if box.size.y <= 0.0:
		return null
	return _place(parent, name, pos, height / box.size.y, yaw)


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
	var box := model_box(nm)
	var scl := minf(size.x / box.size.x, size.z / box.size.z)
	var n := _place(root, nm, Vector3(0, -size.y / 2.0, 0), scl)
	if n:
		n.name = "Building"
	return n != null


static func _model_tree(root: Node3D, prop_name: String, size: Vector3) -> bool:
	var n: Node3D = _place_h(root, TREES[absi(prop_name.hash()) % TREES.size()], Vector3(0, -size.y / 2.0, 0), maxf(size.y, 5.0), float(absi(prop_name.hash()) % 628) / 100.0)
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
				if ResourceLoader.exists(NATURE_DIR % nm):
					# metre-scaled nature model: inner row 7-12 m, outer row 14-24 m
					var tall := rng.randf_range(7.0, 12.0) if spec[1] < 10.0 else rng.randf_range(14.0, 24.0)
					_place_h(root, nm, Vector3(p.x, -0.05, p.y), tall, yaw)
				else:
					_place(root, nm, Vector3(p.x, -0.05, p.y), rng.randf_range(spec[3], spec[4]), yaw)


## Small hand-placed dressing from layout "decor" (G05): KayKit models or
## procedural lanterns, with an optional thin collider ("r", metres) so the
## player does not walk through barrels. Scale 1 = hex-pack units × DECOR_SCALE.
const DECOR_SCALE := 5.0


static func build_decor(parent: Node3D, layout: Dictionary, area_id: String = "") -> void:
	var list: Array = layout.get("decor", [])
	if list.is_empty():
		return
	var night: bool = area_id != "" and style(area_id).get("night", false)
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
			n = _path(root, pos, yaw, Vector2(float(d.size[0]), float(d.size[1])), str(d.get("tex", "cobble")), night)
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
static func _path(parent: Node3D, pos: Vector3, yaw: float, size: Vector2, tex: String, night: bool = false) -> Node3D:
	var plane := PlaneMesh.new()
	plane.size = size
	var mi := _mesh(parent, plane, pos + Vector3(0, 0.02, 0), surface(tex, Color(0.6, 0.66, 0.85) if night else Color(0.92, 0.88, 0.8), FLOOR_SCALE.get(tex, 0.5)), "Path")
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
	amber.emission_energy_multiplier = 2.4
	_mesh(n, lamp, Vector3(0.5, 2.3, 0), amber, "Lamp")
	if not low_end():
		var light := OmniLight3D.new()
		light.name = "LampLight"
		light.position = Vector3(0.5, 2.2, 0)
		light.light_color = Color(1.0, 0.72, 0.4)
		light.light_energy = 1.6
		light.omni_range = 7.0
		n.add_child(light)
	var cap := PrismMesh.new()
	cap.size = Vector3(0.26, 0.12, 0.26)
	_mesh(n, cap, Vector3(0.5, 2.47, 0), wood, "Cap")
	return n


## Ground tint: night worlds get a cool blue cast so the grass sits in the moonlight.
static func ground_tint(area_id: String, layout: Dictionary) -> Color:
	var c := Color.html(layout.get("ground", "#555555"))
	if style(area_id).get("night", false) and not is_indoor(area_id, layout):
		c = c.lerp(Color(0.3, 0.55, 0.9), 0.5).darkened(0.05)
	return c


## grass / flower / mushroom models (Quaternius, metres: grass ~1 m, so scaled down) and their tint
const FLORA := {
	"WORLD_LUNARIS": {"grass": ["Grass_Wispy_Short", "Grass_Common_Short", "Grass_Common_Tall"], "flowers": ["Flower_3_Group", "Flower_4_Group"], "mush": ["Mushroom_Common"], "tint": "#9fc8ff", "flower_tint": "#a8c8ff", "count": 2600, "flower_count": 260, "mush_count": 70, "glow": "#7fd8ff", "glow_count": 160},
	"WORLD_ELARIS": {"grass": ["Grass_Wispy_Short", "Grass_Common_Short", "Grass_Common_Tall"], "flowers": ["Flower_3_Group", "Flower_4_Group", "Clover_1"], "mush": ["Mushroom_Common", "Mushroom_Laetiporus"], "tint": "#e8ffd0", "flower_tint": "#ffffff", "count": 2600, "flower_count": 220, "mush_count": 50, "glow": "#ffe08a", "glow_count": 60},
	"WORLD_VALDORIA": {"grass": ["Grass_Common_Short", "Grass_Common_Tall"], "flowers": ["Flower_3_Group"], "mush": [], "tint": "#d8e8b8", "flower_tint": "#ffffff", "count": 700, "flower_count": 60, "mush_count": 0, "glow": "", "glow_count": 0},
	"WORLD_SOLMERA": {"grass": ["Grass_Wispy_Short", "Plant_1"], "flowers": [], "mush": [], "tint": "#e8cc88", "flower_tint": "#ffffff", "count": 500, "flower_count": 0, "mush_count": 0, "glow": "", "glow_count": 0},
}
static var _flora_meshes := {}


## First mesh of a nature model with every surface material tinted.
static func nature_mesh(name: String, tint: Color) -> Mesh:
	var key := name + tint.to_html()
	if _flora_meshes.has(key):
		return _flora_meshes[key]
	var entry := _entry(name)
	var result: Mesh = null
	if entry[0]:
		var probe: Node3D = (entry[0] as PackedScene).instantiate()
		var found := probe.find_children("*", "MeshInstance3D", true, false)
		if not found.is_empty():
			result = ((found[0] as MeshInstance3D).mesh as Mesh).duplicate()
			for i in result.get_surface_count():
				var m := result.surface_get_material(i)
				if m is StandardMaterial3D:
					m = m.duplicate()
					(m as StandardMaterial3D).albedo_color = tint
					result.surface_set_material(i, m)
		probe.free()
	_flora_meshes[key] = result
	return result


## Grass, flowers, mushrooms and glowing buds scattered over the open ground
## (R01/R04): Quaternius models as MultiMeshes, so it is a handful of draw
## calls even on the web.
static func build_flora(parent: Node3D, area_id: String, layout: Dictionary, size: Vector2) -> void:
	if is_indoor(area_id, layout) or not FLORA.has(world_of(area_id)):
		return
	var cfg: Dictionary = FLORA[world_of(area_id)]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(area_id + "flora")
	# keep roads, houses, water and the exits free
	var blocked: Array[Rect2] = []
	for p in layout.get("props", []):
		blocked.append(Rect2(float(p.pos[0]) - float(p.size[0]) / 2.0 - 0.8, float(p.pos[2]) - float(p.size[2]) / 2.0 - 0.8, float(p.size[0]) + 1.6, float(p.size[2]) + 1.6))
	for d in layout.get("decor", []):
		if d.has("size"):
			blocked.append(Rect2(float(d.pos[0]) - float(d.size[0]) / 2.0 - 0.5, float(d.pos[2]) - float(d.size[1]) / 2.0 - 0.5, float(d.size[0]) + 1.0, float(d.size[1]) + 1.0))
	var exits: Array = layout.get("exits", []).map(func(x): return Vector2(float(x.pos[0]), float(x.pos[2])))
	var root := Node3D.new()
	root.name = "Flora"
	parent.add_child(root)
	var div := 3 if low_end() else 1
	var groups := [["Grass", cfg.grass, Color.html(cfg.tint), int(cfg.count) / div, 0.28, 0.55], ["Flowers", cfg.flowers, Color.html(cfg.flower_tint), int(cfg.flower_count) / div, 0.3, 0.5], ["Mushrooms", cfg.mush, Color(1, 1, 1), int(cfg.mush_count) / div, 0.35, 0.7]]
	var glow_pts: Array[Vector3] = []
	for g in groups:
		var names: Array = g[1]
		if names.is_empty() or int(g[3]) <= 0:
			continue
		# one MultiMesh per model of the group
		var per := maxi(1, int(g[3]) / names.size())
		for nm in names:
			var mesh := nature_mesh(nm, g[2])
			if mesh == null:
				continue
			var xforms: Array[Transform3D] = []
			var tries := 0
			while xforms.size() < per and tries < per * 3:
				tries += 1
				var p := Vector2(rng.randf_range(-size.x / 2.0 + 1.0, size.x / 2.0 - 1.0), rng.randf_range(-size.y / 2.0 + 1.0, size.y / 2.0 - 1.0))
				if blocked.any(func(r: Rect2): return r.has_point(p)) or exits.any(func(e: Vector2): return e.distance_to(p) < 5.0):
					continue
				var sc := rng.randf_range(g[4], g[5])
				xforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), Vector3(p.x, 0.0, p.y)))
				if g[0] == "Grass" and glow_pts.size() < int(cfg.glow_count) / div and rng.randf() < 0.05:
					glow_pts.append(Vector3(p.x, 0.0, p.y))
			_multimesh(root, mesh, xforms, g[0] + "_" + nm)
	if cfg.glow != "" and not glow_pts.is_empty():
		var bulb := SphereMesh.new()
		bulb.radius = 0.09
		bulb.height = 0.18
		bulb.radial_segments = 6
		bulb.rings = 3
		var gm := glow(Color.html(cfg.glow))
		gm.emission_energy_multiplier = 2.2
		bulb.material = gm
		var bulbs: Array[Transform3D] = []
		for gp in glow_pts:
			bulbs.append(Transform3D(Basis.IDENTITY, gp + Vector3(0, rng.randf_range(0.25, 0.5), 0)))
		_multimesh(root, bulb, bulbs, "Buds")


static func _multimesh(parent: Node3D, mesh: Mesh, xforms: Array[Transform3D], nm: String) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mi := MultiMeshInstance3D.new()
	mi.name = nm
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


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
