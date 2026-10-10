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
const RETARGET_SEC := 0.5
const COLORS := {"ENEMY_TRAINING_DUMMY_001": "#b08a5a", "ENEMY_RIFTLING_001": "#7a4ad8", "ENEMY_MOONWOLF_001": "#9ab0d8", "BOSS_ORUN_001": "#4a2a7a", "ENEMY_PILZLING_001": "#c87a9a", "ENEMY_DORNENWOLF_001": "#5a7a3a", "ENEMY_WURZELKRIECHER_001": "#5a4a2a", "BOSS_WURZELKOENIGIN_001": "#4a6a2a", "ENEMY_KANALSCHLEIM_001": "#6a9a5a", "ENEMY_SCHLEUSENKRABBE_001": "#a85a3a", "ENEMY_ROSTGOLEM_001": "#8a5a3a", "BOSS_KANALWAECHTER_001": "#2a5a7a", "ENEMY_SANDSKORPION_001": "#b08a4a", "ENEMY_SANDGEIST_001": "#d8b070", "ENEMY_SANDWAECHTER_001": "#a8803a", "BOSS_KHAROS_001": "#8a6428", "ENEMY_RIFFKRABBE_001": "#c8604a", "ENEMY_LEUCHTQUALLE_001": "#7ad8f0", "ENEMY_ARCHIVWAECHTER_001": "#3a9a98", "BOSS_NERYX_001": "#2a8aa0", "ENEMY_FROSTWOLF_001": "#a8c8e8", "ENEMY_EISGEIST_001": "#c8f0ff", "ENEMY_EISWAECHTER_001": "#8ac0e0", "BOSS_AVARN_001": "#6ab0e8", "ENEMY_ASCHEKAEFER_001": "#c8501a", "ENEMY_FUNKENGEIST_001": "#ffb040", "ENEMY_SCHMIEDEGOLEM_001": "#8a4a2a", "BOSS_MAGMARION_001": "#ff6a20", "ENEMY_MONDFLEDERMAUS_001": "#ffffff", "ENEMY_GRUENSCHLEIM_001": "#ffffff", "ENEMY_WALDSPINNE_001": "#ffffff", "ENEMY_SUMPFFROSCH_001": "#ffffff", "ENEMY_KANALRATTE_001": "#ffffff", "ENEMY_DUENENSCHLANGE_001": "#ffffff", "ENEMY_WUESTENSKELETT_001": "#ffffff", "ENEMY_RIFFFROSCH_001": "#ffffff", "ENEMY_ERTRUNKENER_001": "#ffffff", "ENEMY_EISFLEDERMAUS_001": "#ffffff", "ENEMY_FROSTSPINNE_001": "#ffffff", "ENEMY_GLUEHWESPE_001": "#ffffff", "ENEMY_GLUTDRACHE_001": "#ffffff", "ENEMY_SCHATTENFALTER_001": "#ffffff", "ENEMY_VERGESSENER_001": "#ffffff", "ENEMY_NULLWAECHTER_001": "#5a3a9a", "BOSS_ERINNERUNGSHUETER_001": "#3a2a6a", "ENEMY_WOLKENSCHWINGE_001": "#ffffff", "ENEMY_STERNENWAECHTER_001": "#ffffff", "ENEMY_TEMPELWAECHTER_001": "#c8a860", "BOSS_SOLYRA_001": "#e8c8ff", "ENEMY_SPIEGELSPINNE_001": "#ffffff", "ENEMY_ECHOKRIEGER_001": "#ffffff", "ENEMY_WELTENWAECHTER_001": "#5a8ac8", "BOSS_ELYON_001": "#3a5a9a", "BOSS_END_WAECHTER_001": "#6a4aa8", "BOSS_END_WURZEL_001": "#4a6a2a", "BOSS_END_KOLOSS_001": "#c8a030", "BOSS_END_SANDKOENIG_001": "#b08a40", "BOSS_END_ABYSS_001": "#1a6a88", "BOSS_END_FROSTHERZ_001": "#6a98c8", "BOSS_END_FEUERKERN_001": "#a83a1a", "BOSS_END_D1_001": "#5a7a3a", "BOSS_END_D2_001": "#6a6a7a", "BOSS_END_D3_001": "#3a8ab0", "BOSS_END_D4_001": "#a8501a", "BOSS_END_D5_001": "#4a2a8a", "BOSS_END_D6_001": "#4a7ac8", "BOSS_END_D7_001": "#c8b878", "ENEMY_NG_SCHATTENWOLF_001": "#6a3aa8", "ENEMY_NG_SPINNE_001": "#ffffff", "ENEMY_NG_DRACHE_001": "#ffffff", "ENEMY_NG_WAECHTER_001": "#ffffff"}
const SIZES := {"ENEMY_TRAINING_DUMMY_001": 0.75, "ENEMY_RIFTLING_001": 0.45, "ENEMY_MOONWOLF_001": 0.9, "BOSS_ORUN_001": 1.9, "ENEMY_PILZLING_001": 0.7, "ENEMY_DORNENWOLF_001": 1.1, "ENEMY_WURZELKRIECHER_001": 1.6, "BOSS_WURZELKOENIGIN_001": 2.4, "ENEMY_KANALSCHLEIM_001": 0.6, "ENEMY_SCHLEUSENKRABBE_001": 0.8, "ENEMY_ROSTGOLEM_001": 1.7, "BOSS_KANALWAECHTER_001": 2.3, "ENEMY_SANDSKORPION_001": 0.85, "ENEMY_SANDGEIST_001": 0.7, "ENEMY_SANDWAECHTER_001": 1.8, "BOSS_KHAROS_001": 2.9, "ENEMY_RIFFKRABBE_001": 0.9, "ENEMY_LEUCHTQUALLE_001": 0.75, "ENEMY_ARCHIVWAECHTER_001": 1.8, "BOSS_NERYX_001": 2.8, "ENEMY_FROSTWOLF_001": 1.05, "ENEMY_EISGEIST_001": 0.8, "ENEMY_EISWAECHTER_001": 1.9, "BOSS_AVARN_001": 3.0, "ENEMY_ASCHEKAEFER_001": 0.95, "ENEMY_FUNKENGEIST_001": 0.8, "ENEMY_SCHMIEDEGOLEM_001": 1.9, "BOSS_MAGMARION_001": 3.1, "ENEMY_MONDFLEDERMAUS_001": 0.7, "ENEMY_GRUENSCHLEIM_001": 0.65, "ENEMY_WALDSPINNE_001": 0.7, "ENEMY_SUMPFFROSCH_001": 0.6, "ENEMY_KANALRATTE_001": 0.6, "ENEMY_DUENENSCHLANGE_001": 0.7, "ENEMY_WUESTENSKELETT_001": 1.0, "ENEMY_RIFFFROSCH_001": 0.7, "ENEMY_ERTRUNKENER_001": 1.05, "ENEMY_EISFLEDERMAUS_001": 0.8, "ENEMY_FROSTSPINNE_001": 0.85, "ENEMY_GLUEHWESPE_001": 0.7, "ENEMY_GLUTDRACHE_001": 1.1, "ENEMY_SCHATTENFALTER_001": 0.8, "ENEMY_VERGESSENER_001": 1.0, "ENEMY_NULLWAECHTER_001": 1.9, "BOSS_ERINNERUNGSHUETER_001": 3.0, "ENEMY_WOLKENSCHWINGE_001": 0.85, "ENEMY_STERNENWAECHTER_001": 1.0, "ENEMY_TEMPELWAECHTER_001": 1.9, "BOSS_SOLYRA_001": 3.0, "ENEMY_SPIEGELSPINNE_001": 0.85, "ENEMY_ECHOKRIEGER_001": 1.0, "ENEMY_WELTENWAECHTER_001": 1.9, "BOSS_ELYON_001": 3.1, "BOSS_END_WAECHTER_001": 3.3, "BOSS_END_WURZEL_001": 3.3, "BOSS_END_KOLOSS_001": 3.3, "BOSS_END_SANDKOENIG_001": 3.3, "BOSS_END_ABYSS_001": 3.3, "BOSS_END_FROSTHERZ_001": 3.3, "BOSS_END_FEUERKERN_001": 3.3, "BOSS_END_D1_001": 2.6, "BOSS_END_D2_001": 2.6, "BOSS_END_D3_001": 2.6, "BOSS_END_D4_001": 2.6, "BOSS_END_D5_001": 2.6, "BOSS_END_D6_001": 2.6, "BOSS_END_D7_001": 2.6, "ENEMY_NG_SCHATTENWOLF_001": 1.2, "ENEMY_NG_SPINNE_001": 1.0, "ENEMY_NG_DRACHE_001": 1.5, "ENEMY_NG_WAECHTER_001": 1.15}

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
var target: Node3D          # Player or Companion (duck-typed: dead, take_damage)
var _retarget := 0.0
var home := Vector3.ZERO
var break_max := 0.0   # 0 = cannot be broken
var break_value := 0.0
var roam := 0.0             # > 0: wanders within this radius of home while idle (random encounters)
var _wander_t := 0.0
var _wander_v := Vector3.ZERO
var body_mesh: CreatureVisual
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
	data = _ng_scaled(Content.enemy(enemy_id))
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
	body_mesh = CreatureVisual.create(enemy_id, Color.html(COLORS.get(enemy_id, "#aa3333")))
	body_mesh.scale = Vector3.ONE * s
	add_child(body_mesh)
	label = Label3D.new()
	NameTag.style(label, NameTag.FOE, 16.0)
	label.position.y = 1.9 * s
	add_child(label)
	_update_label()


