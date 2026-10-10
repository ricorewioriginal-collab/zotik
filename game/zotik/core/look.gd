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
	"WORLD_LUNARIS": {"sky_top": "#0a1140", "sky_horizon": "#4a3f9a", "sun": "#b8c8ff", "sun_energy": 0.8, "pitch": -48.0, "fog": "#3a3a8a", "floor": "grass", "boundary": "hedge", "night": true, "fog_density": 0.01, "motes": {"color": "#d8ff8a", "amount": 70, "vy": 0.15, "vxz": 0.5, "y": 1.6, "h": 2.6, "size": 0.12, "life": 7.0}},
	"WORLD_ELARIS": {"sky_top": "#2f74d6", "sky_horizon": "#cdeeff", "sun": "#fff0c8", "sun_energy": 1.25, "pitch": -58.0, "fog": "#a8d8b0", "floor": "forest", "boundary": "hedge", "motes": {"color": "#fff0b0", "amount": 90, "vy": 0.25, "vxz": 0.6, "y": 1.8, "h": 3.2, "size": 0.08, "life": 8.0}},
	"WORLD_VALDORIA": {"sky_top": "#2b4c9c", "sky_horizon": "#ffc48e", "sun": "#ffd8a0", "sun_energy": 1.2, "pitch": -35.0, "fog": "#e6b892", "floor": "cobble", "boundary": "wall", "motes": {"color": "#ffe0c0", "amount": 50, "vy": 0.1, "vxz": 0.4, "y": 2.0, "h": 3.5, "size": 0.07, "life": 8.0}},
	"WORLD_SOLMERA": {"sky_top": "#3b82d9", "sky_horizon": "#ffe0ae", "sun": "#fff2c8", "sun_energy": 1.5, "pitch": -55.0, "fog": "#f2d4a0", "floor": "sand", "boundary": "wall", "motes": {"color": "#f0d8a0", "amount": 120, "vy": 0.05, "vxz": 2.2, "y": 1.2, "h": 2.5, "size": 0.06, "life": 6.0}},
	"WORLD_FROSTHAIN": {"sky_top": "#5a86b8", "sky_horizon": "#e6f2ff", "sun": "#e8f0ff", "sun_energy": 1.0, "pitch": -30.0, "fog": "#d6e6f4", "floor": "snow", "boundary": "wall", "fog_density": 0.014, "snow": true},
	"WORLD_IGNARA": {"sky_top": "#3a1218", "sky_horizon": "#ff7a3a", "sun": "#ffb070", "sun_energy": 1.1, "pitch": -25.0, "fog": "#6a2a1a", "floor": "rock", "boundary": "wall", "fog_density": 0.012, "embers": true},
	"WORLD_AQUALIS": {"sky_top": "#0a3a6a", "sky_horizon": "#4ad0c8", "sun": "#a8f0ff", "sun_energy": 1.1, "pitch": -70.0, "fog": "#1a8aa8", "floor": "sand", "boundary": "wall", "fog_density": 0.016, "motes": {"color": "#bff8ff", "amount": 90, "vy": 0.9, "vxz": 0.2, "y": 0.2, "h": 1.0, "size": 0.1, "life": 7.0}},
	"WORLD_NOCTARIS": {"sky_top": "#07051f", "sky_horizon": "#3a1a6a", "sun": "#a8a0ff", "sun_energy": 0.7, "pitch": -50.0, "fog": "#2a1a5a", "floor": "cobble", "boundary": "wall", "night": true, "fog_density": 0.013, "motes": {"color": "#c8a0ff", "amount": 90, "vy": 0.12, "vxz": 0.5, "y": 1.8, "h": 3.0, "size": 0.12, "life": 8.0}},
	"WORLD_ASTRALIS": {"sky_top": "#1a2a7a", "sky_horizon": "#ff9ad0", "sun": "#ffe8d0", "sun_energy": 0.9, "pitch": -45.0, "fog": "#7a5aa8", "floor": "cobble", "boundary": "wall", "night": true, "fog_density": 0.01, "motes": {"color": "#ffe8a0", "amount": 90, "vy": 0.2, "vxz": 0.6, "y": 2.0, "h": 3.4, "size": 0.1, "life": 8.0}},
	"WORLD_ELYNDRA": {"sky_top": "#050e26", "sky_horizon": "#3ac8c0", "sun": "#b0f0ff", "sun_energy": 0.8, "pitch": -48.0, "fog": "#2a5a7a", "floor": "cobble", "boundary": "wall", "night": true, "fog_density": 0.011, "motes": {"color": "#a0fff0", "amount": 100, "vy": 0.1, "vxz": 0.7, "y": 2.0, "h": 3.4, "size": 0.11, "life": 8.0}},
	"WORLD_WELTENRISS": {"sky_top": "#0a0620", "sky_horizon": "#7a2ab0", "sun": "#d0b0ff", "sun_energy": 0.8, "pitch": -50.0, "fog": "#3a1a6a", "floor": "cobble", "boundary": "wall", "night": true, "fog_density": 0.012, "motes": {"color": "#ff90f0", "amount": 100, "vy": 0.12, "vxz": 0.7, "y": 2.0, "h": 3.4, "size": 0.11, "life": 8.0}},
}

