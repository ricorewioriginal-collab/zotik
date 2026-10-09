class_name Player
extends CharacterBody3D
## Zotik player controller: camera-relative movement, jump, dodge with
## invulnerability frames, block, health. Stats come from Content/Stats,
## persistent values from GameState. Independent of the visual mesh.

signal damaged(amount: int)
signal healed(amount: int)
signal died
signal interactable_changed(target: Interactable)
signal attacked(hits: int)
signal lock_changed(target: Node3D)

const JUMP_VELOCITY := 6.5
const GRAVITY := 18.0
const ACCEL := 30.0
const CAMERA_SPEED := 2.5
const MOUSE_SENS := 0.004

var control_enabled := true
var is_dodging := false
var is_blocking := false
var invulnerable_time := 0.0
var dodge_time_left := 0.0
var dodge_dir := Vector3.ZERO
var dead := false
var current_interactable: Interactable
var attack_cooldown := 0.0
var lock_target: Enemy

## Touch autopilot (A03): tap-to-walk, tap a person/chest to walk there and use
## it, tap an enemy to approach and fight it. Any manual input cancels it.
enum Goal { NONE, POINT, USE, FIGHT }
var goal := Goal.NONE
var goal_point := Vector3.ZERO
var goal_node: Node3D
var _stuck_time := 0.0
var _stuck_ref := Vector3.ZERO

const ATTACK_CONE_DOT := 0.3
const LOCK_RANGE := 15.0

var stats := {}
var visual: ZotikVisual
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D


func _ready() -> void:
	add_to_group("player")
	stats = Content.player_stats()
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.2
	col.shape = shape
	col.position.y = 0.6
	add_child(col)
	visual = ZotikVisual.new()
	visual.name = "Visual"
	add_child(visual)
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.top_level = true
	add_child(camera_pivot)
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 5.0
	spring_arm.rotation_degrees.x = -20.0
	spring_arm.add_excluded_object(get_rid())
	camera_pivot.add_child(spring_arm)
	camera = Camera3D.new()
	camera.current = true
	spring_arm.add_child(camera)
	ColorGrade.apply(camera)
	camera_pivot.global_position = global_position + Vector3(0, 1.0, 0)
	GameState.player["max_hp"] = Stats.max_hp()
	GameState.player["hp"] = clampi(int(GameState.player.get("hp", Stats.max_hp())), 1, Stats.max_hp())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and control_enabled:
		var inv := -1.0 if Settings.get_value("camera_invert") else 1.0
		var sens := MOUSE_SENS * float(Settings.get_value("camera_sensitivity"))
		camera_pivot.rotation.y -= event.relative.x * sens
		spring_arm.rotation.x = clampf(spring_arm.rotation.x - event.relative.y * sens * inv, deg_to_rad(-60), deg_to_rad(20))


func _physics_process(delta: float) -> void:
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if lock_target and (not is_instance_valid(lock_target) or lock_target.is_dead() or lock_target.global_position.distance_to(global_position) > LOCK_RANGE):
		set_lock(null)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var input := Vector2.ZERO
	if control_enabled and not dead:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		camera_pivot.rotation.y += (Input.get_action_strength("camera_left") - Input.get_action_strength("camera_right")) * CAMERA_SPEED * delta
		is_blocking = Input.is_action_pressed("block") and not is_dodging
		if Input.is_action_just_pressed("jump") and is_on_floor() and not is_dodging:
			velocity.y = JUMP_VELOCITY
	else:
		is_blocking = false
	var dir := move_direction(input)
	if goal != Goal.NONE:
		if not control_enabled or dead or input.length() > 0.2:
			clear_goal()
		else:
			dir = _goal_direction(delta)
	if is_dodging:
		dodge_time_left -= delta
		velocity.x = dodge_dir.x * float(stats.dodge_speed)
		velocity.z = dodge_dir.z * float(stats.dodge_speed)
		if dodge_time_left <= 0.0:
			is_dodging = false
	else:
		if control_enabled and not dead and Input.is_action_just_pressed("dodge"):
			start_dodge(dir)
		var speed := float(stats.move_speed) * (0.4 if is_blocking else 1.0)
		velocity.x = move_toward(velocity.x, dir.x * speed, ACCEL * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, ACCEL * delta)
		if lock_target:
			face(lock_target.global_position - global_position)
		elif dir.length() > 0.01:
			face(dir)
	move_and_slide()
	visual.animate(self)
	camera_pivot.global_position = global_position + Vector3(0, 1.0, 0)
	_update_interactable()
	if control_enabled and not dead and current_interactable and Input.is_action_just_pressed("interact"):
		current_interactable.interact(self)
	if control_enabled and not dead and Input.is_action_just_pressed("attack"):
		attack()
	if control_enabled and not dead and Input.is_action_just_pressed("strong_attack"):
		attack(true)
	if control_enabled and not dead and Input.is_action_just_pressed("lock_on"):
		set_lock(null if lock_target else nearest_enemy(LOCK_RANGE))
	if control_enabled and not dead and Input.is_action_just_pressed("use_item"):
		var id := Inventory.first_consumable()
		if id == "" or not Inventory.use(id, self):
			EventBus.notify.emit("Kein passender Gegenstand.")


func set_goal(kind: Goal, point: Vector3 = Vector3.ZERO, node: Node3D = null) -> void:
	goal = kind
	goal_point = point
	goal_node = node
	_stuck_time = 0.0
	_stuck_ref = global_position
	if kind == Goal.FIGHT and node is Enemy:
		set_lock(node)