func _ready() -> void:
	home = position


## New Game+ makes every enemy tougher (+50% hp, +35% attack, +25% defence and +50% Lun per
## level) and gives bosses an extra "Raserei" phase at 12% hp.
static func _ng_scaled(base: Dictionary) -> Dictionary:
	var n: int = GameState.ng_plus
	if n <= 0:
		return base
	var d := base.duplicate(true)
	d.hp = int(round(float(d.hp) * (1.0 + 0.5 * n)))
	d.attack = int(round(float(d.attack) * (1.0 + 0.35 * n)))
	d.defense = int(round(float(d.defense) * (1.0 + 0.25 * n)))
	d.currency = int(round(float(d.get("currency", 0)) * (1.0 + 0.5 * n)))
	var phases: Array = d.get("phases", [])
	if not phases.is_empty() and float(phases[-1].from_hp_ratio) > 0.12:
		var last: Dictionary = phases[-1].duplicate(true)
		last.from_hp_ratio = 0.12
		last.name = "Raserei (NG+)"
		last.attack_mult = float(last.get("attack_mult", 1.0)) * 1.2
		last.cooldown_mult = float(last.get("cooldown_mult", 1.0)) * 0.85
		last.color = "#ff4040"
		if last.has("hazard"):
			last.hazard.interval = float(last.hazard.interval) * 0.8
			last.hazard.damage = int(round(float(last.hazard.damage) * 1.1))
		last.erase("summon")
		phases.append(last)
	return d


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
	_retarget -= delta
	if target == null or not is_instance_valid(target) or target.dead or _retarget <= 0.0:
		_retarget = RETARGET_SEC
		target = _choose_target()
	var dist := INF
	if target:
		dist = global_position.distance_to(target.global_position)
	var speed := float(data.move_speed)
	match state:
		State.IDLE:
			if target and dist < float(data.aggro_range) and speed > 0.0 and not target.dead:
				state = State.CHASE
			if roam > 0.0 and speed > 0.0 and state == State.IDLE:
				_wander(speed, delta)
			else:
				_move_to(Vector3.ZERO, delta)
		State.CHASE:
			if target.dead or dist > float(data.aggro_range) * 1.5:
				state = State.IDLE
			elif dist <= float(data.attack_range) and cooldown <= 0.0:
				state = State.WINDUP
				timer = WINDUP_TIME
				_set_tint(Color(1, 0.3, 0.3))
				Sfx.play("windup")
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
	body_mesh.animate(state, Vector2(velocity.x, velocity.z).length(), delta)


