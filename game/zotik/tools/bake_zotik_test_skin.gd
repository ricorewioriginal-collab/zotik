extends SceneTree
## Offline bake (run once after a new zotik_test.glb): fits the Hunyuan3D test
## mesh onto the shared CC0 human skeleton (Quaternius, as used by
## ZotikVisual) so the human animation library can drive it. PLACEHOLDER.
## godot --headless --path game/zotik -s res://tools/bake_zotik_test_skin.gd
##
## Method: pose the human rig at Idle_Loop frame 0 (arms down, like the
## generated mesh), map every joint into Zotik's proportions (piecewise along
## the height via landmarks, per-height width ratio), store the new bone rest
## translations, bind the mesh in that pose and copy skin weights from the
## warped human body (k nearest vertices). Animations key only rotations plus
## the pelvis position, so changed rest translations survive playback.

const SRC := "res://assets/characters/custom/zotik_test.glb"
const OUT := "res://assets/characters/custom/zotik_test_skinned.res"
const HUMAN := "res://assets/characters/quaternius/Superhero_Male_FullBody.gltf"
## Zotik landmarks as fraction of the mesh height (ear tips = 1.0), read off
## the front view of the generated mesh (tools/models/hunyuan_postprocess.py).
const Z_KNEE := 0.2
const Z_HIP := 0.43
const Z_NECK := 0.72
const Z_HEAD := 0.77
const Z_HEAD_TOP := 0.93
## behind the back (fraction of height): tail/blade, rigid on pelvis or upper spine
const Z_TAIL_BEHIND := -0.14
## farther than this (fraction of height) from the warped human body = outside part
const FAR := 0.07
## |x| below this between knee and hip (fraction of height): sash, on the pelvis
const Z_BETWEEN_LEGS := 0.03
const SMOOTH_PASSES := 3
const K := 4


