extends TestCase
## Level sanity: with every gate open, every entity and exit of each area is
## reachable on foot from the default spawn (grid flood fill over floors,
## minus collidable props inflated by the player radius; props removed by a
## flag count as open).

const CELL := 0.5
const RADIUS := 0.4


func _blocked_boxes(l: Dictionary) -> Array:
	var out := []
	for p in l.get("props", []):
		if p.get("collision", true) and not p.has("requires_flag") and not p.has("hidden_by_flag"):
			var c := WorldArea._v(p.pos)
			var s := WorldArea._v(p.size)
			if c.y - s.y / 2.0 < 1.0:  # only obstacles at walking height
				out.append(Rect2(c.x - s.x / 2.0 - RADIUS, c.z - s.z / 2.0 - RADIUS, s.x + 2 * RADIUS, s.z + 2 * RADIUS))
	return out


func _floor_rects(l: Dictionary) -> Array:
	var out := []
	var size: Array = l.get("size", [20, 20])
	var floors: Array = l.get("floors", [{"pos": [0, -0.5, 0], "size": [size[0], 1, size[1]]}])
	for f in floors:
		var c := WorldArea._v(f.pos)
		var s := WorldArea._v(f.size)
		out.append(Rect2(c.x - s.x / 2.0, c.z - s.z / 2.0, s.x, s.z))
	for en in l.get("entities", []):
		if en.type == "platform":
			var a := WorldArea._v(en.pos)
			var b := WorldArea._v(en.to)
			var s := WorldArea._v(en.get("size", [4, 1, 4]))
			out.append(Rect2(minf(a.x, b.x) - s.x / 2.0, minf(a.z, b.z) - s.z / 2.0, absf(a.x - b.x) + s.x, absf(a.z - b.z) + s.z))
	for p in l.get("props", []):
		if p.has("requires_flag") and p.get("collision", true):
			var c := WorldArea._v(p.pos)
			var s := WorldArea._v(p.size)
			out.append(Rect2(c.x - s.x / 2.0, c.z - s.z / 2.0, s.x, s.z))
	return out


func _walkable(pt: Vector2, l: Dictionary, floors: Array, blocks: Array) -> bool:
	var size: Array = l.get("size", [20, 20])
	var hx: float = size[0] / 2.0 - 0.5 - RADIUS
	var hz: float = size[1] / 2.0 - 0.5 - RADIUS
	if absf(pt.x) > hx or absf(pt.y) > hz:
		return false
	if not floors.any(func(r): return r.grow(-0.2).has_point(pt)):
		return false
	return not blocks.any(func(r): return r.has_point(pt))


func _key(pt: Vector2) -> Vector2i:
	return Vector2i(roundi(pt.x / CELL), roundi(pt.y / CELL))


func test_everything_reachable_from_spawn() -> void:
	for area in Content.layouts:
		var l: Dictionary = Content.layout(area)
		var floors := _floor_rects(l)
		var blocks := _blocked_boxes(l)
		var start_v := WorldArea._v(l.spawns.default)
		var start := _key(Vector2(start_v.x, start_v.z))
		check(_walkable(Vector2(start) * CELL, l, floors, blocks), "%s: default spawn blocked" % area)
		var seen := {start: true}
		var queue := [start]
		while not queue.is_empty():
			var c: Vector2i = queue.pop_back()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = c + d
				if not seen.has(n) and _walkable(Vector2(n) * CELL, l, floors, blocks):
					seen[n] = true
					queue.append(n)
		var targets := {}
		for x in l.get("exits", []):
			targets["exit " + str(x.to)] = WorldArea._v(x.pos)
		for key in l.spawns:
			targets["spawn " + key] = WorldArea._v(l.spawns[key])
		for en in l.get("entities", []):
			if not en.type in ["trigger", "platform"]:
				targets[en.get("spawn", en.get("id", ""))] = WorldArea._v(en.pos)
		for name in targets:
			var t: Vector3 = targets[name]
			# Reachable if any cell within interaction range is reachable.
			var ok := false
			for dx in range(-5, 6):
				for dz in range(-5, 6):
					var cell := _key(Vector2(t.x, t.z)) + Vector2i(dx, dz)
					if seen.has(cell) and (Vector2(cell) * CELL).distance_to(Vector2(t.x, t.z)) <= 2.4:
						ok = true
			check(ok, "%s: %s not reachable on foot" % [area, name])
