class_name Minimap
extends Control
## Round minimap drawn from layout data (cheap on Android: no second 3D
## render). North-up; shows props, exits, NPCs, enemies, the objective
## marker and Zotik's facing arrow. Clips its content to the circle.

const RANGE_M := 32.0
const REDRAW_SEC := 0.1

var hud: Node
var map: Control
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var clip := Control.new()
	clip.name = "Clip"
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	clip.draw.connect(func(): clip.draw_circle(clip.size / 2.0, clip.size.x / 2.0, Color(0.05, 0.09, 0.17, 0.92)))
	add_child(clip)
	map = Control.new()
	map.name = "Map"
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.draw.connect(_draw_map)
	clip.add_child(map)
	var ring := Control.new()
	ring.name = "Ring"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.draw.connect(func(): _draw_ring(ring))
	add_child(ring)


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = REDRAW_SEC
		map.queue_redraw()


func _game() -> Node:
	return hud.game if hud and hud.game else null


func _to_map(world: Vector3, origin: Vector3) -> Vector2:
	var k := (size.x / 2.0) / RANGE_M
	return size / 2.0 + Vector2(world.x - origin.x, world.z - origin.z) * k


func _draw_map() -> void:
	var g := _game()
	if g == null or g.area == null or g.player == null:
		return
	var p: Vector3 = g.player.global_position
	var k := (size.x / 2.0) / RANGE_M
	var lay: Dictionary = g.area.layout
	var sz: Array = lay.get("size", [20, 20])
	var floor_rect := Rect2(_to_map(Vector3(-float(sz[0]) / 2.0, 0, -float(sz[1]) / 2.0), p), Vector2(float(sz[0]), float(sz[1])) * k)
	map.draw_rect(floor_rect, Color.html(lay.get("ground", "#555555")).lightened(0.1))
	for pr in lay.get("props", []):
		var c := WorldArea._v(pr.pos)
		var s := WorldArea._v(pr.size)
		var col := Color.html(pr.color)
		col.a = 0.9
		map.draw_rect(Rect2(_to_map(c - s / 2.0, p), Vector2(s.x, s.z) * k), col.darkened(0.15))
	for x in lay.get("exits", []):
		var e := WorldArea._v(x.pos)
		var open: bool = g.area.is_exit_open(str(x.to))
		map.draw_rect(Rect2(_to_map(e, p) - Vector2(7, 4), Vector2(14, 8)), UiStyle.GOLD if open else Color(0.6, 0.3, 0.8))
	for n in g.area.entities.values():
		if not is_instance_valid(n) or not n.is_visible_in_tree():
			continue
		if n is Npc:
			map.draw_circle(_to_map(n.global_position, p), 4.0, UiStyle.CRYSTAL)
		elif n is Enemy and not n.is_dead():
			map.draw_circle(_to_map(n.global_position, p), 4.0 if not n is Boss else 7.0, Color(1.0, 0.3, 0.3))
	if g.beacon and g.beacon.visible:
		var b: Vector2 = _to_map(g.beacon.global_position, p)
		var r := size.x / 2.0 - 8.0
		if b.distance_to(size / 2.0) > r:
			b = size / 2.0 + (b - size / 2.0).normalized() * r
		map.draw_circle(b, 6.0, Color(1.0, 0.85, 0.2))
		map.draw_circle(b, 3.0, Color(0.3, 0.2, 0.0))
	var yaw: float = g.player.visual.rotation.y
	var fwd := Vector2(-sin(yaw), -cos(yaw))
	var side := Vector2(-fwd.y, fwd.x)
	var c0 := size / 2.0
	map.draw_colored_polygon(PackedVector2Array([c0 + fwd * 10.0, c0 - fwd * 6.0 + side * 6.0, c0 - fwd * 3.0, c0 - fwd * 6.0 - side * 6.0]), Color.WHITE)


func _draw_ring(ring: Control) -> void:
	var c := size / 2.0
	var r := size.x / 2.0
	ring.draw_arc(c, r - 2.0, 0, TAU, 64, UiStyle.GOLD, 3.0, true)
	ring.draw_arc(c, r - 6.0, 0, TAU, 64, Color(UiStyle.GOLD_DARK, 0.6), 1.0, true)
	ring.draw_string(UiStyle.title_font(), c + Vector2(-6, -r + 20), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiStyle.GOLD)
