class_name ZotikVisual
extends Node3D
## Interim visual for CHAR_ZOTIK_MASTER_001 (orange anthropomorphic creature:
## upright body, large pointed ears, green eyes, light muzzle/chest, large
## bushy tail, green scarf, adventurer outfit). C01: the animated CC0 human
## rig (Quaternius) in the ranger outfit with fur-coloured arms; fox head,
## ears, scarf, tail, bag and blade are attached to its bones. Part
## positions are given in model space (metres, +Y up, +Z = his front) and
## converted per bone, so they follow the animation. Not final art (CLAUDE.md
## rule 6); replace with the production model without touching gameplay code.

var parts := {}
var rig: CharacterRig
var _was_dodging := false
var _model_from_skeleton := Transform3D.IDENTITY

## Interim scale (C-23): Zotik ≈ 1.2 m next to ≈ 1.65–1.8 m humans.
const SCALE := 0.68
const BODY_SPEC := {"outfit": "Male_Ranger", "body": "Male", "human_head": false, "hide": ["Male_Ranger_Head_Hood", "Male_Ranger_Acc_Pauldron"]}


func _ready() -> void:
	rig = CharacterRig.create_human(BODY_SPEC, 1.75)
	add_child(rig)
	scale = Vector3.ONE * SCALE
	_model_from_skeleton = rig.model.global_transform.affine_inverse() * rig.skeleton.global_transform
	_bone_part("Head", "PLACEHOLDER_head", _sphere(0.22), Vector3(0, 1.69, 0.02), Vector3.ZERO, Vector3(1.05, 0.95, 1.0))
	_bone_part("Head", "PLACEHOLDER_cheek_l", _sphere(0.085), Vector3(0.13, 1.61, 0.11), Vector3(0, 0, 30), Vector3(1.3, 0.8, 0.9))
	_bone_part("Head", "PLACEHOLDER_cheek_r", _sphere(0.085), Vector3(-0.13, 1.61, 0.11), Vector3(0, 0, -30), Vector3(1.3, 0.8, 0.9))
	_bone_part("Head", "PLACEHOLDER_muzzle", _sphere(0.075), Vector3(0, 1.62, 0.2), Vector3.ZERO, Vector3(1.0, 0.75, 1.35))
	_bone_part("Head", "PLACEHOLDER_nose", _sphere(0.03), Vector3(0, 1.645, 0.3))
	_bone_part("Head", "PLACEHOLDER_ear_l", _cone(0.1, 0.36), Vector3(0.13, 1.95, -0.01), Vector3(0, 0, -16))
	_bone_part("Head", "PLACEHOLDER_ear_r", _cone(0.1, 0.36), Vector3(-0.13, 1.95, -0.01), Vector3(0, 0, 16))
	_bone_part("Head", "PLACEHOLDER_ear_inner_l", _cone(0.055, 0.24), Vector3(0.13, 1.93, 0.03), Vector3(0, 0, -16))
	_bone_part("Head", "PLACEHOLDER_ear_inner_r", _cone(0.055, 0.24), Vector3(-0.13, 1.93, 0.03), Vector3(0, 0, 16))
	_bone_part("Head", "PLACEHOLDER_eye_l", _sphere(0.042), Vector3(0.085, 1.72, 0.198), Vector3.ZERO, Vector3(0.8, 1.0, 0.6))
	_bone_part("Head", "PLACEHOLDER_eye_r", _sphere(0.042), Vector3(-0.085, 1.72, 0.198), Vector3.ZERO, Vector3(0.8, 1.0, 0.6))
	_bone_part("Head", "PLACEHOLDER_pupil_l", _sphere(0.021), Vector3(0.085, 1.72, 0.222))
	_bone_part("Head", "PLACEHOLDER_pupil_r", _sphere(0.021), Vector3(-0.085, 1.72, 0.222))
	_bone_part("Head", "PLACEHOLDER_hair", _cone(0.13, 0.16), Vector3(0, 1.85, 0.07), Vector3(35, 0, 0))
	# spiky fur: crest, back tufts and cheek fluff (like the master sheet)
	var tufts := [[Vector3(0, 1.9, 0.03), Vector3(-15, 0, 0), 0.17], [Vector3(0.07, 1.89, 0.05), Vector3(-10, 0, -22), 0.15], [Vector3(-0.07, 1.89, 0.05), Vector3(-10, 0, 22), 0.15],
		[Vector3(0.14, 1.85, 0.0), Vector3(0, 0, -48), 0.15], [Vector3(-0.14, 1.85, 0.0), Vector3(0, 0, 48), 0.15], [Vector3(0, 1.83, -0.1), Vector3(-50, 0, 0), 0.15],
		[Vector3(0.19, 1.63, 0.08), Vector3(0, 0, -75), 0.12], [Vector3(-0.19, 1.63, 0.08), Vector3(0, 0, 75), 0.12], [Vector3(0.17, 1.57, 0.1), Vector3(0, 0, -105), 0.1], [Vector3(-0.17, 1.57, 0.1), Vector3(0, 0, 105), 0.1]]
	for k in tufts.size():
		_bone_part("Head", "PLACEHOLDER_tuft_%d" % k, _cone(0.06, tufts[k][2] * 1.4), tufts[k][0], tufts[k][1])
	_bone_part("Head", "PLACEHOLDER_brow_l", _box(Vector3(0.075, 0.014, 0.02)), Vector3(0.085, 1.775, 0.2), Vector3(0, 0, -12))
	_bone_part("Head", "PLACEHOLDER_brow_r", _box(Vector3(0.075, 0.014, 0.02)), Vector3(-0.085, 1.775, 0.2), Vector3(0, 0, 12))
	_bone_part("Head", "PLACEHOLDER_glint_l", _sphere(0.012), Vector3(0.1, 1.735, 0.232))
	_bone_part("Head", "PLACEHOLDER_glint_r", _sphere(0.012), Vector3(-0.07, 1.735, 0.232))
	_bone_part("neck_01", "PLACEHOLDER_scarf", _torus(0.1, 0.18), Vector3(0, 1.44, 0.02), Vector3(8, 0, 0), Vector3(1.0, 1.15, 1.0))
	_bone_part("neck_01", "PLACEHOLDER_scarf_fold", _torus(0.09, 0.2), Vector3(0, 1.4, 0.03), Vector3(-10, 0, 0), Vector3(1.0, 1.0, 1.0))
	_bone_part("spine_03", "PLACEHOLDER_scarf_end2", _box(Vector3(0.07, 0.2, 0.03)), Vector3(-0.1, 1.34, 0.15), Vector3(-10, 0, 14))
	_bone_part("spine_03", "PLACEHOLDER_strap", _box(Vector3(0.035, 0.5, 0.02)), Vector3(0.0, 1.2, 0.14), Vector3(0, 0, 38))
	_bone_part("pelvis", "PLACEHOLDER_buckle", _box(Vector3(0.05, 0.05, 0.02)), Vector3(0, 1.0, 0.175))
	_bone_part("spine_03", "PLACEHOLDER_scarf_end", _box(Vector3(0.08, 0.26, 0.03)), Vector3(0.09, 1.33, 0.15), Vector3(-12, 0, -12))
	_bone_part("neck_01", "PLACEHOLDER_chest", _sphere(0.07), Vector3(0, 1.54, 0.15), Vector3.ZERO, Vector3(1.2, 0.9, 0.6))
	_bone_part("pelvis", "PLACEHOLDER_outfit", _torus(0.15, 0.175), Vector3(0, 1.0, 0))
	# bushy tail: root sphere, a fat curved body and a white tip, held up behind him
	_bone_part("pelvis", "PLACEHOLDER_tail_root", _sphere(0.12), Vector3(0, 1.0, -0.17))
	_bone_part("pelvis", "PLACEHOLDER_tail", _capsule(0.15, 0.5), Vector3(0, 1.12, -0.33), Vector3(-38, 0, 0))
	_bone_part("pelvis", "PLACEHOLDER_tail_mid", _sphere(0.19), Vector3(0, 1.28, -0.43), Vector3.ZERO, Vector3(1.0, 1.25, 1.0))
	_bone_part("pelvis", "PLACEHOLDER_tail_tip", _sphere(0.13), Vector3(0, 1.47, -0.46), Vector3.ZERO, Vector3(1.0, 1.4, 1.0))
	for k in 6:
		var a := k * 1.05
		_bone_part("pelvis", "PLACEHOLDER_tail_tuft_%d" % k, _cone(0.05, 0.17), Vector3(cos(a) * 0.17, 1.2 + k * 0.045, -0.4 - sin(a) * 0.1), Vector3(-25, 0, -cos(a) * 60))
	_bone_part("pelvis", "PLACEHOLDER_shoulder_bag", _box(Vector3(0.11, 0.13, 0.06)), Vector3(0.19, 0.95, 0.02))
	# blade in the right hand (bone space, same grip as CharacterRig weapons)
	var sword: Array = CharacterRig.HUMAN_WEAPONS.sword
	var w := MeshInstance3D.new()
	w.name = "PLACEHOLDER_weapon"
	w.mesh = load(CharacterRig.WEAPON_DIR % sword[0]) as Mesh
	w.position = sword[1]
	w.rotation_degrees = sword[2]
	w.scale = Vector3.ONE * float(sword[3])
	w.material_override = StandardMaterial3D.new()
	rig.attach("hand_r", w)
	parts["PLACEHOLDER_weapon"] = w
	# colour holder for the fur shade (applied to the arms' skin surfaces)
	_part("PLACEHOLDER_body", _capsule(0.01, 0.02), Vector3.ZERO)
	parts["PLACEHOLDER_body"].visible = false
	apply_customization()
	if is_inside_tree() and get_tree().root.has_node("EventBus"):
		EventBus.equipment_changed.connect(update_weapon)


