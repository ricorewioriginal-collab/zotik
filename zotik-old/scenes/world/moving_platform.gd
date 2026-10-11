class_name MovingPlatform
extends AnimatableBody3D
## "Sich bewegende Wege": a platform that travels back and forth between two
## points (ping-pong, smooth). Carries the player. PLACEHOLDER visual.

var from := Vector3.ZERO
var to := Vector3.ZERO
var period := 6.0
var t := 0.0


static func create(entry: Dictionary) -> MovingPlatform:
	var p := MovingPlatform.new()
	p.name = entry.id
	p.from = WorldArea._v(entry.pos)
	p.to = WorldArea._v(entry.to)
	p.period = float(entry.get("period", 6.0))
	p.t = float(entry.get("phase", 0.0)) * p.period
	p.sync_to_physics = true
	var size := WorldArea._v(entry.get("size", [4, 1, 4]))
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	p.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.name = "PLACEHOLDER_moving_path"
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.7, 0.3)
	mi.material_override = mat
	p.add_child(mi)
	p.add_to_group("ground")
	return p


func _ready() -> void:
	position = position_at(t)


func position_at(time: float) -> Vector3:
	var k := 0.5 - 0.5 * cos(TAU * time / period)  # 0 -> 1 -> 0
	return from.lerp(to, k)


func _physics_process(delta: float) -> void:
	t = fmod(t + delta, period)
	position = position_at(t)
