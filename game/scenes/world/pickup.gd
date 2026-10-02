extends Node2D

@export var item_id := "zotik:item:healing_fruit"
@export var display_name := "Heilfrucht"


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("pickups")


func interact(_player: Node) -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world != null:
		world.collect_item(item_id, display_name)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color("#e06c65"))
	draw_line(Vector2(0, -7), Vector2(3, -12), Color("#82b677"), 3.0)
