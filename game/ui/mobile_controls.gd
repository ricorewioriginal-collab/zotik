extends Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_button("◀", "move_left", Vector2(28, -142))
	_build_button("▶", "move_right", Vector2(138, -142))
	_build_button("▲", "move_up", Vector2(83, -198))
	_build_button("▼", "move_down", Vector2(83, -86))
	_build_button("E", "interact", Vector2(-154, -145))
	_build_button("●", "attack", Vector2(-78, -74))


func _build_button(label: String, action: String, offset: Vector2) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(62, 62)
	button.anchor_left = 0.0 if offset.x >= 0 else 1.0
	button.anchor_right = button.anchor_left
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.position = offset
	button.modulate = Color(1, 1, 1, 0.78)
	button.button_down.connect(Input.action_press.bind(action))
	button.button_up.connect(Input.action_release.bind(action))
	add_child(button)
