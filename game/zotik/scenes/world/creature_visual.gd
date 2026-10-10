class_name CreatureVisual
extends Node3D
## Procedural interim creature models for enemies and bosses (graphics pass
## G03), following the enemy master sheet: dark bodies with emissive rift
## crystals and eyes. Archetypes: imp (Rissling), wolf, golem, mushroom,
## slime, crab, roots, dummy. Animated from the enemy state (idle bob, walk
## cycle, wind-up, strike lunge, break wobble, death). Cosmetic only; the
## enemy's collision and logic are unchanged. Not final art.
## Entries listed in MODELS use a rigged, animated CC0 model (Quaternius
## "Ultimate Animated Monsters / Easy Enemies", assets/enemies) instead of the
## procedural parts: same animate()/lunge()/die()/set_tint() interface.

const ARCHETYPES := {
	"ENEMY_TRAINING_DUMMY_001": ["dummy", "#ffd27a"],
	"ENEMY_RIFTLING_001": ["imp", "#b060ff"],
	"ENEMY_MOONWOLF_001": ["wolf", "#6cc8ff"],
	"BOSS_ORUN_001": ["golem", "#b060ff"],
	"ENEMY_PILZLING_001": ["mushroom", "#ffe27a"],
	"ENEMY_DORNENWOLF_001": ["wolf", "#9ae060"],
	"ENEMY_WURZELKRIECHER_001": ["roots", "#9ae060"],
	"BOSS_WURZELKOENIGIN_001": ["queen", "#a8ff70"],
	"ENEMY_SCHLEUSENKRABBE_001": ["crab", "#7ad0ff"],
	"ENEMY_ROSTGOLEM_001": ["golem", "#ff8a3a"],
	"BOSS_KANALWAECHTER_001": ["golem", "#4ab0ff"],
	"ENEMY_SANDGEIST_001": ["imp", "#f0c070"],
	"ENEMY_SANDWAECHTER_001": ["golem", "#e8b050"],
	"BOSS_KHAROS_001": ["golem", "#d9a040"],
	"ENEMY_RIFFKRABBE_001": ["crab", "#ff8a7a"],
	"ENEMY_LEUCHTQUALLE_001": ["slime", "#9af0ff"],
	"ENEMY_ARCHIVWAECHTER_001": ["golem", "#5ac8c0"],
	"BOSS_NERYX_001": ["queen", "#58e0f0"],
	"ENEMY_FROSTWOLF_001": ["wolf", "#bfe4ff"],
	"ENEMY_EISGEIST_001": ["imp", "#d8f6ff"],
	"ENEMY_EISWAECHTER_001": ["golem", "#9ad0f0"],
	"BOSS_AVARN_001": ["golem", "#8ac8ff"],
	"ENEMY_FUNKENGEIST_001": ["imp", "#ffd060"],
	"ENEMY_SCHMIEDEGOLEM_001": ["golem", "#ff8a40"],
	"BOSS_MAGMARION_001": ["golem", "#ff7020"],
	"ENEMY_SANDSKORPION_001": ["model", "#e8b86a"],
	"ENEMY_ASCHEKAEFER_001": ["model", "#ff7a3a"],
	"ENEMY_KANALSCHLEIM_001": ["model", "#7affc0"],
	"ENEMY_MONDFLEDERMAUS_001": ["model", "#8ad0ff"],
	"ENEMY_GRUENSCHLEIM_001": ["model", "#a8ff70"],
	"ENEMY_WALDSPINNE_001": ["model", "#9ae060"],
	"ENEMY_SUMPFFROSCH_001": ["model", "#c8ff80"],
	"ENEMY_KANALRATTE_001": ["model", "#ffb070"],
	"ENEMY_DUENENSCHLANGE_001": ["model", "#f0c070"],
	"ENEMY_WUESTENSKELETT_001": ["model", "#f0d890"],
	"ENEMY_RIFFFROSCH_001": ["model", "#58e0f0"],
	"ENEMY_ERTRUNKENER_001": ["model", "#58e0f0"],
	"ENEMY_EISFLEDERMAUS_001": ["model", "#d8f6ff"],
	"ENEMY_FROSTSPINNE_001": ["model", "#bfe4ff"],
	"ENEMY_GLUEHWESPE_001": ["model", "#ffd060"],
	"ENEMY_GLUTDRACHE_001": ["model", "#ff8a40"],
	"ENEMY_SCHATTENFALTER_001": ["model", "#b080ff"],
	"ENEMY_VERGESSENER_001": ["model", "#a090e0"],
	"ENEMY_NULLWAECHTER_001": ["golem", "#b080ff"],
	"BOSS_ERINNERUNGSHUETER_001": ["golem", "#d0a8ff"],
	"ENEMY_WOLKENSCHWINGE_001": ["model", "#ffe080"],
	"ENEMY_STERNENWAECHTER_001": ["model", "#ffe8a0"],
	"ENEMY_TEMPELWAECHTER_001": ["golem", "#ffe080"],
	"BOSS_SOLYRA_001": ["golem", "#fff0c0"],
	"ENEMY_SPIEGELSPINNE_001": ["model", "#a0fff0"],
	"ENEMY_ECHOKRIEGER_001": ["model", "#c0d0ff"],
	"ENEMY_WELTENWAECHTER_001": ["golem", "#80f0ff"],
	"BOSS_ELYON_001": ["golem", "#c0ffff"],
	"BOSS_END_WAECHTER_001": ["golem", "#d0a0ff"],
	"BOSS_END_WURZEL_001": ["queen", "#a8ff70"],
	"BOSS_END_KOLOSS_001": ["golem", "#ffd060"],
	"BOSS_END_SANDKOENIG_001": ["golem", "#f0c070"],
	"BOSS_END_ABYSS_001": ["queen", "#58e0f0"],
	"BOSS_END_FROSTHERZ_001": ["golem", "#c8f0ff"],
	"BOSS_END_FEUERKERN_001": ["golem", "#ff8030"],
	"ENEMY_NG_SCHATTENWOLF_001": ["wolf", "#c080ff"],
	"ENEMY_NG_SPINNE_001": ["model", "#ff60a0"],
	"ENEMY_NG_DRACHE_001": ["model", "#ffd040"],
	"ENEMY_NG_WAECHTER_001": ["model", "#40e0ff"],
}