func apply_customization() -> void:
	var fur := Customization.color("fur_shade")
	var outfit := Customization.color("outfit")
	for p in ["PLACEHOLDER_body", "PLACEHOLDER_head", "PLACEHOLDER_ear_l", "PLACEHOLDER_ear_r", "PLACEHOLDER_tail", "PLACEHOLDER_hair", "PLACEHOLDER_cheek_l", "PLACEHOLDER_cheek_r"]:
		_color(p, fur)
	for k in 10:
		_color("PLACEHOLDER_tuft_%d" % k, fur if k < 6 else Color(0.98, 0.92, 0.84))
	for k in 6:
		_color("PLACEHOLDER_tail_tuft_%d" % k, fur)
	_color("PLACEHOLDER_tail_root", fur)
	_color("PLACEHOLDER_tail_mid", fur)
	_color("PLACEHOLDER_brow_l", fur.darkened(0.45))
	_color("PLACEHOLDER_brow_r", fur.darkened(0.45))
	_color("PLACEHOLDER_glint_l", Color.WHITE)
	_color("PLACEHOLDER_glint_r", Color.WHITE)
	_color("PLACEHOLDER_scarf_fold", Customization.color("scarf").darkened(0.15))
	_color("PLACEHOLDER_scarf_end2", Customization.color("scarf"))
	_color("PLACEHOLDER_strap", Color(0.35, 0.22, 0.12))
	_color("PLACEHOLDER_buckle", Color(0.85, 0.7, 0.3))
	for p in ["PLACEHOLDER_muzzle", "PLACEHOLDER_chest", "PLACEHOLDER_tail_tip", "PLACEHOLDER_ear_inner_l", "PLACEHOLDER_ear_inner_r"]:
		_color(p, Color(0.98, 0.92, 0.84))
	_color("PLACEHOLDER_nose", Color(0.15, 0.1, 0.08))
	_color("PLACEHOLDER_pupil_l", Color(0.05, 0.08, 0.05))
	_color("PLACEHOLDER_pupil_r", Color(0.05, 0.08, 0.05))
	_color("PLACEHOLDER_eye_l", Color(0.2, 0.75, 0.3))
	_color("PLACEHOLDER_eye_r", Color(0.2, 0.75, 0.3))
	_color("PLACEHOLDER_scarf", Customization.color("scarf"))
	_color("PLACEHOLDER_scarf_end", Customization.color("scarf"))
	_color("PLACEHOLDER_outfit", outfit)
	_color("PLACEHOLDER_shoulder_bag", Color(0.45, 0.28, 0.15))
	if rig:
		# clothes take a light outfit tint, exposed skin becomes fur
		for mi in rig.meshes():
			if not mi.name.begins_with("Male_Ranger"):
				continue
			for i in mi.mesh.get_surface_count():
				var base := mi.mesh.surface_get_material(i) as StandardMaterial3D
				if base == null:
					continue
				var m := base.duplicate() as StandardMaterial3D
				if base.resource_name.contains("Regular"):
					m.albedo_texture = null
					m.albedo_color = fur
				else:
					m.albedo_color = outfit.lerp(Color.WHITE, 0.55)
				mi.set_surface_override_material(i, m)
	update_weapon()


