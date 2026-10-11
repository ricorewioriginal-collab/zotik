class_name Companion
extends CharacterBody3D
## AI party member (data/party.json). Follows Zotik, attacks enemies near
## him, and the healer heals the weakest member. Companions have their own
## HP (saved in GameState.party_hp); enemies attack them too. At 0 HP a
## companion is knocked out and gets up with 30 % HP once the fighting
## around stops; every full heal (savepoint, respawn) restores everyone.

signal attacked(target: Enemy)
signal damaged(amount: int)
signal healed_player(amount: int)

const FOLLOW_MIN := 2.5
const FOLLOW_MAX := 4.0
## Formation slots behind Zotik (x = right, z = back), by party index. None
## sits on the line between camera and Zotik, so he is never hidden.
const SLOTS := [Vector3(-2.4, 0, 0.3), Vector3(2.4, 0, 0.3), Vector3(3.6, 0, 1.6)]
## interim model per member (C01, CC0 Quaternius humans; see CharacterRig.create_human)
const LOOKS := {
	"PARTY_LYRA_001": [{"outfit": "Female_Peasant", "body": "Female", "hair": "Hair_Long", "hair_color": Color(0.35, 0.6, 1.0), "tint": Color(0.78, 0.82, 1.0), "right": "staff"}, 1.72],
	"PARTY_NIA_001": [{"outfit": "Female_Ranger", "body": "Female", "hair": "Hair_Buns", "hair_color": Color(0.5, 0.34, 0.22), "hide": ["Female_Ranger_Head_Hood"], "right": "crossbow"}, 1.68],
	"PARTY_ROVAN_001": [{"outfit": "Male_Ranger", "body": "Male", "hair": "Hair_SimpleParted", "beard": true, "hair_color": Color(0.22, 0.16, 0.11), "hide": ["Male_Ranger_Head_Hood"], "right": "axe", "left": "shield"}, 1.86],
}
const TELEPORT_DIST := 25.0
const KO_RECOVER_SEC := 5.0       # quiet seconds after a fight before a K.O. ends
const KO_RECOVER_FRACTION := 0.3
const ENGAGE_RADIUS := 10.0
const GRAVITY := 18.0

var member_id := ""
var data := {}
var player: Player
var attack_cd := 0.0
var dead := false        # knocked out (duck-typed like Player.dead for enemies)
var _ko_quiet := 0.0     # seconds without nearby fighting while knocked out
var heal_cd := 0.0
var body: Node3D
var rig: CharacterRig


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
	var look: Array = LOOKS.get(id, [{"outfit": "Male_Peasant"}, 1.75])
	c.rig = CharacterRig.create_human(look[0], float(look[1]))
	c.body = c.rig
	c.add_child(c.rig)
	if int(GameState.party_hp.get(id, 1)) <= 0:
		c.dead = true  # still knocked out (loaded save or area change)
		c.rig.play("death")
	var label := Label3D.new()
	label.text = str(c.data.get("name", id))
	NameTag.style(label, NameTag.ALLY)
	label.position.y = 2.1
	c.add_child(label)
	return c


## Hit points live in GameState.party_hp (missing entry = full), so they are
## saved and survive area changes.
func max_hp() -> int:
	return int(data.get("hp", 100))


func hp() -> int:
	return int(GameState.party_hp.get(member_id, max_hp()))


func take_damage(raw_attack: int) -> int:
	if dead:
		return 0
	var dmg := Stats.damage(raw_attack, int(data.get("defense", 0)))
	GameState.party_hp[member_id] = maxi(0, hp() - dmg)
	damaged.emit(dmg)
	if hp() == 0:
		_knock_out()
	elif not rig.in_action():
		rig.action("hit", 1.5)
	return dmg


func heal(amount: int) -> int:
	if dead:
		return 0
	var before := hp()
	GameState.party_hp[member_id] = mini(max_hp(), before + amount)
	return hp() - before


func _knock_out() -> void:
	dead = true
	_ko_quiet = 0.0
	velocity = Vector3.ZERO
	rig.play("death")
	EventBus.notify.emit("%s ist kampfunfähig!" % data.name)