## Rigged models: file (assets/enemies/<file>.fbx), tint (replaces the flat model colour),
## hover (flying: lifted by this many units, bobs), spin (extra yaw so the model faces -Z).
const MODELS := {
	"ENEMY_SANDSKORPION_001": {"file": "Spider", "tint": "#c9a45a"},
	"ENEMY_ASCHEKAEFER_001": {"file": "Wasp", "tint": "#8a3a1a", "hover": 0.5},
	"ENEMY_KANALSCHLEIM_001": {"file": "Slime", "tint": "#5aa86a"},
	"ENEMY_MONDFLEDERMAUS_001": {"file": "Bat", "tint": "#5a4a8a", "hover": 0.7},
	"ENEMY_GRUENSCHLEIM_001": {"file": "Slime", "tint": "#8ad25a"},
	"ENEMY_WALDSPINNE_001": {"file": "Spider", "tint": "#4a5a2a"},
	"ENEMY_SUMPFFROSCH_001": {"file": "Frog", "tint": "#7aa84a"},
	"ENEMY_KANALRATTE_001": {"file": "Rat", "tint": "#7a6a5a"},
	"ENEMY_DUENENSCHLANGE_001": {"file": "Snake", "tint": "#c8a050"},
	"ENEMY_WUESTENSKELETT_001": {"file": "Skeleton", "tint": "#d8c8a0"},
	"ENEMY_RIFFFROSCH_001": {"file": "Frog", "tint": "#3a9ab0"},
	"ENEMY_ERTRUNKENER_001": {"file": "Skeleton", "tint": "#7ab0a8"},
	"ENEMY_EISFLEDERMAUS_001": {"file": "Bat", "tint": "#9ac8e8", "hover": 0.7},
	"ENEMY_FROSTSPINNE_001": {"file": "Spider", "tint": "#8ab8d8"},
	"ENEMY_GLUEHWESPE_001": {"file": "Wasp", "tint": "#e8a020", "hover": 0.6},
	"ENEMY_GLUTDRACHE_001": {"file": "Dragon", "tint": "#a83a1a", "hover": 0.5},
	"ENEMY_SCHATTENFALTER_001": {"file": "Bat", "tint": "#5a3a9a", "hover": 0.7},
	"ENEMY_VERGESSENER_001": {"file": "Skeleton", "tint": "#7a6aa8"},
	"ENEMY_WOLKENSCHWINGE_001": {"file": "Bat", "tint": "#e8b840", "hover": 0.8},
	"ENEMY_STERNENWAECHTER_001": {"file": "Skeleton", "tint": "#d8c070"},
	"ENEMY_SPIEGELSPINNE_001": {"file": "Spider", "tint": "#b8d8e8"},
	"ENEMY_ECHOKRIEGER_001": {"file": "Skeleton", "tint": "#8aa8d8"},
	"ENEMY_NG_SPINNE_001": {"file": "Spider", "tint": "#d04080"},
	"ENEMY_NG_DRACHE_001": {"file": "Dragon", "tint": "#e0b020", "hover": 0.5},
	"ENEMY_NG_WAECHTER_001": {"file": "Skeleton", "tint": "#30c8e0"},
}

