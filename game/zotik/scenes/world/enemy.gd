class_name Enemy
extends CharacterBody3D
## Data-driven enemy (data/enemies.json). States: IDLE, CHASE, WINDUP
## (telegraphed attack, can be dodged/blocked), RECOVER, DEAD.
## PLACEHOLDER visual; logic never depends on it.

signal hp_changed(hp: int, max_hp: int)
signal defeated(enemy: Enemy)
signal break_started(enemy: Enemy)
signal break_ended(enemy: Enemy)

enum State { IDLE, CHASE, WINDUP, RECOVER, BROKEN, DEAD }

const WINDUP_TIME := 0.5
const GRAVITY := 18.0
const COLORS := {"ENEMY_TRAINING_DUMMY_001": "#b08a5a", "ENEMY_RIFTLING_001": "#7a4ad8", "ENEMY_MOONWOLF_001": "#9ab0d8", "BOSS_ORUN_001": "#4a2a7a", "ENEMY_PILZLING_001": "#c87a9a", "ENEMY_DORNENWOLF_001": "#5a7a3a", "ENEMY_WURZELKRIECHER_001": "#5a4a2a", "BOSS_WURZELKOENIGIN_001": "#4a6a2a", "ENEMY_KANALSCHLEIM_001": "#6a9a5a", "ENEMY_SCHLEUSENKRABBE_001": "#a85a3a", "ENEMY_ROSTGOLEM_001": "#8a5a3a", "BOSS_KANALWAECHTER_001": "#2a5a7a"}
const SIZES := {"ENEMY_TRAINING_DUMMY_001": 0.75, "ENEMY_RIFTLING_001": 0.45, "ENEMY_MOONWOLF_001": 0.9, "BOSS_ORUN_001": 1.9, "ENEMY_PILZLING_001": 0.7, "ENEMY_DORNENWOLF_001": 1.1, "ENEMY_WURZELKRIECHER_001": 1.6, "BOSS_WURZELKOENIGIN_001": 2.4, "ENEMY_KANALSCHLEIM_001": 0.6, "ENEMY_SCHLEUSENKRABBE_001": 0.8, "ENEMY_ROSTGOLEM_001": 1.7, "BOSS_KANALWAECHTER_001": 2.3}

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
var break_max := 0.0   # 0 = cannot be broken
var break_value := 0.0
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
	break_max = float(data.get("break", 0))
	break_value = break_max
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
	label.font_size = 48
	label.outline_size = 12
	label.fixed_size = true
	label.pixel_size = 0.0009
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
	if Dialogue.is_active():
		_move_to(Vector3.ZERO, delta)
		if state == State.WINDUP:
			state = State.CHASE
			_set_tint(Color.WHITE)
		move_and_slide()
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
		State.BROKEN:
			_move_to(Vector3.ZERO, delta)
			timer -= delta
			if timer <= 0.0:
				_end_break()
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


func is_broken() -> bool:
	return state == State.BROKEN


func break_ratio() -> float:
	return break_value / break_max if break_max > 0.0 else 1.0


## Returns damage dealt. break_amount drains the Break gauge; interrupt
## cancels a telegraphed attack (strong attacks).
func take_hit(attack_value: int, break_amount: float = 0.0, interrupt: bool = false) -> int:
	if state == State.DEAD:
		return 0
	var dmg := Stats.damage(attack_value, int(data.defense))
	if state == State.BROKEN:
		dmg = int(round(dmg * float(Content.combat().get("broken_damage_mult", 1.5))))
	elif break_max > 0.0:
		if interrupt and state == State.WINDUP:
			break_amount += float(Content.combat().get("break_interrupt_bonus", 0))
			state = State.RECOVER
			timer = 0.6
			_set_tint(Color.WHITE)
			EventBus.notify.emit("Unterbrochen!")
		break_value = maxf(0.0, break_value - break_amount)
		if break_value <= 0.0:
			_start_break()
	hp = maxi(0, hp - dmg)
	hp_changed.emit(hp, max_hp)
	_update_label()
	_hit_feedback(dmg)
	if hp == 0:
		_die()
	elif state == State.IDLE and float(data.move_speed) > 0.0 and not is_broken():
		state = State.CHASE
	return dmg


func _start_break() -> void:
	state = State.BROKEN
	timer = float(data.get("break_duration", 2.0))
	velocity = Vector3.ZERO
	_set_tint(Color(1.6, 1.4, 0.4))
	EventBus.notify.emit("BREAK! %s ist verwundbar." % data.get("name", ""))
	break_started.emit(self)
	_update_label()


func _end_break() -> void:
	break_value = break_max
	state = State.CHASE
	_set_tint(Color.WHITE)
	break_ended.emit(self)
	_update_label()


## Hit flash, knockback and a floating damage number.
func _hit_feedback(dmg: int) -> void:
	if not is_inside_tree():
		return
	_set_tint(Color(3, 3, 3))
	get_tree().create_timer(0.08).timeout.connect(func(): if is_instance_valid(self) and state != State.WINDUP and state != State.BROKEN: _set_tint(Color.WHITE))
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p and float(data.move_speed) > 0.0 and not self is Boss:
		var away := global_position - p.global_position
		away.y = 0.0
		velocity += away.normalized() * 4.0
	var num := Label3D.new()
	num.text = str(dmg)
	num.font_size = 96
	num.outline_size = 18
	num.modulate = Color(1, 0.9, 0.3)
	num.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	num.no_depth_test = true
	get_parent().add_child(num)
	num.global_position = global_position + Vector3(0, label.position.y + 0.3, 0)
	var tw := num.create_tween()
	tw.set_parallel()
	tw.tween_property(num, "global_position:y", num.global_position.y + 1.2, 0.7)
	tw.tween_property(num, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(num.queue_free)


func _die() -> void:
	var was_broken := is_broken()
	state = State.DEAD
	if was_broken:
		break_ended.emit(self)
	velocity = Vector3.ZERO
	for d in data.get("drops", []):
		Inventory.add(d.id, int(d.count))
	if int(data.get("currency", 0)) > 0:
		Inventory.add_currency(int(data.currency))
	if persistent:
		GameState.defeated[spawn_id] = true
	Effects.run(data.get("on_defeat", []))
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
	break_value = break_max
	state = State.IDLE
	position = home
	velocity = Vector3.ZERO
	_set_tint(Color.WHITE)
	_update_label()


func base_color() -> Color:
	return Color.html(COLORS.get(enemy_id, "#aa3333"))


func _set_tint(c: Color) -> void:
	(body_mesh.material_override as StandardMaterial3D).albedo_color = base_color() * c


func _update_label() -> void:
	var txt := "%s  %d/%d" % [data.get("name", enemy_id), hp, max_hp]
	if is_broken():
		txt += "  [BREAK]"
	elif break_max > 0.0:
		txt += "  [Bruch %d%%]" % int(round((1.0 - break_ratio()) * 100.0))
	label.text = txt
