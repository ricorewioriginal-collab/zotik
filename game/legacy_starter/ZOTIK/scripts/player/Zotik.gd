extends CharacterBody3D
class_name Zotik

@export var move_speed: float = 5.5
@export var acceleration: float = 18.0
@export var gravity: float = 18.0
@export var dodge_speed: float = 11.0

var can_control := true
var is_dodging := false
var dodge_time := 0.0

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.1

    if not can_control:
        move_and_slide()
        return

    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := Vector3(input_vec.x, 0.0, input_vec.y)

    if direction.length() > 0.01:
        direction = direction.normalized()
        velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
        velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
        look_at(global_position + Vector3(direction.x, 0.0, direction.z), Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

    if Input.is_action_just_pressed("dodge") and not is_dodging:
        _start_dodge(direction)

    if is_dodging:
        dodge_time -= delta
        if dodge_time <= 0.0:
            is_dodging = false

    move_and_slide()

func _start_dodge(direction: Vector3) -> void:
    is_dodging = true
    dodge_time = 0.22
    var dodge_dir := direction if direction.length() > 0.01 else -global_transform.basis.z
    velocity.x = dodge_dir.x * dodge_speed
    velocity.z = dodge_dir.z * dodge_speed
