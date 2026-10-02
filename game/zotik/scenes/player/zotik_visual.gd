class_name ZotikVisual
extends Node3D
## PLACEHOLDER visual for CHAR_ZOTIK_MASTER_001 (orange anthropomorphic
## creature: upright body, large pointed ears, green eyes, light muzzle/chest,
## large bushy tail, scarf, adventurer outfit). Built from primitives; replace
## with the production model without touching gameplay code.

var parts := {}


func _ready() -> void:
	_part("PLACEHOLDER_body", _capsule(0.32, 1.1), Vector3(0, 0.75, 0))
	_part("PLACEHOLDER_outfit", _cylinder(0.35, 0.33, 0.45), Vector3(0, 0.6, 0))
	_part("PLACEHOLDER_head", _sphere(0.3), Vector3(0, 1.45, 0))
	_part("PLACEHOLDER_muzzle", _sphere(0.14), Vector3(0, 1.38, -0.24))
	_part("PLACEHOLDER_chest", _sphere(0.18), Vector3(0, 1.0, -0.2))
	_part("PLACEHOLDER_ear_l", _cone(0.11, 0.32), Vector3(-0.17, 1.78, 0), Vector3(0, 0, 15))
	_part("PLACEHOLDER_ear_r", _cone(0.11, 0.32), Vector3(0.17, 1.78, 0), Vector3(0, 0, -15))
	_part("PLACEHOLDER_eye_l", _sphere(0.05), Vector3(-0.11, 1.5, -0.26))
	_part("PLACEHOLDER_eye_r", _sphere(0.05), Vector3(0.11, 1.5, -0.26))
	_part("PLACEHOLDER_tail", _capsule(0.16, 0.9), Vector3(0, 0.75, 0.42), Vector3(55, 0, 0))
	_part("PLACEHOLDER_scarf", _torus(0.2, 0.3), Vector3(0, 1.2, 0))
	apply_customization()


func apply_customization() -> void:
	var fur := Customization.color("fur_shade")
	_color("PLACEHOLDER_body", fur)
	_color("PLACEHOLDER_head", fur)
	_color("PLACEHOLDER_ear_l", fur)
	_color("PLACEHOLDER_ear_r", fur)
	_color("PLACEHOLDER_tail", fur)
	_color("PLACEHOLDER_muzzle", Color(0.98, 0.9, 0.8))
	_color("PLACEHOLDER_chest", Color(0.98, 0.9, 0.8))
	_color("PLACEHOLDER_eye_l", Color(0.2, 0.75, 0.3))
	_color("PLACEHOLDER_eye_r", Color(0.2, 0.75, 0.3))
	_color("PLACEHOLDER_scarf", Customization.color("scarf"))
	_color("PLACEHOLDER_outfit", Customization.color("outfit"))


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


func _color(name: String, c: Color) -> void:
	(parts[name].material_override as StandardMaterial3D).albedo_color = c


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
