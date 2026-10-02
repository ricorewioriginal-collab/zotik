class_name CharacterRig
extends Node3D
## Animated interim character (graphics pass G02) built on the CC0 KayKit
## Adventurers rigs (assets/characters/kaykit). Shared by Zotik, companions
## and NPCs: scales the model to a target height, turns it to face -Z, plays
## locomotion/action animations and can recolour the palette texture,
## hide body parts and attach extra meshes to bones. Cosmetic only.

const MODELS := {
	"rogue": "res://assets/characters/kaykit/Rogue.glb",
	"rogue_hooded": "res://assets/characters/kaykit/Rogue_Hooded.glb",
	"mage": "res://assets/characters/kaykit/Mage.glb",
	"knight": "res://assets/characters/kaykit/Knight.glb",
	"barbarian": "res://assets/characters/kaykit/Barbarian.glb",
}
## model height in its own units (head top), measured once (G02)
const MODEL_HEIGHT := 2.19
const WEAPON_MESHES := ["Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable", "1H_Sword", "1H_Sword_Offhand", "2H_Sword", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Wand", "2H_Staff", "Spellbook", "Spellbook_open", "Axe", "1H_Axe", "1H_Axe_Offhand", "2H_Axe", "Mug", "Barbarian_Round_Shield"]
const STATES := {
	"idle": "Idle", "walk": "Walking_A", "run": "Running_A", "attack": "1H_Melee_Attack_Chop",
	"attack_strong": "2H_Melee_Attack_Spin", "cast": "Spellcast_Shoot", "hit": "Hit_A",
	"dodge": "Dodge_Forward", "block": "Blocking", "death": "Death_A", "cheer": "Cheer", "interact": "Interact",
}
const LOOPING := ["idle", "walk", "run", "block"]

var kind := ""
var states: Dictionary = STATES
var model: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer
var state := ""
var _action_until := 0.0

static var _palettes := {}


## --- Human characters (C01): CC0 Quaternius Universal Base Characters +
## Modular Character Outfits (Fantasy) + Universal Animation Library. One
## shared skeleton; the base body supplies the head, the outfit the clothes.
const HUMAN_DIR := "res://assets/characters/quaternius/%s.gltf"
const HUMAN_ANIMS := "res://assets/characters/quaternius/ual_anims.res"
const HUMAN_HEIGHT := 1.81
const HUMAN_STATES := {
	"idle": "Idle_Loop", "walk": "Walk_Loop", "run": "Jog_Fwd_Loop", "attack": "Sword_Attack",
	"attack_strong": "Punch_Cross", "cast": "Spell_Simple_Shoot", "hit": "Hit_Chest",
	"dodge": "Roll", "block": "Sword_Idle", "death": "Death01", "cheer": "Dance_Loop", "interact": "Interact",
	"talk": "Idle_Talking_Loop",
}
const HUMAN_LOOPING := ["Idle_Loop", "Walk_Loop", "Jog_Fwd_Loop", "Sprint_Loop", "Sword_Idle", "Idle_Talking_Loop", "Dance_Loop"]
## weapon meshes borrowed from the KayKit packs: [source model, mesh, offset, rotation°, scale]
const HUMAN_WEAPONS := {
	"staff": ["mage", "2H_Staff", Vector3(0.0, 0.02, 0.0), Vector3(180, 0, 0), 0.62],
	"crossbow": ["rogue", "2H_Crossbow", Vector3(0.0, 0.03, 0.02), Vector3(180, 0, 0), 0.55],
	"axe": ["barbarian", "1H_Axe", Vector3(0.0, 0.03, 0.0), Vector3(180, 0, 0), 0.6],
	"shield": ["barbarian", "Barbarian_Round_Shield", Vector3(0.0, 0.0, 0.08), Vector3(0, 90, 0), 0.55],
	"sword": ["knight", "1H_Sword", Vector3(0.0, 0.03, 0.0), Vector3(180, 0, 0), 0.6],
}
static var _human_anims: AnimationLibrary


## spec: {outfit: "Male_Ranger"|…, body: "Male"|"Female", hair: "Hair_Long"|…|"",
## beard: bool, hair_color: Color, tint: Color (outfit), hide: [mesh names],
## right: weapon key, left: weapon key}
static func create_human(spec: Dictionary, height: float) -> CharacterRig:
	var r := CharacterRig.new()
	r.kind = "human_" + str(spec.get("outfit", "Male_Peasant")).to_lower()
	r.name = "Rig"
	r.states = HUMAN_STATES
	r.model = (load(HUMAN_DIR % spec.get("outfit", "Male_Peasant")) as PackedScene).instantiate()
	r.model.name = "Model"
	r.model.scale = Vector3.ONE * (height / HUMAN_HEIGHT)
	r.model.rotation.y = PI
	r.add_child(r.model)
	r.skeleton = r.model.find_children("*", "Skeleton3D", true, false)[0]
	var tint: Color = spec.get("tint", Color.WHITE)
	if tint != Color.WHITE:
		r.tint_clothes(tint)
	# human head from the base character (skipped for non-human heads, e.g. Zotik)
	if spec.get("human_head", true):
		var body: Node3D = (load(HUMAN_DIR % ("Superhero_%s_FullBody" % spec.get("body", "Male"))) as PackedScene).instantiate()
		for mi in body.find_children("*", "MeshInstance3D", true, false):
			var moved := _move_mesh(mi, r.skeleton)
			moved.mesh = _head_only(mi.mesh)  # the outfit brings its own body
		body.free()
	var hairs: Array = []
	if str(spec.get("hair", "")) != "":
		hairs.append(spec.hair)
	if spec.get("beard", false):
		hairs.append("Hair_Beard")
	for h in hairs:
		var hs: Node3D = (load(HUMAN_DIR % h) as PackedScene).instantiate()
		for mi in hs.find_children("*", "MeshInstance3D", true, false):
			var moved := _move_mesh(mi, r.skeleton)
			if spec.has("hair_color"):
				_color_mesh(moved, spec.hair_color)
		hs.free()
	r.hide_parts(spec.get("hide", []))
	r.anim = AnimationPlayer.new()
	r.anim.name = "AnimationPlayer"
	r.model.add_child(r.anim)
	r.anim.root_node = NodePath("..")
	if _human_anims == null:
		_human_anims = load(HUMAN_ANIMS)
		for n in _human_anims.get_animation_list():
			if n in HUMAN_LOOPING:
				_human_anims.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	r.anim.add_animation_library("", _human_anims)
	for side in [["right", "hand_r"], ["left", "hand_l"]]:
		if spec.has(side[0]):
			r._human_weapon(str(spec[side[0]]), side[1])
	r.play("idle")
	return r


## The base body is one mesh (head + body) and bulkier than the outfits;
## keep only triangles above the neck. Cached per mesh.
const NECK_Y := 1.5
static var _heads := {}


static func _head_only(mesh: Mesh) -> Mesh:
	if _heads.has(mesh):
		return _heads[mesh]
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var keep := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			if verts[idx[t]].y > NECK_Y and verts[idx[t + 1]].y > NECK_Y and verts[idx[t + 2]].y > NECK_Y:
				keep.append(idx[t])
				keep.append(idx[t + 1])
				keep.append(idx[t + 2])
		if keep.is_empty():
			continue
		arrays[Mesh.ARRAY_INDEX] = keep
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, mesh.surface_get_format(s) & ~Mesh.ARRAY_FORMAT_INDEX | Mesh.ARRAY_FORMAT_INDEX)
		out.surface_set_material(out.get_surface_count() - 1, mesh.surface_get_material(s))
	_heads[mesh] = out
	return out