## Drives the rig from the player state (called every physics frame).
func animate(p: Player) -> void:
	if rig == null:
		return
	if p.dead:
		if rig.state != "death":
			rig.play("death")
		return
	if p.is_dodging and not _was_dodging:
		rig.action("dodge", 1.6)
	_was_dodging = p.is_dodging
	if p.is_blocking and not rig.in_action():
		rig.play("block")
		return
	rig.locomotion(Vector2(p.velocity.x, p.velocity.z).length(), float(p.stats.move_speed))


func hurt() -> void:
	if rig and not rig.in_action():
		rig.action("hit", 1.5)


## Shows the equipped weapon; the Weltenklinge glows (reacts to Zotik).
func update_weapon() -> void:
	var id: String = GameState.equipment.get("weapon", "")
	var w: MeshInstance3D = parts["PLACEHOLDER_weapon"]
	w.visible = id != ""
	var mat := w.material_override as StandardMaterial3D
	mat.albedo_color = Color(0.75, 0.85, 1.0) if id == "WEAPON_WORLD_BLADE_001" else Color(0.7, 0.7, 0.72)
	mat.emission_enabled = id == "WEAPON_WORLD_BLADE_001"
	mat.emission = Color(0.5, 0.4, 1.0)


## Attack animation (light or strong).
func swing(strong: bool = false) -> void:
	if rig and is_inside_tree():
		rig.action("attack_strong" if strong else "attack", 1.8)


