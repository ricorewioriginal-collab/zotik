class_name Enemy
extends CharacterBody3D
## Data-driven enemy (data/enemies.json). States: IDLE, CHASE, WINDUP
## (telegraphed attack, can be dodged/blocked), RECOVER, DEAD.
## PLACEHOLDER visual; logic never depends on it.

signal hp_changed(hp: int, max_hp: int)
signal defeated(enemy: Enemy)

enum State { IDLE, CHASE, WINDUP, RECOVER, DEAD }

const WINDUP_TIME := 0.5
const GRAVITY := 18.0
const COLORS := {"ENEMY_TRAINING_DUMMY_001": "#b08a5a", "ENEMY_RIFTLING_001": "#7a4ad8", "ENEMY_MOONWOLF_001": "#9ab0d8", "BOSS_ORUN_001": "#4a2a7a"}
const SIZES := {"ENEMY_TRAINING_DUMMY_001": 0.9, "ENEMY_RIFTLING_001": 0.7, "ENEMY_MOONWOLF_001": 1.2, "BOSS_ORUN_001": 2.2}

var enemy_id := ""
var spawn_id := ""
var persistent := false
var data := {}
var hp := 1
var max_hp := 1
var state := State.IDLE
var timer := 0.0
var cooldown := 0.0
var attack_mult := 1.0
var cooldown_mult := 1.0
var target: Player
var home := Vector3.ZERO
var body_mesh: MeshInstance3D
var label: Label3D


static func create(entry: Dictionary) -> Enemy:
	if entry.get("persistent", false) and GameState.defeated.has(entry.spawn):
		return null
	var script: GDScript = load("res://scenes/world/boss.gd") if Content.enemy(entry.enemy).has("phases") else load("res://scenes/world/enemy.gd")
	var e: Enemy = script.new()
	e.setup(entry)
	return e


func setup(entry: Dictionary) -> void:
	enemy_id = entry.enemy
	spawn_id = entry.spawn
	persistent = entry.get("persistent", false)
	name = spawn_id
	data = Content.enemy(enemy_id)
	max_hp = int(data.hp)
	hp = max_hp
	add_to_group("enemy")
	var s: float = SIZES.get(enemy_id, 1.0)
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4 * s
	shape.height = 1.6 * s
	cs.shape = shape
	cs.position.y = 0.8 * s
	add_child(cs)
	body_mesh = MeshInstance3D.new()
	body_mesh.name = "PLACEHOLDER_enemy"
	var m := CapsuleMesh.new()
	m.radius = 0.4 * s
	m.height = 1.6 * s
	body_mesh.mesh = m
	body_mesh.position.y = 0.8 * s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.html(COLORS.get(enemy_id, "#aa3333"))
	body_mesh.material_override = mat
	add_child(body_mesh)
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 1.9 * s
	add_child(label)
	_update_label()


func _ready() -> void:
	home = position


func is_dead() -> bool:
	return state == State.DEAD


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if state == State.DEAD:
		return
	cooldown = maxf(0.0, cooldown - delta)
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Player
	var dist := INF
	if target:
		dist = global_position.distance_to(target.global_position)
	var speed := float(data.move_speed)
	match state:
		State.IDLE:
			if target and dist < float(data.aggro_range) and speed > 0.0 and not target.dead:
				state = State.CHASE
			_move_to(Vector3.ZERO, delta)
		State.CHASE:
			if target.dead or dist > float(data.aggro_range) * 1.5:
				state = State.IDLE
			elif dist <= float(data.attack_range) and cooldown <= 0.0:
				state = State.WINDUP
				timer = WINDUP_TIME
				_set_tint(Color(1, 0.3, 0.3))
			else:
				_move_to((target.global_position - global_position).normalized() * speed, delta)
		State.WINDUP:
			_move_to(Vector3.ZERO, delta)
			timer -= delta
			if timer <= 0.0:
				_strike(dist)
		State.RECOVER:
			_move_to(Vector3.ZERO, delta)
			timer -= delta
			if timer <= 0.0:
				state = State.CHASE
	move_and_slide()


func _move_to(v: Vector3, delta: float) -> void:
	velocity.x = move_toward(velocity.x, v.x, 20.0 * delta)
	velocity.z = move_toward(velocity.z, v.z, 20.0 * delta)
	if Vector2(v.x, v.z).length() > 0.1:
		body_mesh.rotation.y = atan2(-v.x, -v.z)


func _strike(dist: float) -> void:
	_set_tint(Color.WHITE)
	if target and dist <= float(data.attack_range) * 1.25:
		target.take_damage(int(round(int(data.attack) * attack_mult)))
	cooldown = float(data.attack_cooldown) * cooldown_mult
	state = State.RECOVER
	timer = 0.3


## Returns damage dealt.
func take_hit(attack_value: int) -> int:
	if state == State.DEAD:
		return 0
	var dmg := Stats.damage(attack_value, int(data.defense))
	hp = maxi(0, hp - dmg)
	hp_changed.emit(hp, max_hp)
	_update_label()
	if hp == 0:
		_die()
	elif state == State.IDLE and float(data.move_speed) > 0.0:
		state = State.CHASE
	return dmg


func _die() -> void:
	state = State.DEAD
	velocity = Vector3.ZERO
	for d in data.get("drops", []):
		Inventory.add(d.id, int(d.count))
	if int(data.get("currency", 0)) > 0:
		Inventory.add_currency(int(data.currency))
	if persistent:
		GameState.defeated[spawn_id] = true
	defeated.emit(self)
	EventBus.enemy_defeated.emit(enemy_id)
	hide()
	for c in find_children("*", "CollisionShape3D", true, false):
		c.set_deferred("disabled", true)
	remove_from_group("enemy")


func reset_encounter() -> void:
	if state == State.DEAD:
		return
	hp = max_hp
	state = State.IDLE
	position = home
	velocity = Vector3.ZERO
	_set_tint(Color.WHITE)
	_update_label()


func _set_tint(c: Color) -> void:
	(body_mesh.material_override as StandardMaterial3D).albedo_color = Color.html(COLORS.get(enemy_id, "#aa3333")) * c


func _update_label() -> void:
	label.text = "%s  %d/%d" % [data.get("name", enemy_id), hp, max_hp]
