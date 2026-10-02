extends Node
## Root of a running game session: world container + UI layer.

@onready var world: Node3D = $World
@onready var ui: CanvasLayer = $UI


func _ready() -> void:
	print("ZOTIK game root ready")
