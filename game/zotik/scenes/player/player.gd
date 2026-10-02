class_name Player
extends CharacterBody3D
## Zotik player controller: camera-relative movement, jump, dodge with
## invulnerability frames, block, health. Stats come from Content/Stats,
## persistent values from GameState. Independent of the visual mesh.

signal damaged(amount: int)
signal healed(amount: int)
signal died

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
	shape.radius = 0.35
	shape.height = 1.7
	col.shape = shape
	col.position.y = 0.85
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
	camera_pivot.global_position = global_position + Vector3(0, 1.4, 0)
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
		if dir.length() > 0.01:
			face(dir)
	move_and_slide()
	camera_pivot.global_position = global_position + Vector3(0, 1.4, 0)


## Converts stick/WASD input into a world direction relative to the camera yaw.
func move_direction(input: Vector2) -> Vector3:
	if input.length() < 0.01:
		return Vector3.ZERO
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, camera_pivot.rotation.y).normalized() * minf(input.length(), 1.0)


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
	dead = false
	GameState.player.max_hp = Stats.max_hp()
	GameState.player.hp = Stats.max_hp()