## prop name keyword -> shape/material kind (first match wins)
const PROP_KINDS := [
	["water", ["stream", "canal_water", "flooded_channel", "water_basin"]],
	["glow", ["rift_glow", "great_rift", "resonance_bridge", "professorium_machine", "lava"]],
	["tree", ["tree"]],
	["roots", ["root_"]],
	["house", ["house", "shop_", "research_hall", "workshop", "smithy", "guild_hall", "library", "casino", "valve_house"]],
	["wood", ["bed", "table", "crates", "fence", "pier", "banner", "stands", "stall", "drained_channel"]],
	["stone", []],
]

const EXIT_GAP := 6.0
## texture repeats per metre on floors (keeps cobbles/planks at a believable size)
const FLOOR_SCALE := {"cobble": 0.55, "wood": 0.6, "rock": 0.3, "grass": 0.25, "forest": 0.25, "sand": 0.2, "snow": 0.25}

## tree models for placed "tree" props
const TREES := ["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "CommonTree_5"]

## CC0 KayKit Medieval Hexagon models (assets/world/kaykit), G04
const MODEL_DIR := "res://assets/world/kaykit/%s.gltf"
## CC0 Quaternius Stylized Nature MegaKit (assets/world/nature), R04: trees, rocks, grass, flowers
const NATURE_DIR := "res://assets/world/nature/%s.gltf"
## CC0 Quaternius Fantasy Props MegaKit (assets/world/props): barrels, crates, benches, stalls, banners, torches
const PROPS_DIR := "res://assets/world/props/%s.gltf"
## CC0 Quaternius Medieval Village MegaKit (assets/world/village): roofs, doors, chimneys and plaster/brick textures for the houses
const VILLAGE_DIR := "res://assets/world/village/%s.gltf"
const VILLAGE_TEX := "res://assets/world/village/T_%s_BaseColor.png"
const WORLD_COLOR := {"WORLD_LUNARIS": "blue", "WORLD_ELARIS": "green", "WORLD_VALDORIA": "red", "WORLD_SOLMERA": "red", "WORLD_AQUALIS": "blue", "WORLD_FROSTHAIN": "blue", "WORLD_IGNARA": "red", "WORLD_NOCTARIS": "blue", "WORLD_ASTRALIS": "blue", "WORLD_ELYNDRA": "blue", "WORLD_WELTENRISS": "blue"}
## prop name keyword -> building model ("%s" = world colour variant)
const BUILDINGS := [["smithy", "building_blacksmith_red"], ["workshop", "building_blacksmith_red"], ["market", "building_market_red"], ["shop_", "building_market_red"], ["library", "building_church_red"], ["research_hall", "building_church_red"], ["guild_hall", "building_tavern_%s"], ["house", "building_home_%s"]]
## backdrop beyond the area border: [inner row models, outer row models]
const BACKDROP := {
	"WORLD_LUNARIS": [["CommonTree_1", "CommonTree_3", "CommonTree_5", "Pine_2", "CommonTree_2"], ["TwistedTree_1", "TwistedTree_2", "Pine_1", "TwistedTree_3"]],
	"WORLD_ELARIS": [["CommonTree_2", "CommonTree_4", "Pine_1", "CommonTree_1", "Pine_3"], ["TwistedTree_2", "TwistedTree_3", "Pine_2"]],
	"WORLD_VALDORIA": [["building_home_A_red", "building_home_B_red", "building_tavern_red", "building_tower_A_red", "building_home_A_red"], ["trees_A_large", "trees_B_large"]],
	"WORLD_SOLMERA": [["rock_single_A", "rock_single_B", "tent", "rock_single_C", "building_tower_A_red"], ["rock_single_A", "rock_single_C", "rock_single_B"]],
	"WORLD_FROSTHAIN": [["Pine_1", "Pine_2", "Pine_3", "DeadTree_1", "Pine_2"], ["Pine_3", "Pine_1", "Pine_2", "DeadTree_2"]],
	"WORLD_IGNARA": [["Rock_Medium_1", "DeadTree_1", "Rock_Medium_2", "DeadTree_2", "Rock_Medium_3"], ["Rock_Medium_3", "Rock_Medium_1", "DeadTree_2", "Rock_Medium_2"]],
	"WORLD_AQUALIS": [["building_tower_A_blue", "rock_single_A", "building_home_A_blue", "rock_single_B", "building_home_B_blue"], ["rock_single_A", "rock_single_C", "rock_single_B"]],
	"WORLD_NOCTARIS": [["building_tower_A_blue", "rock_single_A", "building_home_A_blue", "tree_single_A", "building_home_B_blue"], ["rock_single_A", "trees_A_large", "rock_single_B"]],
	"WORLD_ASTRALIS": [["building_tower_B_blue", "rock_single_B", "building_home_A_blue", "tree_single_B", "building_tower_A_blue"], ["rock_single_C", "trees_B_large", "rock_single_A"]],
	"WORLD_ELYNDRA": [["building_tower_A_green", "rock_single_C", "building_home_B_blue", "building_tower_B_blue", "rock_single_A"], ["rock_single_B", "trees_A_large", "rock_single_C"]],
	"WORLD_WELTENRISS": [["rock_single_A", "rock_single_B", "building_tower_A_blue", "rock_single_C", "rock_single_B"], ["rock_single_C", "rock_single_A", "rock_single_B"]],
}

static var _cache := {}
static var _models := {}   # name -> [PackedScene, AABB]


## Android and the browser use the compatibility renderer: cheaper shadows.
## Set ZOTIK_LOWEND=1 to test the web/Android settings on a desktop.
static var _force_low := OS.get_environment("ZOTIK_LOWEND") == "1"


static func low_end() -> bool:
	return _force_low or OS.has_feature("mobile") or OS.has_feature("web")


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


## True for the metre-scaled kits (nature, props); the KayKit hex models use their own units.
static func is_metric(name: String) -> bool:
	return ResourceLoader.exists(NATURE_DIR % name) or ResourceLoader.exists(PROPS_DIR % name) or ResourceLoader.exists(VILLAGE_DIR % name)


static func _entry(name: String) -> Array:
	if not _models.has(name):
		var path := MODEL_DIR % name
		if not ResourceLoader.exists(path):
			path = NATURE_DIR % name
		if not ResourceLoader.exists(path):
			path = PROPS_DIR % name
		if not ResourceLoader.exists(path):
			path = VILLAGE_DIR % name
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


## Instance of a model plus its unscaled bounds (cached per name).
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


## Soft rim light on character materials: a bright edge that separates people from the scene (R03).
static func rim(m: Material, amount: float) -> void:
	if m is StandardMaterial3D:
		(m as StandardMaterial3D).rim_enabled = true
		(m as StandardMaterial3D).rim = amount
		(m as StandardMaterial3D).rim_tint = 0.8


## Plaster/brick/timber material from the village kit (world-space triplanar, tintable).
static func village_surface(tex: String, tint: Color, scale: float = 0.3) -> StandardMaterial3D:
	var key := "V%s|%s|%s" % [tex, tint.to_html(), scale]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(VILLAGE_TEX % tex)
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[key] = m
	return m


## Model scaled per axis so its footprint fills width x depth, standing on y = 0 of `pivot`.
static func _fit(pivot: Node3D, name: String, width: float, depth: float, sy: float, long_axis_x: bool = false) -> Node3D:
	var m: Array = model(name)
	if m[0] == null:
		return null
	var n: Node3D = m[0]
	var box: AABB = m[1]
	var sx := width / box.size.x
	var sz := depth / box.size.z
	n.scale = Vector3(sx, sy, sz)
	n.position = Vector3(-(box.position.x + box.size.x / 2.0) * sx, -box.position.y * sy, -(box.position.z + box.size.z / 2.0) * sz)
	pivot.add_child(n)
	return n


## A real-looking house from the village kit (G6): plaster walls on a stone base,
## timber frame, a tiled roof fitted to the footprint, door with frame, chimney
## and lit windows. Footprint and height come from the layout prop.
static func _village_house(prop_root: Node3D, prop_name: String, size: Vector3, world_style: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "Building"
	prop_root.add_child(root)
	var w := size.x
	var d := size.z
	var h := size.y
	var night: bool = world_style.get("night", false)
	var wall_h := minf(h, 4.6) if h > 4.6 else h
	var wall_col := Color(0.88, 0.84, 0.78)
	match _world_key(world_style):
		"blue": wall_col = Color(0.8, 0.84, 0.95)
		"green": wall_col = Color(0.92, 0.9, 0.78)
		"red": wall_col = Color(0.95, 0.82, 0.7)
	if night:
		wall_col = wall_col.darkened(0.12)
	var plaster := village_surface("Plaster", wall_col, 0.35)
	var stone := village_surface("UnevenBrick", Color(0.85, 0.85, 0.9), 0.5)
	var wood := village_surface("WoodTrim", Color(0.75, 0.6, 0.5), 0.6)
	var base_h := minf(1.0, wall_h * 0.3)
	var top_y := -h / 2.0 + wall_h
	# stone base and plaster upper walls
	var base := BoxMesh.new()
	base.size = Vector3(w, base_h, d)
	_mesh(root, base, Vector3(0, -h / 2.0 + base_h / 2.0, 0), stone, "Base")
	var upper := BoxMesh.new()
	upper.size = Vector3(w - 0.12, wall_h - base_h, d - 0.12)
	_mesh(root, upper, Vector3(0, -h / 2.0 + base_h + (wall_h - base_h) / 2.0, 0), plaster, "Walls")
	# timber frame: corner posts and a beam under the roof (skipped on web/Android: 12 draw calls per house)
	for sx_ in ([] if low_end() else [-1, 1]):
		for sz_ in [-1, 1]:
			var post := BoxMesh.new()
			post.size = Vector3(0.22, wall_h - base_h, 0.22)
			_mesh(root, post, Vector3(sx_ * (w / 2.0 - 0.05), -h / 2.0 + base_h + (wall_h - base_h) / 2.0, sz_ * (d / 2.0 - 0.05)), wood, "Post")
	for side in ([] if low_end() else [-1, 1]):
		var beam_x := BoxMesh.new()
		beam_x.size = Vector3(w + 0.1, 0.2, 0.2)
		_mesh(root, beam_x, Vector3(0, top_y - 0.1, side * (d / 2.0 - 0.05)), wood, "BeamX")
		var beam_z := BoxMesh.new()
		beam_z.size = Vector3(0.2, 0.2, d + 0.1)
		_mesh(root, beam_z, Vector3(side * (w / 2.0 - 0.05), top_y - 0.1, 0), wood, "BeamZ")
	# roof from the kit: ridge along the longer side
	var long_x := w >= d
	var long_len := maxf(w, d)
	var short_len := minf(w, d)
	var ratio := long_len / short_len
	var roof_name := "Roof_RoundTiles_4x4"
	if short_len >= 8.0:
		roof_name = "Roof_RoundTiles_8x8" if ratio < 1.2 else ("Roof_RoundTiles_8x10" if ratio < 1.5 else "Roof_RoundTiles_8x12")
	elif short_len >= 6.0:
		roof_name = "Roof_RoundTiles_6x6" if ratio < 1.2 else ("Roof_RoundTiles_6x8" if ratio < 1.5 else "Roof_RoundTiles_6x10")
	else:
		roof_name = "Roof_RoundTiles_4x4" if ratio < 1.2 else ("Roof_RoundTiles_4x6" if ratio < 1.6 else "Roof_RoundTiles_4x8")
	var pivot := Node3D.new()
	pivot.name = "RoofPivot"
	pivot.position = Vector3(0, top_y, 0)
	pivot.rotation.y = 0.0 if not long_x else PI / 2.0
	root.add_child(pivot)
	var rb := model_box(roof_name)
	var sy := clampf((short_len + 1.2) / rb.size.x, 0.7, 1.5)
	var roof := _fit(pivot, roof_name, short_len + 1.2, long_len + 1.2, sy)
	if roof:
		roof.name = "Roof"
		var tiles := village_surface("RoundTiles", Color(0.95, 0.62, 0.45) if not night else Color(0.75, 0.55, 0.5), 0.4)
		for mi in roof.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = tiles
	# door with frame on the front (+z) face, bottom at the floor
	var frame := _place(root, "DoorFrame_Round_WoodDark", Vector3(0, -h / 2.0, d / 2.0 - 0.1), 1.0, 0.0)
	if frame:
		frame.name = "DoorFrame"
	var door := _place(root, "Door_1_Round", Vector3(0, -h / 2.0, d / 2.0 + 0.02), 1.0, 0.0)
	if door:
		door.name = "Door"
	# chimney on the roof
	var chim := _place(root, "Prop_Chimney", Vector3(w * 0.25 if long_x else w * 0.3, top_y + 1.0, d * 0.15 if long_x else d * 0.25), 1.0, 0.0)
	if chim:
		chim.name = "Chimney"
	# windows: two on each long face, warm light at night
	var win_mat := glow(Color(1.0, 0.78, 0.45)) if night else glow(Color(0.55, 0.7, 0.85))
	win_mat.emission_energy_multiplier = 2.0 if night else 0.25
	var wh := clampf(wall_h * 0.28, 0.6, 1.0)
	for sd in [-1, 1]:
		for k in [-1, 1]:
			var win := BoxMesh.new()
			win.size = Vector3(0.7, wh, 0.05)
			_mesh(root, win, Vector3(k * w * 0.28, -h / 2.0 + base_h + (wall_h - base_h) * 0.55, sd * (d / 2.0 + 0.01)), win_mat, "Window")


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
	if size.x >= 4.0 and size.z >= 4.0 and ResourceLoader.exists(VILLAGE_TEX % "Plaster") and world_style.get("boundary", "") != "":
		_village_house(root, prop_name, size, world_style)
		return true
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
	var exit_pts := PackedVector2Array()
	for x in layout.get("exits", []):
		exit_pts.append(Vector2(float(x.pos[0]), float(x.pos[2])))
	var town := world_of(area_id) == "WORLD_VALDORIA"
	var low := low_end()
	# web/Android: wider spacing and no 4,700-triangle twisted trees
	var inner: Array = rows[0]
	var outer: Array = rows[1]
	if low:
		outer = outer.filter(func(m): return not str(m).begins_with("TwistedTree"))
		if outer.is_empty():
			outer = ["Pine_1", "Pine_2"]
	# [models, distance beyond the edge, spacing, min scale, max scale]
	var specs := [[inner, 5.0, 12.0 if low else 7.5, 4.5 if not town else 6.0, 6.5 if not town else 8.0], [outer, 18.0, 24.0 if low else 10.0, 7.0, 10.0]]
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
				var edge := Vector2(clampf(p.x, -size.x / 2.0, size.x / 2.0), clampf(p.y, -size.y / 2.0, size.y / 2.0))
				var near_exit := false
				for e in exit_pts:
					if e.distance_squared_to(edge) < 49.0:
						near_exit = true
						break
				if near_exit:
					continue
				var models: Array = spec[0]
				var nm: String = models[rng.randi() % models.size()]
				var yaw := atan2(-p.x, -p.y) if town else rng.randf() * TAU
				if ResourceLoader.exists(NATURE_DIR % nm):
					# metre-scaled nature model: inner row 7-12 m, outer row 14-24 m
					var tall := rng.randf_range(7.0, 12.0) if spec[1] < 10.0 else rng.randf_range(14.0, 24.0)
					_no_shadow(_place_h(root, nm, Vector3(p.x, -0.05, p.y), tall, yaw))
				else:
					_no_shadow(_place(root, nm, Vector3(p.x, -0.05, p.y), rng.randf_range(spec[3], spec[4]), yaw))


## Far scenery does not need to cast shadows (they would fall outside the shadow range anyway).
static func _no_shadow(n: Node3D) -> void:
	if n == null:
		return
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Small hand-placed dressing from layout "decor" (G05): KayKit models or
## procedural lanterns, with an optional thin collider ("r", metres) so the
## player does not walk through barrels. Scale 1 = hex-pack units × DECOR_SCALE.
const DECOR_SCALE := 5.0
## KayKit decor names that now use the metre-scaled kits: name -> [model, scale (or tree height in m at scale 1)]
const DECOR_MAP := {
	"tree_single_A": ["@tree", 6.5], "tree_single_B": ["@tree", 6.5],
	"rock_single_A": ["Rock_Medium_1", 0.8], "rock_single_B": ["Rock_Medium_2", 0.8], "rock_single_C": ["Rock_Medium_3", 0.8],
	"barrel": ["Barrel", 1.0], "crate_A_big": ["Crate_Wooden", 1.0], "crate_B_small": ["Crate_Wooden", 0.7],
	"bucket_water": ["Bucket_Wooden_1", 1.0], "weaponrack": ["WeaponStand", 1.0], "fence_wood_straight": ["Prop_WoodenFence_Single", 1.0],
}


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
		elif DECOR_MAP.has(d.model) and (DECOR_MAP[d.model][0] == "@tree" or is_metric(DECOR_MAP[d.model][0])):
			var m: Array = DECOR_MAP[d.model]
			var variant: String = m[0] if m[0] != "@tree" else TREES[absi(int(pos.x * 7.0 + pos.z * 13.0)) % TREES.size()]
			if m[0] == "@tree":
				n = _place_h(root, variant, pos, float(m[1]) * float(d.get("scale", 1.0)), yaw)
			else:
				n = _place(root, variant, pos, float(m[1]) * float(d.get("scale", 1.0)), yaw)
		else:
			n = _place(root, d.model, pos, (1.0 if is_metric(d.model) else DECOR_SCALE) * float(d.get("scale", 1.0)), yaw)
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


## Falling snow over the whole area (Frosthain): one CPUParticles3D, fewer flakes on web/Android.
static func build_weather(parent: Node3D, area_id: String, layout: Dictionary, size: Vector2) -> void:
	var st := style(area_id)
	if is_indoor(area_id, layout):
		return
	if st.has("motes"):
		_build_motes(parent, st.motes, size)
	if not (st.get("snow", false) or st.get("embers", false)):
		return
	var embers: bool = st.get("embers", false)
	var p := CPUParticles3D.new()
	p.name = "Embers" if embers else "Snow"
	p.amount = 160 if low_end() else 700
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(size.x / 2.0, 0.5, size.y / 2.0)
	p.position = Vector3(0, 1 if st.get("embers", false) else 12, 0)
	p.direction = Vector3(0.15, 1.0 if embers else -1.0, 0.05)
	p.spread = 12.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.2
	p.gravity = Vector3(0.2, 0.2 if embers else -0.3, 0.0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.55, 0.2, 0.95) if embers else Color(1, 1, 1, 0.9)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = mat
	p.mesh = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)


## Ambient particles per world: fireflies, pollen, dust, bubbles. A few soft glowing quads that
## drift around the player's end of the area (fewer on web/Android).
static func _build_motes(parent: Node3D, cfg: Dictionary, size: Vector2) -> void:
	var p := CPUParticles3D.new()
	p.name = "Motes"
	p.amount = int(cfg.amount) / (3 if low_end() else 1)
	p.lifetime = float(cfg.life)
	p.preprocess = float(cfg.life)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(size.x / 2.0, float(cfg.h) / 2.0, size.y / 2.0)
	p.position = Vector3(0, float(cfg.y), 0)
	p.direction = Vector3(1, 0.3, 0.4)
	p.spread = 180.0
	p.initial_velocity_min = float(cfg.vxz) * 0.4
	p.initial_velocity_max = float(cfg.vxz)
	p.gravity = Vector3(0, float(cfg.vy), 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.5
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * float(cfg.size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.html(cfg.color)
	mat.albedo_color.a = 0.8
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = mat
	p.mesh = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)


## Footprints of houses, roads and water (x/z rectangles) that dressing and flora keep clear.
static func _blocked_rects(layout: Dictionary) -> Array[Rect2]:
	var blocked: Array[Rect2] = []
	for p in layout.get("props", []):
		blocked.append(Rect2(float(p.pos[0]) - float(p.size[0]) / 2.0 - 0.8, float(p.pos[2]) - float(p.size[2]) / 2.0 - 0.8, float(p.size[0]) + 1.6, float(p.size[2]) + 1.6))
	for d in layout.get("decor", []):
		if d.has("size"):
			blocked.append(Rect2(float(d.pos[0]) - float(d.size[0]) / 2.0 - 0.5, float(d.pos[2]) - float(d.size[1]) / 2.0 - 0.5, float(d.size[0]) + 1.0, float(d.size[1]) + 1.0))
	return blocked


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
	"WORLD_ELYNDRA": {"grass": ["Grass_Wispy_Short"], "flowers": [], "mush": [], "tint": "#58c8d0", "flower_tint": "#ffffff", "count": 600, "flower_count": 0, "mush_count": 0, "glow": "#80fff0", "glow_count": 140},
	"WORLD_ASTRALIS": {"grass": ["Grass_Wispy_Short", "Grass_Common_Short"], "flowers": ["Flower_3_Group"], "mush": [], "tint": "#c8b8ff", "flower_tint": "#ffe8ff", "count": 900, "flower_count": 120, "mush_count": 0, "glow": "#ffe0a0", "glow_count": 140},
	"WORLD_NOCTARIS": {"grass": ["Grass_Wispy_Short"], "flowers": [], "mush": [], "tint": "#8a7ac8", "flower_tint": "#ffffff", "count": 700, "flower_count": 0, "mush_count": 0, "glow": "#b080ff", "glow_count": 120},
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
	var blocked := _blocked_rects(layout)
	var exit_pts := PackedVector2Array()
	for x in layout.get("exits", []):
		exit_pts.append(Vector2(float(x.pos[0]), float(x.pos[2])))
	var root := Node3D.new()
	root.name = "Flora"
	parent.add_child(root)
	var low := low_end()
	var div := 2 if low else 1
	# web/Android: only the cheapest models (about 50-90 triangles) and no mushrooms
	var grass_models: Array = ["Grass_Common_Short"] if low else cfg.grass
	var flower_models: Array = (["Flower_3_Single"] if not cfg.flowers.is_empty() else []) if low else cfg.flowers
	var mush_models: Array = [] if low else cfg.mush
	var groups := [["Grass", grass_models, Color.html(cfg.tint), int(cfg.count) / div, 0.2, 0.4], ["Flowers", flower_models, Color.html(cfg.flower_tint), int(cfg.flower_count) / div, 0.25, 0.42], ["Mushrooms", mush_models, Color(1, 1, 1), int(cfg.mush_count) / div, 0.35, 0.7]]
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
			var chunks := {}  # cell -> Array[Transform3D]
			var placed := 0
			var tries := 0
			while placed < per and tries < per * 3:
				tries += 1
				var p := Vector2(rng.randf_range(-size.x / 2.0 + 1.0, size.x / 2.0 - 1.0), rng.randf_range(-size.y / 2.0 + 1.0, size.y / 2.0 - 1.0))
				if _free_spot(p, blocked, exit_pts):
					var sc := rng.randf_range(g[4], g[5])
					var cell := Vector2i(floori(p.x / FLORA_CELL), floori(p.y / FLORA_CELL))
					if not chunks.has(cell):
						chunks[cell] = [] as Array[Transform3D]
					(chunks[cell] as Array[Transform3D]).append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), Vector3(p.x, 0.0, p.y)))
					placed += 1
					if g[0] == "Grass" and glow_pts.size() < int(cfg.glow_count) / div and rng.randf() < 0.05:
						glow_pts.append(Vector3(p.x, 0.0, p.y))
			for cell in chunks:
				_multimesh(root, mesh, chunks[cell], "%s_%s_%d_%d" % [g[0], nm, cell.x, cell.y], Vector3((cell.x + 0.5) * FLORA_CELL, 0.0, (cell.y + 0.5) * FLORA_CELL), 38.0 if low else 70.0)
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


