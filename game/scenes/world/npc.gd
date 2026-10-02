extends Node2D

@export var character_id := "zotik:npc:forest_keeper"
@export_multiline var greeting := "Willkommen am Rand des Splitterwalds, Zotik. Folge dem leuchtenden Pfad."


func _ready() -> void:
	add_to_group("interactables")


func interact(_player: Node) -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world != null:
		world.show_message(greeting)


func _draw() -> void:
	draw_circle(Vector2(0, 3), 13.0, Color("#42695a"))
	draw_circle(Vector2(0, -9), 9.0, Color("#ddb688"))
	draw_rect(Rect2(-8, -2, 16, 17), Color("#487f68"), true)
	draw_circle(Vector2(-3, -10), 1.3, Color("#292222"))
	draw_circle(Vector2(3, -10), 1.3, Color("#292222"))
