extends Node2D

signal defeated

var health := 3


func _ready() -> void:
	add_to_group("combat_targets")


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	if health == 0:
		defeated.emit()
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 15.0, Color("#6856a0"))
	draw_circle(Vector2(-5, -3), 2.0, Color("#fff0c5"))
	draw_circle(Vector2(5, -3), 2.0, Color("#fff0c5"))
	draw_line(Vector2(-6, 5), Vector2(6, 5), Color("#352b48"), 2.0)