## nominal size of a model (longest side) before the enemy's size factor
const MODEL_FIT := 1.6
static var _fit_cache := {}
static var _mat_cache := {}
static var _overlay_cache := {}

var archetype := "imp"
var model_id := ""
var model_hover := 0.0
var ap: AnimationPlayer
var clips := {}
var _attack_t := 0.0
var _meshes: Array[MeshInstance3D] = []
var skin: StandardMaterial3D
var glow_mat: StandardMaterial3D
var root: Node3D          # bobbing/lunging part
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var t := 0.0
var _lunge := 0.0


static func create(enemy_id: String, color: Color) -> CreatureVisual:
	var v := CreatureVisual.new()
	v.name = "Visual"
	var a: Array = ARCHETYPES.get(enemy_id, ["imp", "#b060ff"])
	v.archetype = a[0]
	v.model_id = enemy_id
	v.skin = StandardMaterial3D.new()
	v.skin.albedo_color = color
	v.skin.roughness = 0.75
	v.skin.rim_enabled = true
	v.skin.rim = 0.4
	v.glow_mat = Look.glow(Color.html(a[1]))
	v.glow_mat.emission_energy_multiplier = 1.1
	v.root = Node3D.new()
	v.root.name = "Body"
	v.add_child(v.root)
	v.call("_build_" + v.archetype)
	return v


## `c`: absolute colour for the procedural parts; `mult`: the state multiplier alone
## (white = normal, red = wind-up, gold = broken, bright = hit flash) for models.
func set_tint(c: Color, mult := Color.WHITE) -> void:
	skin.albedo_color = c
	if _meshes.is_empty():
		return
	var ov: Material = null
	if mult.g < 0.6:
		ov = _overlay(Color(1, 0.15, 0.1, 0.45))
	elif mult.r > 2.0:
		ov = _overlay(Color(1, 1, 1, 0.7))
	elif mult.r > 1.2:
		ov = _overlay(Color(1, 0.85, 0.3, 0.45))
	for mi in _meshes:
		mi.material_overlay = ov


static func _overlay(c: Color) -> StandardMaterial3D:
	var k := c.to_html()
	if not _overlay_cache.has(k):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = c
		_overlay_cache[k] = m
	return _overlay_cache[k]


func lunge() -> void:
	_lunge = 1.0
	if ap and clips.has("attack"):
		_attack_t = minf(ap.get_animation(clips.attack).length, 0.9)
		ap.play(clips.attack, 0.05)