## Re-parents a skinned mesh from another scene with the same skeleton.
static func _move_mesh(mi: MeshInstance3D, skeleton: Skeleton3D) -> MeshInstance3D:
	var copy := MeshInstance3D.new()
	copy.name = mi.name
	copy.mesh = mi.mesh
	copy.skin = mi.skin
	for i in mi.get_surface_override_material_count():
		copy.set_surface_override_material(i, mi.get_surface_override_material(i))
	skeleton.add_child(copy)
	copy.skeleton = NodePath("..")
	return copy


static func _color_mesh(mi: MeshInstance3D, c: Color) -> void:
	for i in mi.mesh.get_surface_count():
		var m := mi.get_active_material(i)
		if m is StandardMaterial3D:
			var dup := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
			dup.albedo_color = c
			mi.set_surface_override_material(i, dup)


func _human_weapon(key: String, bone: String) -> void:
	var w: Array = HUMAN_WEAPONS.get(key, [])
	if w.is_empty():
		return
	var src: Node = (load(MODELS[w[0]]) as PackedScene).instantiate()
	var found: Array = src.find_children(w[1], "MeshInstance3D", true, false)
	if not found.is_empty():
		var mi := MeshInstance3D.new()
		mi.name = "Weapon_" + key
		mi.mesh = (found[0] as MeshInstance3D).mesh
		mi.position = w[2]
		mi.rotation_degrees = w[3]
		mi.scale = Vector3.ONE * float(w[4])
		attach(bone, mi)
	src.free()