## Edge length (m) of one flora chunk: each chunk is culled by the camera frustum and by distance.
const FLORA_CELL := 14.0


## True if a flora/dressing spot is clear of houses, roads, water and the exits (plain loops: no lambdas, this runs thousands of times).
static func _free_spot(p: Vector2, blocked: Array[Rect2], exit_pts: PackedVector2Array) -> bool:
	for r in blocked:
		if r.has_point(p):
			return false
	for e in exit_pts:
		if e.distance_squared_to(p) < 25.0:
			return false
	return true


## `origin` re-bases the transforms so the node sits in the middle of its chunk (needed for the
## distance cut-off); `range_end` > 0 hides the chunk beyond that distance.
static func _multimesh(parent: Node3D, mesh: Mesh, xforms: Array[Transform3D], nm: String, origin := Vector3.ZERO, range_end := 0.0) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		var t := xforms[i]
		t.origin -= origin
		mm.set_instance_transform(i, t)
	var mi := MultiMeshInstance3D.new()
	mi.name = nm
	mi.multimesh = mm
	mi.position = origin
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if range_end > 0.0:
		mi.visibility_range_end = range_end
		mi.visibility_range_end_margin = 4.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	parent.add_child(mi)


## Small everyday props around houses (barrels, crates, benches, banners) so
## villages do not look empty (R04). Deterministic per area; keeps roads,
## exits and other buildings free.
const DRESSING := ["Barrel", "Crate_Wooden", "Barrel_Apples", "FarmCrate_Apple", "Bench", "Stool", "Bucket_Wooden_1", "Crate_Metal", "Banner_1"]


