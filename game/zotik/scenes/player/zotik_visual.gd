class_name ZotikVisual
extends Node3D
## Interim visual for CHAR_ZOTIK_MASTER_001 (orange anthropomorphic creature:
## upright body, large pointed ears, green eyes, light muzzle/chest, large
## bushy tail, green scarf, adventurer outfit). G02: an animated CC0 rig body
## recoloured to his fur/outfit palette, with a fox head, ears, tail, scarf,
## bag and blade attached to its bones. Not final art (CLAUDE.md rule 6);
## replace with the production model without touching gameplay code.

var parts := {}
var rig: CharacterRig
var _was_dodging := false

## Interim scale (C-23): Zotik ≈ 1.2 m next to ≈ 1.65–1.8 m humans.
const SCALE := 0.68


func _ready() -> void:
	rig = CharacterRig.create("rogue", 1.75)
	add_child(rig)
	rig.hide_parts(["Rogue_Head", "Rogue_Cape"])
	# head-bone space, model units (front = +Z inside the model)
	_bone_part("head", "PLACEHOLDER_head", _sphere(0.48), Vector3(0, 0.48, 0.02), Vector3.ZERO, Vector3(1.05, 0.95, 1.0))
	_bone_part("head", "PLACEHOLDER_cheek_l", _sphere(0.2), Vector3(0.3, 0.3, 0.18), Vector3(0, 0, 30), Vector3(1.3, 0.8, 0.9))
	_bone_part("head", "PLACEHOLDER_cheek_r", _sphere(0.2), Vector3(-0.3, 0.3, 0.18), Vector3(0, 0, -30), Vector3(1.3, 0.8, 0.9))
	_bone_part("head", "PLACEHOLDER_muzzle", _sphere(0.16), Vector3(0, 0.32, 0.42), Vector3.ZERO, Vector3(1.0, 0.75, 1.35))
	_bone_part("head", "PLACEHOLDER_nose", _sphere(0.065), Vector3(0, 0.37, 0.63))
	_bone_part("head", "PLACEHOLDER_ear_l", _cone(0.19, 0.58), Vector3(0.27, 1.06, -0.02), Vector3(0, 0, -16))
	_bone_part("head", "PLACEHOLDER_ear_r", _cone(0.19, 0.58), Vector3(-0.27, 1.06, -0.02), Vector3(0, 0, 16))
	_bone_part("head", "PLACEHOLDER_ear_inner_l", _cone(0.1, 0.36), Vector3(0.27, 1.0, 0.07), Vector3(0, 0, -16))
	_bone_part("head", "PLACEHOLDER_ear_inner_r", _cone(0.1, 0.36), Vector3(-0.27, 1.0, 0.07), Vector3(0, 0, 16))
	_bone_part("head", "PLACEHOLDER_eye_l", _sphere(0.095), Vector3(0.19, 0.56, 0.4), Vector3.ZERO, Vector3(0.8, 1.0, 0.6))
	_bone_part("head", "PLACEHOLDER_eye_r", _sphere(0.095), Vector3(-0.19, 0.56, 0.4), Vector3.ZERO, Vector3(0.8, 1.0, 0.6))
	_bone_part("head", "PLACEHOLDER_pupil_l", _sphere(0.045), Vector3(0.19, 0.56, 0.455))
	_bone_part("head", "PLACEHOLDER_pupil_r", _sphere(0.045), Vector3(-0.19, 0.56, 0.455))
	_bone_part("head", "PLACEHOLDER_hair", _cone(0.32, 0.36), Vector3(0, 0.9, 0.16), Vector3(35, 0, 0))
	_bone_part("chest", "PLACEHOLDER_scarf", _torus(0.3, 0.41), Vector3(0, 0.18, 0.02))
	_bone_part("chest", "PLACEHOLDER_scarf_end", _box(Vector3(0.18, 0.5, 0.06)), Vector3(0.2, -0.05, -0.36), Vector3(15, 0, -10))
	_bone_part("chest", "PLACEHOLDER_chest", _sphere(0.16), Vector3(0, -0.02, 0.32), Vector3.ZERO, Vector3(1.0, 1.25, 0.5))
	_bone_part("hips", "PLACEHOLDER_outfit", _torus(0.36, 0.46), Vector3(0, 0.12, 0))
	_bone_part("hips", "PLACEHOLDER_tail", _capsule(0.3, 1.35), Vector3(0, 0.3, -0.62), Vector3(-58, 0, 0))
	_bone_part("hips", "PLACEHOLDER_tail_tip", _sphere(0.27), Vector3(0, 0.62, -1.13))
	_bone_part("hips", "PLACEHOLDER_shoulder_bag", _box(Vector3(0.28, 0.32, 0.16)), Vector3(0.48, 0.05, 0.05))
	_bone_part("handslot.r", "PLACEHOLDER_weapon", _box(Vector3(0.09, 0.05, 1.2)), Vector3(0, 0, 0.38))
	# colour holder for the fur shade (the rig body itself is recoloured)
	_part("PLACEHOLDER_body", _capsule(0.01, 0.02), Vector3.ZERO)
	parts["PLACEHOLDER_body"].visible = false
	scale = Vector3.ONE * SCALE
	apply_customization()
	if is_inside_tree() and get_tree().root.has_node("EventBus"):
		EventBus.equipment_changed.connect(update_weapon)


func apply_customization() -> void:
	var fur := Customization.color("fur_shade")
	var outfit := Customization.color("outfit")
	for p in ["PLACEHOLDER_body", "PLACEHOLDER_head", "PLACEHOLDER_ear_l", "PLACEHOLDER_ear_r", "PLACEHOLDER_tail", "PLACEHOLDER_hair", "PLACEHOLDER_cheek_l", "PLACEHOLDER_cheek_r"]:
		_color(p, fur)
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
		rig.recolor("zotik_%s_%s" % [fur.to_html(), outfit.to_html()], [
			[func(c: Color): return c.v > 0.8 and c.s > 0.12 and c.s < 0.6 and c.h > 0.02 and c.h < 0.12, fur],
			[func(c: Color): return c.s > 0.4 and c.h > 0.35 and c.h < 0.55, outfit],
		])
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


func _bone_part(bone: String, name: String, mesh: Mesh, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	mi.material_override = StandardMaterial3D.new()
	rig.attach(bone, mi)
	parts[name] = mi


func _color(name: String, c: Color) -> void:
	(parts[name].material_override as StandardMaterial3D).albedo_color = c


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