## fraction of max HP; used by full heals (savepoint, respawn) and after fights
func revive(fraction: float) -> void:
	var was_down := dead
	dead = false
	GameState.party_hp[member_id] = maxi(hp() if not was_down else 0, int(ceil(max_hp() * fraction)))
	if was_down:
		rig.play("idle")
		EventBus.notify.emit("%s steht wieder auf." % data.name)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if dead:
		_move(Vector3.ZERO, delta, false)
		_ko_quiet = 0.0 if _fight_nearby() else _ko_quiet + delta
		if _ko_quiet >= KO_RECOVER_SEC and not player.dead:
			revive(KO_RECOVER_FRACTION)
		return
	attack_cd = maxf(0.0, attack_cd - delta)
	heal_cd = maxf(0.0, heal_cd - delta)
	var to_player := player.global_position - global_position
	if to_player.length() > TELEPORT_DIST:
		snap_to_player()
		return
	if Dialogue.is_active() or player.dead:
		_move(Vector3.ZERO, delta)
		return
	if int(data.get("heal_amount", 0)) > 0 and heal_cd <= 0.0:
		_heal_weakest()
	var target := _pick_target()
	var goal := Vector3.ZERO
	if target:
		var to_t := target.global_position - global_position
		to_t.y = 0.0
		if to_t.length() > float(data.attack_range):
			goal = to_t.normalized() * float(data.move_speed)
		elif attack_cd <= 0.0:
			attack_cd = float(data.attack_cooldown)
			target.take_hit(int(data.attack), float(data.get("break", Content.combat().get("break_party", 6))))
			_bolt(target.global_position)
			attacked.emit(target)
			rig.action("cast" if float(data.attack_range) > 4.0 else "attack", 1.5)
		_face(to_t)
	else:
		var to_slot := slot_position() - global_position
		to_slot.y = 0.0
		if to_slot.length() > 0.6:
			goal = to_slot.normalized() * minf(float(data.move_speed), to_slot.length() * 3.0)
		var flat := Vector3(to_player.x, 0, to_player.z)
		if flat.length() > 0.1:
			_face(flat)
	_move(goal, delta)


## Formation point for this member: behind Zotik relative to the camera, so
## companions never stand between the camera and Zotik.
func slot_position() -> Vector3:
	var idx := maxi(0, GameState.party.find(member_id)) % SLOTS.size()
	var yaw: float = player.camera_pivot.rotation.y if player.camera_pivot else 0.0
	return player.global_position + (SLOTS[idx] as Vector3).rotated(Vector3.UP, yaw)


func snap_to_player() -> void:
	if not is_instance_valid(player):
		return
	global_position = slot_position() + Vector3(0, 0.2, 0)
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


func _move(v: Vector3, delta: float, animate: bool = true) -> void:
	velocity.x = move_toward(velocity.x, v.x, 25.0 * delta)
	velocity.z = move_toward(velocity.z, v.z, 25.0 * delta)
	move_and_slide()
	if animate:
		rig.locomotion(Vector2(velocity.x, velocity.z).length(), float(data.move_speed))


## Healer: heals whoever (Zotik or a companion) is lowest below the threshold.
func _heal_weakest() -> void:
	var best: Node = null
	var best_ratio := float(data.heal_threshold)
	var pr := float(GameState.player.hp) / float(maxi(1, Stats.max_hp()))
	if not player.dead and pr < best_ratio:
		best = player
		best_ratio = pr
	for n in get_tree().get_nodes_in_group("party"):
		var c := n as Companion
		var r := float(c.hp()) / float(c.max_hp())
		if not c.dead and r < best_ratio:
			best = c
			best_ratio = r
	if best == null:
		return
	heal_cd = float(data.heal_cooldown)
	var done: int = best.heal(int(data.heal_amount))
	if best == player:
		healed_player.emit(done)
		EventBus.notify.emit("%s heilt dich (+%d)." % [data.name, done])
	else:
		EventBus.notify.emit("%s heilt %s (+%d)." % [data.name, (best as Companion).data.name, done])
	rig.action("cast", 1.5)


func _fight_nearby() -> bool:
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Enemy
		if e and not e.is_dead() and e.state != Enemy.State.IDLE and e.global_position.distance_to(global_position) < 20.0:
			return true
	return false


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
