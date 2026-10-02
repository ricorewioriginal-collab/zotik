class_name ZotikTestModel
extends Node3D
## PLACEHOLDER test model of Zotik generated with Hunyuan3D-2.1 from
## reference/derived/ZOTIK_FRONT_CROP.png (seed 1234), shape only with the
## reference projected as vertex colours (tools/models/hunyuan_postprocess.py).
## NOT final art (CLAUDE.md rule 6). Shown next to the current Zotik for
## comparison: one static copy and one fitted onto the shared human skeleton
## (tools/bake_zotik_test_skin.gd) that plays the human animations.

const GLB := "res://assets/characters/custom/zotik_test.glb"
const SKINNED := "res://assets/characters/custom/zotik_test_skinned.res"
## show the comparison pair next to Zotik whenever an area loads
const SHOW_IN_GAME := true
## same in-game height as ZotikVisual (1.75 m rig × 0.68)
const HEIGHT := 1.19

var rig: CharacterRig
var mesh_instance: MeshInstance3D

static var _material: StandardMaterial3D


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.resource_name = "PLACEHOLDER_zotik_test"
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.85
	return _material


## Unrigged GLB as delivered (facing -Z like the game characters).
static func create_static() -> ZotikTestModel:
	var t := ZotikTestModel.new()
	t.name = "PLACEHOLDER_ZotikTest_Static"
	var src: Node = (load(GLB) as PackedScene).instantiate()
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = (src.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	src.free()
	mi.material_override = material()
	mi.scale = Vector3.ONE * HEIGHT
	mi.rotation.y = PI
	t.add_child(mi)
	t.mesh_instance = mi
	return t


## Skinned to the human rig (bone rests refitted to Zotik's proportions).
static func create_rigged() -> ZotikTestModel:
	var t := ZotikTestModel.new()
	t.name = "PLACEHOLDER_ZotikTest_Rigged"
	var mesh: ArrayMesh = load(SKINNED)
	var units: float = mesh.get_meta("height_units")
	t.rig = CharacterRig.create_human(ZotikVisual.BODY_SPEC, CharacterRig.HUMAN_HEIGHT * HEIGHT / units)
	t.add_child(t.rig)
	for mi in t.rig.meshes():
		mi.visible = false
	var sk := t.rig.skeleton
	var rests: Dictionary = mesh.get_meta("bone_rests")
	for bone_name in rests:
		var b := sk.find_bone(bone_name)
		if b >= 0:
			var r := sk.get_bone_rest(b)
			r.origin = rests[bone_name]
			sk.set_bone_rest(b, r)
			sk.set_bone_pose_position(b, r.origin)
	var mi := MeshInstance3D.new()
	mi.name = "PLACEHOLDER_zotik_test_skinned"
	mi.mesh = mesh
	mi.skin = mesh.get_meta("skin")
	mi.material_override = material()
	sk.add_child(mi)
	mi.skeleton = NodePath("..")
	t.mesh_instance = mi
	return t


## Comparison pair placed to Zotik's right (static, then rigged).
static func showcase() -> Node3D:
	var n := Node3D.new()
	n.name = "PLACEHOLDER_ZotikTestShowcase"
	var s := create_static()
	s.position = Vector3(1.0, 0, 0)
	n.add_child(s)
	var r := create_rigged()
	r.position = Vector3(2.0, 0, 0)
	n.add_child(r)
	return n
