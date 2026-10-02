class_name ZotikVisual
extends Node3D
## PLACEHOLDER visual for CHAR_ZOTIK_MASTER_001 (orange anthropomorphic
## creature: upright body, large pointed ears, green eyes, light muzzle/chest,
## large bushy tail, scarf, adventurer outfit). Built from primitives; replace
## with the production model without touching gameplay code.

var parts := {}

## Interim scale (C-23): Zotik ≈ 1.2 m next to ≈ 1.65–1.8 m humans.
const SCALE := 0.68


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
	_part("PLACEHOLDER_weapon", _box(Vector3(0.08, 1.0, 0.03)), Vector3(0.42, 0.9, -0.1), Vector3(-20, 0, 0))
	_part("PLACEHOLDER_shoulder_bag", _box(Vector3(0.22, 0.26, 0.12)), Vector3(-0.36, 0.72, 0.05))
	scale = Vector3.ONE * SCALE
	apply_customization()
	if is_inside_tree() and get_tree().root.has_node("EventBus"):
		EventBus.equipment_changed.connect(update_weapon)


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
	_color("PLACEHOLDER_shoulder_bag", Color(0.45, 0.28, 0.15))
	update_weapon()


## Shows the equipped weapon; the Weltenklinge glows (reacts to Zotik).
func update_weapon() -> void:
	var id: String = GameState.equipment.get("weapon", "")
	var w: MeshInstance3D = parts["PLACEHOLDER_weapon"]
	w.visible = id != ""
	var mat := w.material_override as StandardMaterial3D
	mat.albedo_color = Color(0.75, 0.85, 1.0) if id == "WEAPON_WORLD_BLADE_001" else Color(0.7, 0.7, 0.72)
	mat.emission_enabled = id == "WEAPON_WORLD_BLADE_001"
	mat.emission = Color(0.5, 0.4, 1.0)


## Short weapon swing animation (placeholder for the attack animation).
func swing() -> void:
	var w: MeshInstance3D = parts["PLACEHOLDER_weapon"]
	if not w.visible or not is_inside_tree():
		return
	var tw := create_tween()
	w.rotation_degrees = Vector3(-20, 0, 0)
	tw.tween_property(w, "rotation_degrees", Vector3(-110, -60, 0), 0.08)
	tw.tween_property(w, "rotation_degrees", Vector3(-20, 0, 0), 0.15)


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
