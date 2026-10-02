extends Node2D

@export var destination := "res://scenes/world/forest.tscn"
@export var portal_label := "Weiter zum Splitterwald"


func _ready() -> void:
	add_to_group("interactables")


func interact(_player: Node) -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world != null:
		if destination.ends_with("forest.tscn") and not world.gate_open:
			world.show_message("Der Weg ist versiegelt. Löse das Resonanzrätsel und öffne das Siegel.")
			return
		world.show_message(portal_label)
		world.save_game()
		var transfer_data := SaveManager.load_slot(1)
		if not transfer_data.is_empty():
			transfer_data["region"] = "forest" if destination.ends_with("forest.tscn") else "start"
			transfer_data["position"] = [170, 330] if destination.ends_with("forest.tscn") else [834, 358]
			GameManager.pending_save = transfer_data
			SaveManager.save_slot(1, transfer_data)
		SceneManager.change_scene(destination, GameManager.State.WORLD)


func _draw() -> void:
	draw_arc(Vector2.ZERO, 19.0, PI, TAU, 24, Color("#8bd6d0"), 4.0)
	draw_line(Vector2(-19, 0), Vector2(-19, 18), Color("#8bd6d0"), 4.0)
	draw_line(Vector2(19, 0), Vector2(19, 18), Color("#8bd6d0"), 4.0)
