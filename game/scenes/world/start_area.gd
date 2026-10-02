extends Node2D

@export var is_forest := false

var player: CharacterBody2D
var collected_items: Array[String] = []
var puzzle_solved := false
var gate_open := false
var message_label: Label
var pause_panel: PanelContainer


func _ready() -> void:
	add_to_group("world")
	GameManager.set_state(GameManager.State.WORLD)
	_build_environment()
	player = get_node("Zotik")
	var saved_data := GameManager.pending_save
	GameManager.pending_save = {}
	if not saved_data.is_empty():
		var saved_region: String = saved_data.get("region", "start")
		if (saved_region == "forest") == is_forest:
			var saved_position: Array = saved_data.get("position", [])
			if saved_position.size() == 2:
				player.position = Vector2(saved_position[0], saved_position[1])
		collected_items.assign(saved_data.get("collected_items", []))
		puzzle_solved = saved_data.get("puzzle_solved", false)
		gate_open = saved_data.get("gate_open", false)
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup.get("item_id") in collected_items:
			pickup.queue_free()
	if gate_open:
		get_node("SealedGate").queue_free()
	message_label.text = "Splitterwald" if is_forest else "Startgebiet"
	_update_objective()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 620), Color("#90b581"), true)
	draw_rect(Rect2(0, 360, 960, 90), Color("#b9a876"), true)
	draw_rect(Rect2(0, 380, 960, 30), Color("#c9bb91"), true)
	for x in range(0, 960, 64):
		draw_circle(Vector2(x + 32, 112), 35, Color("#6c956e"))
		draw_rect(Rect2(x + 27, 125, 10, 32), Color("#82674d"), true)
	draw_rect(Rect2(110, 188, 98, 82), Color("#c9a070"), true)
	draw_rect(Rect2(104, 180, 110, 14), Color("#765b50"), true)
	draw_rect(Rect2(695, 158, 170, 112), Color("#8a7664"), true)
	draw_rect(Rect2(684, 148, 192, 16), Color("#615860"), true)
	draw_circle(Vector2(740, 335), 30, Color("#719b9b"))
	draw_circle(Vector2(740, 335), 17, Color("#a8d6cf"))


func show_message(text: String) -> void:
	message_label.text = text


func collect_item(item_id: String, display_name: String) -> void:
	if item_id in collected_items:
		return
	collected_items.append(item_id)
	show_message("Erhalten: %s" % display_name)
	_update_objective()


func set_puzzle_solved(value: bool) -> void:
	puzzle_solved = value
	_update_objective()


func save_game() -> void:
	var region := "forest" if is_forest else "start"
	var payload := {
		"region": region,
		"position": [player.position.x, player.position.y],
		"collected_items": collected_items,
		"puzzle_solved": puzzle_solved,
		"gate_open": gate_open,
	}
	GameManager.pending_save = payload.duplicate(true)
	SaveManager.save_slot(1, payload)


func open_gate() -> void:
	gate_open = true
	_update_objective()


func _build_environment() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	message_label = Label.new()
	message_label.position = Vector2(24, 18)
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color("#fff0cd"))
	canvas.add_child(message_label)

	var controls := Label.new()
	controls.anchor_left = 1.0
	controls.anchor_right = 1.0
	controls.offset_left = -350
	controls.offset_top = 18
	controls.offset_right = -24
	controls.offset_bottom = 60
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.text = "WASD / Pfeile bewegen  ·  E interagieren  ·  Leertaste angreifen  ·  Esc pausieren"
	controls.add_theme_color_override("font_color", Color("#fff0cd"))
	canvas.add_child(controls)

	pause_panel = PanelContainer.new()
	pause_panel.visible = false
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-150, -105)
	pause_panel.custom_minimum_size = Vector2(300, 210)
	canvas.add_child(pause_panel)
	var pause_contents := VBoxContainer.new()
	pause_contents.add_theme_constant_override("separation", 10)
	pause_contents.add_theme_constant_override("margin_left", 18)
	pause_contents.add_theme_constant_override("margin_right", 18)
	pause_contents.add_theme_constant_override("margin_top", 18)
	pause_contents.add_theme_constant_override("margin_bottom", 18)
	pause_panel.add_child(pause_contents)
	var heading := Label.new()
	heading.text = "Pause"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_contents.add_child(heading)
	var resume := Button.new()
	resume.text = "Weiter"
	resume.pressed.connect(_toggle_pause)
	pause_contents.add_child(resume)
	var save := Button.new()
	save.text = "Speichern"
	save.pressed.connect(save_game)
	pause_contents.add_child(save)
	var menu := Button.new()
	menu.text = "Hauptmenü"
	menu.pressed.connect(_return_to_menu)
	pause_contents.add_child(menu)

	if OS.has_feature("android"):
		var mobile_controls := preload("res://ui/mobile_controls.tscn").instantiate()
		canvas.add_child(mobile_controls)


func _update_objective() -> void:
	if message_label == null:
		return
	if is_forest:
		message_label.text = "Splitterwald · Erkunde den Wald und finde den Rückweg"
	elif gate_open:
		message_label.text = "Startgebiet · Der Weg zum Splitterwald ist frei"
	elif puzzle_solved:
		message_label.text = "Startgebiet · Resonanz aktiv: öffne das Siegel"
	else:
		message_label.text = "Startgebiet · Sprich mit der Hüterin, aktiviere den Schalter"


func _toggle_pause() -> void:
	pause_panel.visible = not pause_panel.visible
	get_node("Zotik").set_physics_process(not pause_panel.visible)


func _return_to_menu() -> void:
	save_game()
	SceneManager.change_scene("res://scenes/ui/main_menu.tscn", GameManager.State.MAIN_MENU)