func _initialize() -> void:
	var human: Node3D = (load(HUMAN) as PackedScene).instantiate()
	root.add_child(human)
	var sk: Skeleton3D = human.find_children("*", "Skeleton3D", true, false)[0]
	var body: MeshInstance3D = null
	for mi in human.find_children("*", "MeshInstance3D", true, false):
		if body == null or mi.mesh.get_faces().size() > body.mesh.get_faces().size():
			body = mi
	# 1) idle pose, frame 0
	var lib: AnimationLibrary = load(CharacterRig.HUMAN_ANIMS)
	var idle := lib.get_animation(CharacterRig.HUMAN_STATES.idle)
	for t in idle.get_track_count():
		var b := sk.find_bone(str(idle.track_get_path(t).get_concatenated_subnames()))
		if b < 0:
			continue
		if idle.track_get_type(t) == Animation.TYPE_ROTATION_3D:
			sk.set_bone_pose_rotation(b, idle.rotation_track_interpolate(t, 0.0))
		elif idle.track_get_type(t) == Animation.TYPE_POSITION_3D:
			sk.set_bone_pose_position(b, idle.position_track_interpolate(t, 0.0))
	var nb := sk.get_bone_count()
	var g_h: Array[Transform3D] = []
	for b in nb:
		g_h.append(sk.get_bone_global_pose(b))
	# 2) CPU-skin the human body in that pose (skeleton space)
	var ha := body.mesh.surface_get_arrays(0)
	var hv: PackedVector3Array = ha[Mesh.ARRAY_VERTEX]
	var hb: PackedInt32Array = ha[Mesh.ARRAY_BONES]
	var hw: PackedFloat32Array = ha[Mesh.ARRAY_WEIGHTS]
	var bpv: int = hb.size() / hv.size()
	var skin: Skin = body.skin
	var bind_bone := PackedInt32Array()
	var bind_mat: Array[Transform3D] = []
	for i in skin.get_bind_count():
		var bb := skin.get_bind_bone(i)
		if skin.get_bind_name(i) != &"":
			bb = sk.find_bone(skin.get_bind_name(i))
		bind_bone.append(bb)
		bind_mat.append(g_h[bb] * skin.get_bind_pose(i))
	var hp := PackedVector3Array()
	hp.resize(hv.size())
	var hbone := PackedInt32Array()  # per human vertex: skeleton bone indices (bpv)
	hbone.resize(hb.size())
	for i in hv.size():
		var p := Vector3.ZERO
		for j in bpv:
			var w := hw[i * bpv + j]
			hbone[i * bpv + j] = bind_bone[hb[i * bpv + j]]
			if w > 0.0:
				p += (bind_mat[hb[i * bpv + j]] * hv[i]) * w
		hp[i] = p
	var top_h := -INF
	for p in hp:
		top_h = maxf(top_h, p.y)
	var pel := sk.find_bone("pelvis")
	var hip_h := g_h[pel].origin.y
	var knee_h := g_h[sk.find_bone("calf_l")].origin.y
	var neck_h := g_h[sk.find_bone("neck_01")].origin.y
	var head_h := g_h[sk.find_bone("Head")].origin.y
	# 3) Zotik mesh in skeleton units: hips at the human hip height
	var zscene: Node = (load(SRC) as PackedScene).instantiate()
	var zmi: MeshInstance3D = zscene.find_children("*", "MeshInstance3D", true, false)[0]
	var za := zmi.mesh.surface_get_arrays(0)
	zscene.free()
	var k := hip_h / Z_HIP
	var zv: PackedVector3Array = za[Mesh.ARRAY_VERTEX]
	for i in zv.size():
		zv[i] *= k
	za[Mesh.ARRAY_VERTEX] = zv
	var ys := PackedFloat32Array([0.0, knee_h, hip_h, neck_h, head_h, top_h])
	var yz := PackedFloat32Array([0.0, Z_KNEE * k, Z_HIP * k, Z_NECK * k, Z_HEAD * k, Z_HEAD_TOP * k])
	# width ratio per height band (95th percentile of |x|, tail excluded)
	var bands := 24
	var hwid := _band_widths(hp, top_h, bands, func(y): return y, -INF)
	var zwid := _band_widths(zv, top_h, bands, func(y): return _map(y, yz, ys), Z_TAIL_BEHIND * k)
	var sx := PackedFloat32Array()
	for i in bands:
		sx.append(clampf(zwid[i] / maxf(hwid[i], 0.01), 0.5, 3.0) if hwid[i] > 0.0 and zwid[i] > 0.0 else 1.0)
	var warp := func(p: Vector3) -> Vector3:
		var s := _band_value(sx, p.y / top_h)
		return Vector3(p.x * s, _map(p.y, ys, yz), p.z * s)
	# 4) new rests: joints at their warped positions, rotations unchanged
	var g_z: Array[Transform3D] = []
	var rests := {}
	for b in nb:
		var target: Vector3 = warp.call(g_h[b].origin)
		var par := sk.get_bone_parent(b)
		var local := g_h[b].origin if par < 0 else g_z[par].basis.inverse() * (target - g_z[par].origin)
		if par < 0:
			target = g_h[b].origin
		elif b == pel:
			# the animations key the pelvis position; keep it as authored
			local = sk.get_bone_pose_position(b)
			target = g_z[par] * local
		g_z.append(Transform3D(g_h[b].basis, target))
		rests[sk.get_bone_name(b)] = local
	# 5) weights: k nearest warped human vertices (grid lookup)
	var wp := PackedVector3Array()
	wp.resize(hp.size())
	for i in hp.size():
		wp[i] = warp.call(hp[i])
	var cell := 0.06 * k
	var grid := {}
	for i in wp.size():
		var key := Vector3i((wp[i] / cell).floor())
		if not grid.has(key):
			grid[key] = PackedInt32Array()
		grid[key].append(i)
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var tail_z := Z_TAIL_BEHIND * k
	var spine3 := sk.find_bone("spine_03")
	var vw: Array[Dictionary] = []
	for i in zv.size():
		var p := zv[i]
		var acc := {}
		var near := _nearest(grid, wp, p, cell)
		# behind the back (tail, blade) or far outside the human body (scarf
		# flap): rigid on the torso instead of picking up arm/leg weights
		var outside: bool = near.is_empty() or float(near[0][0]) > FAR * k
		var between_legs := absf(p.x) < Z_BETWEEN_LEGS * k and p.y > Z_KNEE * k and p.y < Z_HIP * k
		if between_legs or (p.y > Z_KNEE * k and (p.z < tail_z or outside)):
			acc[pel if p.y < (Z_HIP + Z_NECK) * 0.5 * k else spine3] = 1.0
		else:
			for n in near:
				var w := 1.0 / maxf(n[0], 1e-4)
				for j in bpv:
					var hwj := hw[n[1] * bpv + j]
					if hwj > 0.0:
						var bi := hbone[n[1] * bpv + j]
						acc[bi] = acc.get(bi, 0.0) + hwj * w
		vw.append(acc)
	# smooth weights over mesh neighbours (no hard pelvis/thigh seams that tear)
	var idx: PackedInt32Array = za[Mesh.ARRAY_INDEX]
	var nbr: Array[PackedInt32Array] = []
	nbr.resize(zv.size())
	for t in range(0, idx.size(), 3):
		for e in 3:
			nbr[idx[t + e]].append(idx[t + (e + 1) % 3])
			nbr[idx[t + (e + 1) % 3]].append(idx[t + e])
	for it in SMOOTH_PASSES:
		var nxt: Array[Dictionary] = []
		for i in zv.size():
			var sum := _normalized(vw[i])
			for j in nbr[i]:
				var o := _normalized(vw[j])
				for bi in o:
					sum[bi] = sum.get(bi, 0.0) + o[bi]
			nxt.append(sum)
		vw = nxt
	for acc in vw:
		var pairs := []
		for bi in acc:
			pairs.append([acc[bi], bi])
		pairs.sort_custom(func(a, c): return a[0] > c[0])
		var total := 0.0
		for j in mini(4, pairs.size()):
			total += pairs[j][0]
		for j in 4:
			if j < pairs.size():
				bones.append(pairs[j][1])
				weights.append(pairs[j][0] / total)
			else:
				bones.append(0)
				weights.append(0.0)
	za[Mesh.ARRAY_BONES] = bones
	za[Mesh.ARRAY_WEIGHTS] = weights
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, za)
	out.resource_name = "PLACEHOLDER_zotik_test_skinned"
	var zskin := Skin.new()
	for b in nb:
		zskin.add_named_bind(sk.get_bone_name(b), g_z[b].affine_inverse())
	out.set_meta("skin", zskin)
	out.set_meta("bone_rests", rests)
	out.set_meta("height_units", k)
	var err := ResourceSaver.save(out, OUT)
	print("baked ", OUT, " err=", err, " verts=", zv.size(), " k=", k, " widths=", sx)
	human.queue_free()
	quit(0 if err == OK else 1)