## Nearest of Zotik and the companions still standing; Zotik if all are down.
func _choose_target() -> Node3D:
	var best: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if best == null:
		return null
	var best_d := global_position.distance_to(best.global_position) if not best.dead else INF
	for n in get_tree().get_nodes_in_group("party"):
		var c := n as Companion
		if c and not c.dead:
			var d := global_position.distance_to(c.global_position)
			if d < best_d - 0.5:
				best_d = d
				best = c
	return best


## Roaming enemies stroll between pauses and drift back when they get too far from home.
func _wander(speed: float, delta: float) -> void:
	_wander_t -= delta
	if _wander_t <= 0.0:
		_wander_t = randf_range(1.5, 4.0)
		var to_home := home - position
		to_home.y = 0.0
		if randf() < 0.35 and to_home.length() < roam:
			_wander_v = Vector3.ZERO
		else:
			var a := randf() * TAU
			var dir := Vector3(cos(a), 0, sin(a))
			if to_home.length() > roam:
				dir = to_home.normalized()
			_wander_v = dir * speed * 0.35
	_move_to(_wander_v, delta)


func _move_to(v: Vector3, delta: float) -> void:
	velocity.x = move_toward(velocity.x, v.x, 20.0 * delta)
	velocity.z = move_toward(velocity.z, v.z, 20.0 * delta)
	if Vector2(v.x, v.z).length() > 0.1:
		body_mesh.rotation.y = atan2(-v.x, -v.z)


