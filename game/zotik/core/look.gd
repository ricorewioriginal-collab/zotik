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
const FLOOR_SCALE := {"cobble": 0.55, "wood": 0.6, "rock": 0.3, "grass": 0.25, "forest": 0.25}

static var _cache := {}


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
			_tree(root, size, color)
		"roots":
			var b := BoxMesh.new()
			b.size = size
			_mesh(root, b, Vector3.ZERO, surface("bark", color, 0.4))
		"house":
			_house(root, size, color)
		"wood":
			var b := BoxMesh.new()
			b.size = size
			_mesh(root, b, Vector3.ZERO, surface("wood", color, 0.35))
		_:
			var b := BoxMesh.new()
			b.size = size
			_mesh(root, b, Vector3.ZERO, surface("brick" if world_style.get("boundary", "") == "wall" else "rock", color, 0.3))


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
		mat = surface("grass", ground.darkened(0.1), 0.5)
		h = 3.2
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