## state: Enemy.State as int; speed: horizontal speed.
func animate(state: int, speed: float, delta: float) -> void:
	t += delta
	if ap:
		_animate_model(state, speed, delta)
		return
	_lunge = maxf(0.0, _lunge - delta * 4.0)
	var moving := clampf(speed / 3.0, 0.0, 1.0)
	var bob := sin(t * (10.0 if moving > 0.1 else 2.5)) * (0.06 if moving > 0.1 else 0.025)
	root.position = Vector3(0, bob, -_lunge * 0.5)
	root.rotation = Vector3.ZERO
	match state:
		2:  # WINDUP: rear back
			root.rotation.x = 0.25
			root.position.z = 0.15
		4:  # BROKEN: dazed wobble
			root.rotation.z = sin(t * 6.0) * 0.18
			root.rotation.x = -0.2
	for i in legs.size():
		legs[i].rotation.x = sin(t * 10.0 + PI * i) * 0.6 * moving
	for i in arms.size():
		arms[i].rotation.x = -_lunge * 1.6 + sin(t * 2.0 + i) * 0.05
	if archetype == "slime":
		var sq := 1.0 + sin(t * (8.0 if moving > 0.1 else 3.0)) * 0.08
		root.scale = Vector3(1.0 / sq, sq, 1.0 / sq)


func die() -> void:
	if ap and clips.has("death"):
		ap.play(clips.death, 0.05)
		return
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.2, 0.05, 1.2), 0.35).set_trans(Tween.TRANS_BACK)


# --- builders (units: ~1.6 high before the enemy's size factor) ----------

