class_name Interactable
extends Node3D
## Anything the player can use with "interact". The player picks the nearest
## enabled interactable within INTERACT_RANGE.

signal interacted

const INTERACT_RANGE := 2.6

var prompt := "Benutzen"
var enabled := true


func _enter_tree() -> void:
	add_to_group("interactable")


func can_interact() -> bool:
	return enabled and is_visible_in_tree()


func interact(_player: Node) -> void:
	interacted.emit()
