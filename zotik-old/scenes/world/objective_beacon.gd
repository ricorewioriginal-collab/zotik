class_name ObjectiveBeacon
extends Node3D
## Glowing marker over the current objective (or the exit leading to it).
## PLACEHOLDER visual: translucent light pillar + bobbing arrow.

var pillar: MeshInstance3D
var arrow: MeshInstance3D
var _t := 0.0


func _ready() -> void:
	pillar = MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 0.25
	m.bottom_radius = 0.25
	m.height = 30.0
	pillar.mesh = m
	pillar.position.y = 15.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.3, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pillar.material_override = mat
	add_child(pillar)
	arrow = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.45
	cone.bottom_radius = 0.0
	cone.height = 0.8
	arrow.mesh = cone
	var amat := StandardMaterial3D.new()
	amat.albedo_color = Color(1.0, 0.85, 0.3)
	amat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow.material_override = amat
	add_child(arrow)
	hide()


func _process(delta: float) -> void:
	_t += delta
	arrow.position.y = 3.2 + sin(_t * 3.0) * 0.25
	arrow.rotation.y = _t * 2.0
