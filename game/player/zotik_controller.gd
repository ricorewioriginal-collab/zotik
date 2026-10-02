extends CharacterBody2D

signal interacted(target: Node)
signal attacked(target: Node)

const MOVE_SPEED := 190.0
const INTERACT_DISTANCE := 42.0
const ATTACK_DISTANCE := 52.0

var facing_direction := Vector2.DOWN
var health := 5


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()
	velocity = direction * MOVE_SPEED
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		_interact_with_nearest()
	if Input.is_action_just_pressed("attack"):
		_attack_nearest()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, 4), 12.0, Color(0.17, 0.12, 0.12, 0.25))
	draw_rect(Rect2(-8, -3, 16, 18), Color("#e96b35"), true)
	draw_circle(Vector2(0, -9), 10.0, Color("#f28a43"))
	draw_circle(Vector2(-3, -10), 1.4, Color("#292222"))
	draw_circle(Vector2(3, -10), 1.4, Color("#292222"))
	draw_line(Vector2.ZERO, facing_direction * 12.0, Color("#ffe0a5"), 2.0)


func _interact_with_nearest() -> void:
	var target := _nearest_node("interactables", INTERACT_DISTANCE)
	if target != null and target.has_method("interact"):
		target.interact(self)
		interacted.emit(target)


func _attack_nearest() -> void:
	var target := _nearest_node("combat_targets", ATTACK_DISTANCE)
	if target != null and target.has_method("take_damage"):
		target.take_damage(1)
		attacked.emit(target)


func _nearest_node(group_name: String, maximum_distance: float) -> Node2D:
	var nearest: Node2D
	var nearest_distance := maximum_distance
	for candidate in get_tree().get_nodes_in_group(group_name):
		if not candidate is Node2D:
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance <= nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest
