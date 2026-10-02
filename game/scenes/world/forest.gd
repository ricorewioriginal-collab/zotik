extends Node2D

const START_AREA := "res://scenes/world/start_area.tscn"

var player: CharacterBody2D
var message_label: Label
var collected_items: Array = []
var puzzle_solved := false
var gate_open := false


func _ready() -> void:
	add_to_group("world")
	player = get_node("Zotik")
	var saved := GameManager.pending_save
	GameManager.pending_save = {}
	if saved.get("region", "") == "forest":
		var saved_position: Array = saved.get("position", [])
		if saved_position.size() == 2:
			player.position = Vector2(saved_position[0], saved_position[1])
		collected_items.assign(saved.get("collected_items", []))
		puzzle_solved = saved.get("puzzle_solved", false)
		gate_open = saved.get("gate_open", false)
	_build_hud()
	GameManager.set_state(GameManager.State.WORLD)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		return_to_start()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 620), Color("#789d7b"), true)
	for x in range(0, 960, 75):
		draw_circle(Vector2(x + 30, 110), 42, Color("#53775f"))
		draw_rect(Rect2(x + 26, 123, 8, 44), Color("#806348"), true)
	draw_rect(Rect2(0, 375, 960, 70), Color("#b5a77c"), true)
	draw_circle(Vector2(520, 325), 42, Color("#78a6a0"))
	draw_circle(Vector2(520, 325), 24, Color("#aadbd2"))


func return_to_start() -> void:
	save_game()
	SceneManager.change_scene(START_AREA, GameManager.State.WORLD)


func save_game() -> void:
	SaveManager.save_slot(1, {
		"region": "forest",
		"position": [player.position.x, player.position.y],
		"collected_items": collected_items,
		"puzzle_solved": puzzle_solved,
		"gate_open": gate_open,
	})
	GameManager.pending_save = SaveManager.load_slot(1)


func show_message(text: String) -> void:
	message_label.text = text


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	message_label = Label.new()
	message_label.position = Vector2(24, 18)
	message_label.text = "Splitterwald · Folge dem Pfad zurück"
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color("#fff0cd"))
	canvas.add_child(message_label)
	var controls := Label.new()
	controls.anchor_left = 1.0
	controls.anchor_right = 1.0
	controls.offset_left = -280
	controls.offset_top = 18
	controls.offset_right = -24
	controls.offset_bottom = 56
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.text = "E interagieren  ·  Esc zurück"
	controls.add_theme_color_override("font_color", Color("#fff0cd"))
	canvas.add_child(controls)
	if OS.has_feature("android"):
		canvas.add_child(preload("res://ui/mobile_controls.tscn").instantiate())
