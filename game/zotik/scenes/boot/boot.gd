extends Node
## Boot: validates the content, then opens the title screen.

func _ready() -> void:
	print("ZOTIK %s – boot" % App.VERSION)
	var errors := Content.validate()
	if errors.is_empty():
		print("CONTENT OK (%d tables)" % Content.tables.size())
	else:
		for e in errors:
			push_error("CONTENT ERROR: " + e)
	App.goto_scene.call_deferred(App.SCENE_TITLE)
