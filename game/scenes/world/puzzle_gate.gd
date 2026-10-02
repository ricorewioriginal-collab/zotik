extends Node2D

var is_open := false


func _ready() -> void:
	add_to_group("interactables")


func interact(_player: Node) -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world != null and world.puzzle_solved:
		world.open_gate()
		world.show_message("Das Resonanzsiegel öffnet sich. Der Pfad zum Wald ist frei.")
		queue_free()
	elif world != null:
		world.show_message("Das Siegel reagiert nicht. Aktiviere zuerst den Resonanzschalter.")


func _draw() -> void:
	draw_rect(Rect2(-13, -24, 26, 48), Color("#55717a"), true)
	draw_rect(Rect2(-5, -12, 10, 24), Color("#b1d1cd"), false, 2.0)
