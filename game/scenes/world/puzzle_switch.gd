extends Node2D

var activated := false


func _ready() -> void:
	add_to_group("interactables")


func interact(_player: Node) -> void:
	activated = not activated
	var world := get_tree().get_first_node_in_group("world")
	if world != null:
		world.set_puzzle_solved(activated)
		world.show_message("Der Resonanzschalter %s." % ("leuchtet" if activated else "erlischt"))


func _draw() -> void:
	draw_circle(Vector2.ZERO, 12.0, Color("#d6a65d") if activated else Color("#677d84"))
	draw_circle(Vector2.ZERO, 5.0, Color("#fff1ae") if activated else Color("#394951"))