func is_weapon_glowing() -> bool:
	return (parts["PLACEHOLDER_weapon"].material_override as StandardMaterial3D).emission_enabled


func part_color(name: String) -> Color:
	return (parts[name].material_override as StandardMaterial3D).albedo_color


func _part(name: String, mesh: Mesh, pos: Vector3, rot := Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot
	mi.material_override = StandardMaterial3D.new()
	add_child(mi)
	parts[name] = mi


## Mesh attached to `bone`; pos/rot are in model space (rest pose), so the
## part keeps its place regardless of how the bone's axes are oriented.
func _bone_part(bone: String, name: String, mesh: Mesh, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = StandardMaterial3D.new()
	var idx := rig.skeleton.find_bone(bone)
	var rest := rig.skeleton.get_bone_global_rest(idx)
	var want := Transform3D(Basis.from_euler(rot * PI / 180.0).scaled(scl), pos)
	mi.transform = rest.affine_inverse() * _model_from_skeleton.affine_inverse() * want
	rig.attach(bone, mi)
	parts[name] = mi


func _color(name: String, c: Color) -> void:
	var m := parts[name].material_override as StandardMaterial3D
	m.albedo_color = c
	Look.rim(m, 0.2)


static func _box(size: Vector3) -> Mesh:
	var m := BoxMesh.new(); m.size = size; return m


static func _capsule(r: float, h: float) -> Mesh:
	var m := CapsuleMesh.new(); m.radius = r; m.height = h; return m


static func _sphere(r: float) -> Mesh:
	var m := SphereMesh.new(); m.radius = r; m.height = r * 2.0; return m


static func _cylinder(top: float, bottom: float, h: float) -> Mesh:
	var m := CylinderMesh.new(); m.top_radius = top; m.bottom_radius = bottom; m.height = h; return m


static func _cone(r: float, h: float) -> Mesh:
	return _cylinder(0.0, r, h)


static func _torus(inner: float, outer: float) -> Mesh:
	var m := TorusMesh.new(); m.inner_radius = inner; m.outer_radius = outer; return m