static func _normalized(d: Dictionary) -> Dictionary:
	var total := 0.0
	for v in d.values():
		total += v
	var out := {}
	for b in d:
		out[b] = d[b] / total
	return out


## Piecewise-linear map of v from the xs knots onto the ys knots (linear extrapolation).
static func _map(v: float, xs: PackedFloat32Array, ys: PackedFloat32Array) -> float:
	var i := 0
	while i < xs.size() - 2 and v > xs[i + 1]:
		i += 1
	return ys[i] + (v - xs[i]) * (ys[i + 1] - ys[i]) / (xs[i + 1] - xs[i])


static func _band_value(vals: PackedFloat32Array, f: float) -> float:
	var x := clampf(f, 0.0, 1.0) * (vals.size() - 1)
	var i := mini(int(x), vals.size() - 2)
	return lerpf(vals[i], vals[i + 1], x - i)


## 95th percentile of |x| per band; band index from to_ref(y) / ref_h (human height).
static func _band_widths(pts: PackedVector3Array, ref_h: float, bands: int, to_ref: Callable, min_z: float) -> PackedFloat32Array:
	var buckets := []
	for i in bands:
		buckets.append(PackedFloat32Array())
	for p in pts:
		if p.z < min_z:
			continue
		var f: float = to_ref.call(p.y) / ref_h
		var i := clampi(int(f * bands), 0, bands - 1)
		buckets[i].append(absf(p.x))
	var out := PackedFloat32Array()
	for b in buckets:
		var arr: PackedFloat32Array = b
		if arr.size() < 8:
			out.append(0.0)
			continue
		arr.sort()
		out.append(arr[int(arr.size() * 0.95)])
	return out


static func _nearest(grid: Dictionary, pts: PackedVector3Array, p: Vector3, cell: float) -> Array:
	var c := Vector3i((p / cell).floor())
	var found := []
	for r in range(1, 6):
		found.clear()
		for x in range(c.x - r, c.x + r + 1):
			for y in range(c.y - r, c.y + r + 1):
				for z in range(c.z - r, c.z + r + 1):
					var key := Vector3i(x, y, z)
					if grid.has(key):
						for i in grid[key]:
							found.append([p.distance_to(pts[i]), i])
		if found.size() >= K:
			break
	found.sort_custom(func(a, b): return a[0] < b[0])
	return found.slice(0, K)
