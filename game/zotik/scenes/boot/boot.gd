extends Node
## Boot: validates the core, then opens the title screen.

func _ready() -> void:
	print("ZOTIK %s – boot" % App.VERSION)
	App.goto_scene.call_deferred(App.SCENE_TITLE)
