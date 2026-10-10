class_name Prewarm
extends Node3D
## Draws the things a fight needs once, in front of the camera, while the first area fades in:
## the hit/wind-up/break overlay on a skinned and an unskinned mesh, the glow material of the death
## burst and the digits of the damage numbers. Without it the renderers without shader caching
## (web, Android) compile these on the first hit and the game stutters at the start of a fight.
## Nothing here is logic; headless runs skip it.

const FRAMES := 3


static func run(game: Node3D) -> void:
	if DisplayServer.get_name() == "headless" or not is_instance_valid(game):
		return
	var cam := game.get_viewport().get_camera_3d()
	if cam == null:
		return
	var p := Prewarm.new()
	p.name = "Prewarm"
	cam.add_child(p)
	p.position = Vector3(0, 0, -1.5)
	p._start(game)


func _start(game: Node3D) -> void:
	var overlays: Array[Material] = [
		CreatureVisual._overlay(Color(1, 0.15, 0.1, 0.45)),
		CreatureVisual._overlay(Color(1, 1, 1, 0.7)),
		CreatureVisual._overlay(Color(1, 0.85, 0.3, 0.45)),
	]
	var ball := SphereMesh.new()
	ball.radius = 0.04
	ball.height = 0.08
	for o in overlays:
		var mi := MeshInstance3D.new()
		mi.mesh = ball
		mi.material_override = Look.glow(Color(0.7, 0.4, 1.0))
		mi.material_overlay = o
		add_child(mi)
	var num := Enemy.damage_label("0123456789")
	num.scale = Vector3.ONE * 0.05
	add_child(num)
	# the player's own skinned meshes carry the overlay for a moment (same vertex format as the enemy models)
	var player := game.get_tree().get_first_node_in_group("player")
	var skinned: Array[MeshInstance3D] = []
	if player:
		for m in player.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if mi.skin != null or mi.get_skeleton_path() != NodePath(""):
				skinned.append(mi)
	for mi in skinned:
		mi.material_overlay = overlays[1]
	for i in FRAMES:
		await get_tree().process_frame
	for mi in skinned:
		if is_instance_valid(mi):
			mi.material_overlay = null
	queue_free()