func _strike(dist: float) -> void:
	_set_tint(Color.WHITE)
	body_mesh.lunge()
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
	Sfx.play("break")
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


## The floating damage number (also drawn once by Prewarm so its glyphs exist before the first hit).
static func damage_label(text: String) -> Label3D:
	var num := Label3D.new()
	num.text = text
	num.font_size = 64
	num.outline_size = 12
	num.modulate = Color(1, 0.9, 0.3)
	num.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	num.no_depth_test = true
	num.pixel_size = 0.0075  # keeps the on-screen size of the former 96 px label
	return num


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
	var num := damage_label(str(dmg))
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
	_death_burst()
	hide()
	for c in find_children("*", "CollisionShape3D", true, false):
		c.set_deferred("disabled", true)
	remove_from_group("enemy")


## Short rift-light burst where the enemy vanished (cosmetic).
func _death_burst() -> void:
	if not is_inside_tree() or get_parent() == null:
		return
	var b := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.6 * SIZES.get(enemy_id, 1.0)
	m.height = m.radius * 2.0
	b.mesh = m
	b.material_override = body_mesh.glow_mat
	get_parent().add_child(b)
	b.global_position = global_position + Vector3(0, 0.7 * SIZES.get(enemy_id, 1.0), 0)
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector3.ONE * 1.8, 0.3)
	tw.parallel().tween_property(b, "transparency", 1.0, 0.3)
	tw.tween_callback(b.queue_free)


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
	body_mesh.set_tint(base_color() * c, c)


func _update_label() -> void:
	var txt := "%s\n%d/%d" % [data.get("name", enemy_id), hp, max_hp]
	if is_broken():
		txt += "  [BREAK]"
	elif break_max > 0.0:
		txt += "  [Bruch %d%%]" % int(round((1.0 - break_ratio()) * 100.0))
	label.text = txt