static func create(model_kind: String, height: float) -> CharacterRig:
	var r := CharacterRig.new()
	r.kind = model_kind
	r.name = "Rig"
	var scene: PackedScene = load(MODELS[model_kind])
	r.model = scene.instantiate()
	r.model.name = "Model"
	r.model.scale = Vector3.ONE * (height / MODEL_HEIGHT)
	r.model.rotation.y = PI  # KayKit faces +Z, the game faces -Z
	r.add_child(r.model)
	r.skeleton = r.model.find_children("*", "Skeleton3D", true, false)[0]
	r.anim = r.model.find_children("*", "AnimationPlayer", true, false)[0]
	for a in LOOPING:
		var res := r.anim.get_animation(STATES[a])
		if res:
			res.loop_mode = Animation.LOOP_LINEAR
	r.show_weapons([])
	r.play("idle")
	return r


func meshes() -> Array:
	return skeleton.find_children("*", "MeshInstance3D", true, false)


func show_weapons(names: Array) -> void:
	for mi in meshes():
		if mi.name in WEAPON_MESHES:
			mi.visible = mi.name in names


func hide_parts(names: Array) -> void:
	for mi in meshes():
		if mi.name in names:
			mi.visible = false


## Mesh attached to a bone; position/rotation in model units (before scaling).
func attach(bone: String, node: Node3D) -> BoneAttachment3D:
	var ba := BoneAttachment3D.new()
	ba.name = "Attach_" + bone.replace(".", "_") + "_" + node.name
	ba.bone_name = bone
	skeleton.add_child(ba)
	ba.add_child(node)
	return ba


## Replaces palette colours: rules = [[predicate(Color) -> bool, Color target]]
## applied per pixel, keeping each cell's gradient (value) shape.
func recolor(key: String, rules: Array) -> void:
	var tex: Texture2D
	if _palettes.has(key):
		tex = _palettes[key]
	else:
		var src: Texture2D = _first_material().albedo_texture
		var img := src.get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				for r in rules:
					if (r[0] as Callable).call(c):
						var t: Color = r[1]
						img.set_pixel(x, y, Color.from_hsv(t.h, t.s, clampf(t.v * (c.v / 0.9), 0.0, 1.0)))
						break
		img.generate_mipmaps()
		tex = ImageTexture.create_from_image(img)
		_palettes[key] = tex
	for mi in meshes():
		for s in mi.mesh.get_surface_count():
			var m: Material = mi.mesh.surface_get_material(s)
			if m is StandardMaterial3D:
				var dup := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_texture = tex
				mi.set_surface_override_material(s, dup)


## Tints clothing surfaces only; the outfits' exposed-skin surfaces use the
## "MI_Regular_*" materials and keep their skin colour.
func tint_clothes(c: Color) -> void:
	for mi in meshes():
		for s in mi.mesh.get_surface_count():
			var m: Material = mi.get_active_material(s)
			if m is StandardMaterial3D and not m.resource_name.contains("Regular"):
				var dup := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_color = c
				mi.set_surface_override_material(s, dup)


func tint(c: Color) -> void:
	for mi in meshes():
		for s in mi.mesh.get_surface_count():
			var m: Material = mi.get_active_material(s)
			if m is StandardMaterial3D:
				var dup := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_color = c
				mi.set_surface_override_material(s, dup)


func _first_material() -> StandardMaterial3D:
	for mi in meshes():
		if mi.visible and mi.mesh and mi.mesh.get_surface_count() > 0 and mi.mesh.surface_get_material(0) is StandardMaterial3D:
			return mi.mesh.surface_get_material(0)
	return StandardMaterial3D.new()


func play(s: String, speed: float = 1.0) -> void:
	if s == state and anim.is_playing():
		return
	state = s
	anim.play(states.get(s, states.idle), 0.15, speed)


## One-shot action (attack, hit, dodge …); locomotion resumes afterwards.
func action(s: String, speed: float = 1.0) -> void:
	state = ""
	play(s, speed)
	var res := anim.get_animation(states.get(s, states.idle))
	_action_until = Time.get_ticks_msec() / 1000.0 + (res.length / speed if res else 0.4)


func in_action() -> bool:
	return Time.get_ticks_msec() / 1000.0 < _action_until


## Picks idle/walk/run from the horizontal speed unless an action is playing.
func locomotion(speed: float, run_speed: float = 4.0) -> void:
	if in_action() or state == "death":
		return
	if speed < 0.3:
		play("idle")
	elif speed < run_speed * 0.6:
		play("walk")
	else:
		play("run")