func _m(mesh: Mesh, pos: Vector3, mat: Material, parent: Node3D = null, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	mi.material_override = mat
	(parent if parent else root).add_child(mi)
	return mi


func _pivot(pos: Vector3, parent: Node3D = null) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	(parent if parent else root).add_child(p)
	return p


static func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new(); s.radius = r; s.height = r * 2.0; return s


static func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new(); c.top_radius = top; c.bottom_radius = bottom; c.height = h; return c


static func _cap(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new(); c.radius = r; c.height = h; return c


static func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new(); b.size = size; return b


func _eyes(y: float, z: float, spread: float, r: float, parent: Node3D = null) -> void:
	for sx in [-1, 1]:
		_m(_sph(r), Vector3(sx * spread, y, z), glow_mat, parent)


func _build_imp() -> void:
	_m(_sph(0.42), Vector3(0, 0.62, 0), skin, null, Vector3.ZERO, Vector3(1, 1.1, 0.9))
	var head := _pivot(Vector3(0, 1.15, -0.05))
	_m(_sph(0.4), Vector3.ZERO, skin, head)
	_eyes(0.04, -0.33, 0.15, 0.11, head)
	for i in 5:
		var a := -50.0 + i * 25.0
		_m(_cyl(0.0, 0.07, 0.45), Vector3(sin(deg_to_rad(a)) * 0.25, 0.38, 0.1), glow_mat, head, Vector3(-25, 0, -a))
	for sx in [-1, 1]:
		_m(_cyl(0.0, 0.12, 0.4), Vector3(sx * 0.36, 0.15, 0), skin, head, Vector3(0, 0, -sx * 70))
		var arm := _pivot(Vector3(sx * 0.42, 0.85, 0))
		_m(_cyl(0.05, 0.08, 0.5), Vector3(0, -0.22, -0.05), skin, arm)
		_m(_cyl(0.0, 0.05, 0.18), Vector3(0, -0.5, -0.1), glow_mat, arm, Vector3(-30, 0, 0))
		arms.append(arm)
		var leg := _pivot(Vector3(sx * 0.18, 0.32, 0))
		_m(_cyl(0.07, 0.09, 0.34), Vector3(0, -0.15, 0), skin, leg)
		legs.append(leg)
	_m(_cyl(0.02, 0.09, 0.7), Vector3(0, 0.45, 0.45), skin, null, Vector3(-60, 0, 0))
	_m(_cyl(0.0, 0.08, 0.25), Vector3(0, 0.75, 0.75), glow_mat, null, Vector3(-60, 0, 0))


func _build_wolf() -> void:
	_m(_cap(0.36, 1.45), Vector3(0, 0.88, 0.05), skin, null, Vector3(90, 0, 0))
	_m(_sph(0.34), Vector3(0, 0.98, -0.5), skin, null, Vector3.ZERO, Vector3(1.05, 1.0, 0.9))
	var head := _pivot(Vector3(0, 1.22, -0.82))
	_m(_sph(0.27), Vector3.ZERO, skin, head, Vector3.ZERO, Vector3(1.0, 0.95, 1.05))
	_m(_cyl(0.07, 0.16, 0.38), Vector3(0, -0.07, -0.3), skin, head, Vector3(-90, 0, 0))
	_m(_sph(0.05), Vector3(0, -0.04, -0.5), Look.glow(Color(0.1, 0.1, 0.12)), head)
	_eyes(0.07, -0.21, 0.12, 0.05, head)
	for sx in [-1, 1]:
		_m(_cyl(0.0, 0.1, 0.32), Vector3(sx * 0.15, 0.28, 0.04), skin, head, Vector3(-10, 0, -sx * 12))
	for i in 6:
		var z := -0.55 + i * 0.22
		_m(_cyl(0.0, 0.06 + 0.02 * (i % 2), 0.32 + 0.1 * (i % 2)), Vector3(0, 1.22 - absf(z) * 0.1, z), glow_mat, null, Vector3(20, 0, 0))
	for p in [Vector3(-0.2, 0.68, -0.48), Vector3(0.2, 0.68, -0.48), Vector3(-0.2, 0.68, 0.52), Vector3(0.2, 0.68, 0.52)]:
		var leg := _pivot(p)
		_m(_cap(0.08, 0.72), Vector3(0, -0.32, 0), skin, leg)
		legs.append(leg)
	_m(_cap(0.16, 0.85), Vector3(0, 1.0, 0.95), skin, null, Vector3(-60, 0, 0), Vector3(1.0, 1.0, 1.2))
	_m(_cyl(0.0, 0.1, 0.28), Vector3(0, 1.32, 1.3), glow_mat, null, Vector3(-60, 0, 0))


func _build_golem() -> void:
	skin = Look.surface("rock", skin.albedo_color, 1.2).duplicate()
	skin.rim_enabled = true
	skin.rim = 0.3
	_m(_sph(0.58), Vector3(0, 1.05, 0), skin, null, Vector3.ZERO, Vector3(1.1, 1.0, 0.85))
	_m(_sph(0.4), Vector3(0, 0.62, 0.02), skin, null, Vector3.ZERO, Vector3(1.0, 0.8, 0.85))
	_m(_sph(0.17), Vector3(0, 1.08, -0.45), glow_mat)
	var head := _pivot(Vector3(0, 1.62, -0.12))
	_m(_sph(0.24), Vector3.ZERO, skin, head, Vector3.ZERO, Vector3(1.1, 0.9, 1.0))
	_eyes(0.02, -0.2, 0.09, 0.045, head)
	for sx in [-1, 1]:
		_m(_cyl(0.0, 0.07, 0.42), Vector3(sx * 0.17, 0.25, 0.02), glow_mat, head, Vector3(-15, 0, -sx * 28))
		_m(_sph(0.3), Vector3(sx * 0.66, 1.38, 0), skin)
		for k in 3:
			_m(_cyl(0.0, 0.06, 0.35 + 0.1 * k), Vector3(sx * (0.6 + 0.08 * k), 1.62, 0.1 - 0.12 * k), glow_mat, null, Vector3(-10 * k, 0, -sx * (15 + 12 * k)))
		var arm := _pivot(Vector3(sx * 0.72, 1.3, 0))
		_m(_cap(0.15, 0.85), Vector3(0, -0.42, 0), skin, arm)
		_m(_sph(0.26), Vector3(0, -0.92, -0.04), skin, arm)
		_m(_cyl(0.0, 0.05, 0.22), Vector3(0, -0.95, -0.28), glow_mat, arm, Vector3(-90, 0, 0))
		arms.append(arm)
		var leg := _pivot(Vector3(sx * 0.28, 0.55, 0))
		_m(_cap(0.17, 0.62), Vector3(0, -0.27, 0), skin, leg)
		legs.append(leg)
	for k in 4:
		_m(_cyl(0.0, 0.08, 0.5), Vector3(-0.25 + 0.17 * k, 1.35, 0.42), glow_mat, null, Vector3(35, 0, -20 + 13 * k))


func _build_queen() -> void:
	_build_golem()
	for i in 7:
		var a := deg_to_rad(i * 360.0 / 7.0)
		_m(_cyl(0.0, 0.06, 0.5), Vector3(cos(a) * 0.22, 2.0, sin(a) * 0.22), glow_mat, null, Vector3(sin(a) * 20, 0, -cos(a) * 20))
	var bark := Look.surface("bark", Color(0.6, 0.5, 0.4), 0.8)
	for sx in [-1, 1]:
		_m(_cyl(0.05, 0.12, 1.4), Vector3(sx * 0.3, 0.75, 0.45), bark, null, Vector3(-30, 0, sx * 15))


func _build_mushroom() -> void:
	_m(_cyl(0.22, 0.28, 0.7), Vector3(0, 0.45, 0), Look.surface("plaster", Color(0.95, 0.9, 0.8), 1.0))
	var cap := _m(_sph(0.55), Vector3(0, 0.9, 0), skin, null, Vector3.ZERO, Vector3(1, 0.6, 1))
	for p in [Vector3(0.25, 0.25, -0.3), Vector3(-0.3, 0.3, -0.1), Vector3(0.05, 0.4, 0.3), Vector3(-0.1, 0.2, -0.45)]:
		_m(_sph(0.09), p, glow_mat, cap)
	_eyes(0.6, -0.26, 0.1, 0.05)
	for sx in [-1, 1]:
		var leg := _pivot(Vector3(sx * 0.13, 0.15, 0))
		_m(_cyl(0.06, 0.07, 0.2), Vector3(0, -0.06, 0), skin, leg)
		legs.append(leg)


func _build_slime() -> void:
	skin.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	skin.albedo_color.a = 0.8
	skin.roughness = 0.1
	_m(_sph(0.6), Vector3(0, 0.5, 0), skin, null, Vector3.ZERO, Vector3(1, 0.85, 1))
	_m(_sph(0.15), Vector3(0, 0.55, 0.05), glow_mat)
	_eyes(0.72, -0.48, 0.17, 0.08)


func _build_crab() -> void:
	_m(_cyl(0.55, 0.6, 0.35), Vector3(0, 0.55, 0), skin, null, Vector3.ZERO, Vector3(1, 1, 0.8))
	_eyes(0.85, -0.32, 0.15, 0.07)
	for sx in [-1, 1]:
		var arm := _pivot(Vector3(sx * 0.55, 0.6, -0.3))
		_m(_cyl(0.06, 0.08, 0.45), Vector3(0, 0, -0.2), skin, arm, Vector3(-90, 0, 0))
		_m(_box(Vector3(0.25, 0.18, 0.35)), Vector3(0, 0.05, -0.5), skin, arm)
		arms.append(arm)
		for i in 3:
			var leg := _pivot(Vector3(sx * 0.5, 0.5, -0.1 + i * 0.22))
			_m(_cyl(0.03, 0.05, 0.55), Vector3(sx * 0.15, -0.2, 0), skin, leg, Vector3(0, 0, sx * 40))
			legs.append(leg)
	for i in 4:
		_m(_cyl(0.0, 0.06, 0.2), Vector3(-0.3 + i * 0.2, 0.78, 0.05), glow_mat)


func _build_roots() -> void:
	var bark := Look.surface("bark", Color(0.7, 0.6, 0.45), 0.8)
	skin = bark.duplicate()
	for i in 6:
		var a := deg_to_rad(i * 60.0)
		_m(_cyl(0.08, 0.22, 1.6), Vector3(cos(a) * 0.35, 0.7, sin(a) * 0.35), skin, null, Vector3(sin(a) * 25, 0, -cos(a) * 25))
	_m(_sph(0.5), Vector3(0, 1.05, 0), skin)
	_eyes(1.15, -0.45, 0.16, 0.08)


func _build_dummy() -> void:
	var wood := Look.surface("wood", Color(0.85, 0.7, 0.5), 1.0)
	skin = wood.duplicate()
	_m(_cyl(0.12, 0.14, 1.5), Vector3(0, 0.75, 0), skin)
	_m(_box(Vector3(1.0, 0.12, 0.12)), Vector3(0, 1.15, 0), skin)
	_m(_sph(0.25), Vector3(0, 1.6, 0), skin)
	_m(_cyl(0.3, 0.3, 0.05), Vector3(0, 1.0, -0.15), glow_mat, null, Vector3(90, 0, 0))


# --- animated models ------------------------------------------------------

## Longest side of the model in its own space, via the node chain (skinned
## meshes keep their AABB in bind pose, the scale sits on the armature nodes).
static func _measure(inst: Node3D) -> Dictionary:
	var box := AABB()
	var first := true
	for n in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var tr := Transform3D.IDENTITY
		var p: Node = mi
		while p != null and p != inst:
			tr = (p as Node3D).transform * tr
			p = p.get_parent()
		var b := tr * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var longest := maxf(box.size.x, maxf(box.size.y, box.size.z))
	return {"scale": MODEL_FIT / maxf(longest, 0.0001), "bottom": Vector3(box.get_center().x, box.position.y, box.get_center().z)}


func _clip(keys: Array) -> String:
	for k in keys:
		for n in ap.get_animation_list():
			if str(n).to_lower().ends_with(k):
				return n
	return ""


func _build_model() -> void:
	var def: Dictionary = MODELS[model_id]
	var inst: Node3D = (load("res://assets/enemies/%s.fbx" % def.file) as PackedScene).instantiate()
	if not _fit_cache.has(def.file):
		_fit_cache[def.file] = _measure(inst)
	var fit: Dictionary = _fit_cache[def.file]
	var wrap := Node3D.new()
	wrap.name = "Model"
	wrap.rotation_degrees.y = float(def.get("spin", 180.0))
	wrap.scale = Vector3.ONE * float(fit.scale)
	wrap.position = -(wrap.basis * fit.bottom)
	model_hover = float(def.get("hover", 0.0))
	wrap.position.y += model_hover
	root.add_child(wrap)
	wrap.add_child(inst)
	var tint := Color.html(def.get("tint", "#ffffff"))
	for n in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in mi.mesh.get_surface_count():
			var key := "%s|%s|%d" % [def.file, tint.to_html(), i]
			if not _mat_cache.has(key):
				var src := mi.get_active_material(i) as BaseMaterial3D
				var m: BaseMaterial3D = src.duplicate() if src else StandardMaterial3D.new()
				m.albedo_color = tint
				m.roughness = 0.75
				m.metallic = 0.0
				m.rim_enabled = true
				m.rim = 0.35
				_mat_cache[key] = m
			mi.set_surface_override_material(i, _mat_cache[key])
		_meshes.append(mi)
	ap = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		return
	clips = {"idle": _clip(["idle", "flying"]), "walk": _clip(["walk", "running", "run", "flying"]), "attack": _clip(["attack"]), "hit": _clip(["hit"]), "death": _clip(["death"])}
	for k in clips.keys():
		if clips[k] == "":
			clips.erase(k)
	for k in ["idle", "walk"]:
		if clips.has(k):
			ap.get_animation(clips[k]).loop_mode = Animation.LOOP_LINEAR
	if clips.has("idle"):
		ap.play(clips.idle)


func _animate_model(state: int, speed: float, delta: float) -> void:
	_lunge = maxf(0.0, _lunge - delta * 4.0)
	_attack_t = maxf(0.0, _attack_t - delta)
	var moving := clampf(speed / 3.0, 0.0, 1.0)
	var bob := sin(t * 3.0) * 0.06 if model_hover > 0.0 else 0.0
	root.position = Vector3(0, bob, -_lunge * 0.5)
	root.rotation = Vector3.ZERO
	match state:
		2:
			root.rotation.x = 0.25
			root.position.z = 0.15
		4:
			root.rotation.z = sin(t * 6.0) * 0.18
			root.rotation.x = -0.2
	if _attack_t > 0.0:
		return
	var want := "idle"
	if state == 4 and clips.has("hit"):
		want = "hit"
	elif moving > 0.1 and clips.has("walk"):
		want = "walk"
	if clips.has(want) and ap.current_animation != clips[want]:
		ap.play(clips[want], 0.15)
