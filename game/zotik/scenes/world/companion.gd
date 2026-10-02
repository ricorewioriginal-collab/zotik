class_name Companion
extends CharacterBody3D
## AI party member (data/party.json). Follows Zotik, attacks enemies near
## him from range and heals him when his health is low. Enemies target only
## Zotik, so companions never block progress. PLACEHOLDER visual.

signal attacked(target: Enemy)
signal healed_player(amount: int)

const FOLLOW_MIN := 2.5
const FOLLOW_MAX := 4.0
const TELEPORT_DIST := 25.0
const ENGAGE_RADIUS := 10.0
const GRAVITY := 18.0

var member_id := ""
var data := {}
var player: Player
var attack_cd := 0.0
var heal_cd := 0.0
var body: MeshInstance3D


static func create(id: String, p: Player) -> Companion:
	var c := Companion.new()
	c.member_id = id
	c.name = id
	c.player = p
	c.data = Content.get_entry("party", id)
	c.add_to_group("party")
	c.collision_layer = 0  # never blocks the player or enemies
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.7
	cs.shape = shape
	cs.position.y = 0.85
	c.add_child(cs)
	c.body = MeshInstance3D.new()
	c.body.name = "PLACEHOLDER_companion"
	var m := CapsuleMesh.new()
	m.radius = 0.3
	m.height = 1.7
	c.body.mesh = m
	c.body.position.y = 0.85
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.html(c.data.get("color", "#cccccc"))
	c.body.material_override = mat
	c.add_child(c.body)
	var label := Label3D.new()
	label.text = str(c.data.get("name", id))
	label.font_size = 64
	label.outline_size = 14
	label.position.y = 2.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	c.add_child(label)
	return c


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	attack_cd = maxf(0.0, attack_cd - delta)
	heal_cd = maxf(0.0, heal_cd - delta)
	var to_player := player.global_position - global_position
	if to_player.length() > TELEPORT_DIST:
		snap_to_player()
		return
	if Dialogue.is_active() or player.dead:
		_move(Vector3.ZERO, delta)
		return
	if heal_cd <= 0.0 and float(GameState.player.hp) / float(maxi(1, Stats.max_hp())) < float(data.heal_threshold):
		heal_cd = float(data.heal_cooldown)
		var done := player.heal(int(data.heal_amount))
		healed_player.emit(done)
		EventBus.notify.emit("%s heilt dich (+%d)." % [data.name, done])
	var target := _pick_target()
	var goal := Vector3.ZERO
	if target:
		var to_t := target.global_position - global_position
		to_t.y = 0.0
		if to_t.length() > float(data.attack_range):
			goal = to_t.normalized() * float(data.move_speed)
		elif attack_cd <= 0.0:
			attack_cd = float(data.attack_cooldown)
			target.take_hit(int(data.attack), float(Content.combat().get("break_party", 6)))
			_bolt(target.global_position)
			attacked.emit(target)
		_face(to_t)
	else:
		var flat := Vector3(to_player.x, 0, to_player.z)
		if flat.length() > FOLLOW_MAX:
			goal = flat.normalized() * float(data.move_speed)
		elif flat.length() < FOLLOW_MIN * 0.5:
			goal = -flat.normalized() * 2.0
		if flat.length() > 0.1:
			_face(flat)
	_move(goal, delta)


func snap_to_player() -> void:
	if not is_instance_valid(player):
		return
	var back := Vector3(0, 0, 1).rotated(Vector3.UP, player.visual.rotation.y) * FOLLOW_MIN
	global_position = player.global_position + back + Vector3(0.8, 0.2, 0)
	velocity = Vector3.ZERO


func _pick_target() -> Enemy:
	var best: Enemy = null
	var best_d := ENGAGE_RADIUS
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Enemy
		if e == null or e.is_dead() or float(e.data.get("move_speed", 0.0)) == 0.0 and e.enemy_id == "ENEMY_TRAINING_DUMMY_001":
			continue
		var d := e.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _move(v: Vector3, delta: float) -> void:
	velocity.x = move_toward(velocity.x, v.x, 25.0 * delta)
	velocity.z = move_toward(velocity.z, v.z, 25.0 * delta)
	move_and_slide()


func _face(dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length() > 0.01:
		body.rotation.y = atan2(-dir.x, -dir.z)


## Short-lived magic bolt visual (placeholder).
func _bolt(to: Vector3) -> void:
	var b := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.15
	m.height = 0.3
	b.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.8, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.6, 1.0)
	b.material_override = mat
	get_parent().add_child(b)
	b.global_position = global_position + Vector3(0, 1.3, 0)
	var tw := b.create_tween()
	tw.tween_property(b, "global_position", to + Vector3(0, 1.0, 0), 0.2)
	tw.tween_callback(b.queue_free)