func clear_goal() -> void:
	goal = Goal.NONE
	goal_node = null


## Steering for the current goal: a world direction, or zero when there is
## none, when it was reached (and acted on) or when the way is blocked.
func _goal_direction(delta: float) -> Vector3:
	var target := goal_point
	if goal != Goal.POINT:
		if not is_instance_valid(goal_node) or (goal_node is Enemy and (goal_node as Enemy).is_dead()):
			clear_goal()
			return Vector3.ZERO
		target = goal_node.global_position
	var to := target - global_position
	to.y = 0.0
	var reach := 0.35
	if goal == Goal.USE:
		reach = Interactable.INTERACT_RANGE * 0.7
	elif goal == Goal.FIGHT:
		reach = maxf(0.8, float(stats.attack_range) - 0.4)
	if to.length() <= reach:
		if goal == Goal.FIGHT:
			face(to)
			attack()  # gated by the attack cooldown; the goal stays until the foe falls
			return Vector3.ZERO
		var it := goal_node as Interactable
		clear_goal()
		if it != null and it.can_interact():
			it.interact(self)
		return Vector3.ZERO
	_stuck_time += delta
	if _stuck_time >= 1.2:
		if global_position.distance_to(_stuck_ref) < 0.3:
			clear_goal()
			return Vector3.ZERO
		_stuck_time = 0.0
		_stuck_ref = global_position
	if goal == Goal.FIGHT and lock_target != goal_node and global_position.distance_to(target) <= LOCK_RANGE:
		set_lock(goal_node as Enemy)
	return to.normalized()


func _update_interactable() -> void:
	var best: Interactable = null
	var best_d := Interactable.INTERACT_RANGE
	for n in get_tree().get_nodes_in_group("interactable"):
		var it := n as Interactable
		if it == null or not it.can_interact():
			continue
		var d := it.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = it
	if best != current_interactable:
		current_interactable = best
		interactable_changed.emit(best)


## Converts stick/WASD input into a world direction relative to the camera yaw.
func move_direction(input: Vector2) -> Vector3:
	if input.length() < 0.01:
		return Vector3.ZERO
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, camera_pivot.rotation.y).normalized() * minf(input.length(), 1.0)


## Melee attack against all enemies in a frontal cone. Returns hits.
## A strong attack hits harder, drains more Break and interrupts telegraphs.
func attack(strong: bool = false) -> int:
	if attack_cooldown > 0.0 or is_dodging or dead:
		return 0
	var cb := Content.combat()
	attack_cooldown = float(cb.get("strong_cooldown", 1.1)) if strong else float(stats.attack_cooldown)
	var power := int(round(Stats.attack() * (float(cb.get("strong_damage_mult", 1.6)) if strong else 1.0)))
	var brk := float(cb.get("break_strong", 25)) if strong else float(cb.get("break_light", 8))
	if lock_target:
		face(lock_target.global_position - global_position)
	var hits := 0
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Enemy
		if e == null or e.is_dead():
			continue
		var to := e.global_position - global_position
		to.y = 0.0
		if to.length() > float(stats.attack_range) + 0.5:
			continue
		if to.length() > 0.3 and forward().dot(to.normalized()) < ATTACK_CONE_DOT:
			continue
		e.take_hit(power, brk, strong)
		hits += 1
	visual.swing(strong)
	Sfx.play("hit" if hits > 0 else "swing")
	attacked.emit(hits)
	return hits


func nearest_enemy(max_range: float) -> Enemy:
	var best: Enemy = null
	var best_d := max_range
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Enemy
		if e == null or e.is_dead():
			continue
		var d := e.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func set_lock(e: Enemy) -> void:
	lock_target = e
	lock_changed.emit(e)


func face(dir: Vector3) -> void:
	var flat := Vector3(dir.x, 0, dir.z)
	if flat.length() > 0.01:
		visual.rotation.y = atan2(-flat.x, -flat.z)


func forward() -> Vector3:
	return Vector3(0, 0, -1).rotated(Vector3.UP, visual.rotation.y)


func start_dodge(dir: Vector3) -> void:
	is_dodging = true
	dodge_time_left = float(stats.dodge_time)
	invulnerable_time = float(stats.iframe_time)
	dodge_dir = dir.normalized() if dir.length() > 0.01 else forward()


## Applies incoming damage. Returns the damage actually taken.
func take_damage(raw_attack: int) -> int:
	if dead or invulnerable_time > 0.0:
		return 0
	var dmg := Stats.damage(raw_attack, Stats.defense())
	if is_blocking:
		dmg = maxi(1, int(round(dmg * (1.0 - float(stats.block_reduction)))))
	GameState.player.hp = maxi(0, int(GameState.player.hp) - dmg)
	Sfx.play("hurt")
	visual.hurt()
	damaged.emit(dmg)
	if GameState.player.hp == 0:
		dead = true
		died.emit()
		EventBus.player_died.emit()
	return dmg


func heal(amount: int) -> int:
	var before := int(GameState.player.hp)
	GameState.player.hp = mini(Stats.max_hp(), before + amount)
	var done := int(GameState.player.hp) - before
	healed.emit(done)
	return done


func revive_full() -> void:
	if is_inside_tree():
		for c in get_tree().get_nodes_in_group("party"):
			(c as Companion).revive(1.0)  # every full heal restores the whole party
	dead = false
	is_dodging = false
	set_lock(null)
	GameState.player.max_hp = Stats.max_hp()
	GameState.player.hp = Stats.max_hp()