static func build_dressing(parent: Node3D, area_id: String, layout: Dictionary) -> void:
	if is_indoor(area_id, layout) or world_of(area_id) == "WORLD_AQUALIS":
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(area_id + "dress")
	var exit_pts := PackedVector2Array()
	for x in layout.get("exits", []):
		exit_pts.append(Vector2(float(x.pos[0]), float(x.pos[2])))
	var rects := _blocked_rects(layout)
	var root := Node3D.new()
	root.name = "Dressing"
	parent.add_child(root)
	for p in layout.get("props", []):
		if prop_kind(str(p.name)) != "house" or p.has("requires_flag") or p.has("hidden_by_flag"):
			continue
		var cx := float(p.pos[0])
		var cz := float(p.pos[2])
		var hx := float(p.size[0]) / 2.0
		var hz := float(p.size[2]) / 2.0
		for k in 3:
			var nm: String = DRESSING[rng.randi() % DRESSING.size()]
			var side := rng.randi() % 4
			var along := rng.randf_range(-0.7, 0.7)
			var pos := Vector3.ZERO
			var yaw := 0.0
			match side:
				0: pos = Vector3(cx + along * hx, 0, cz + hz + 0.9); yaw = 0.0
				1: pos = Vector3(cx + along * hx, 0, cz - hz - 0.9); yaw = PI
				2: pos = Vector3(cx + hx + 0.9, 0, cz + along * hz); yaw = PI / 2.0
				_: pos = Vector3(cx - hx - 0.9, 0, cz + along * hz); yaw = -PI / 2.0
			var p2 := Vector2(pos.x, pos.z)
			var near_exit := false
			for e in exit_pts:
				if e.distance_squared_to(p2) < 36.0:
					near_exit = true
					break
			if near_exit:
				continue
			# outside every other footprint (the own house is allowed: the item stands next to it)
			var in_other := false
			for r in rects:
				if r.has_point(p2) and not r.has_point(Vector2(cx, cz)):
					in_other = true
					break
			if in_other:
				continue
			var n := _place(root, nm, pos, 1.0, yaw + rng.randf_range(-0.3, 0.3))
			if n and not nm.begins_with("Banner"):
				var body := StaticBody3D.new()
				body.name = "DressingCollider"
				var cs := CollisionShape3D.new()
				var cyl := CylinderShape3D.new()
				cyl.radius = 0.4
				cyl.height = 1.0
				cs.shape = cyl
				cs.position.y = 0.5
				body.add_child(cs)
				body.position = pos
				root.add_child(body)


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
