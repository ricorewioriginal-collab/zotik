class_name Warmup
extends RefCounted
## Pays the first-use costs of the game (loading models, building character rigs
## and creature meshes) one small step per frame while the title screen is up,
## so that walking into a new world later does not freeze (R07). The most
## important jobs run first; if the player starts the game earlier, the rest is
## simply skipped. Does nothing in headless runs (tests) and runs once per start.

static var started := false
static var progress := 0.0
static var timings := {}  # category -> ms (for the profile script)


static func _jobs() -> Array:
	var jobs := []  # [category, Callable]
	jobs.append(["zotik", func(): ZotikVisual.new().free()])
	for id in Npc.LOOKS:
		if id.begins_with("NPC_MIRA") or id.begins_with("NPC_TOREN") or id.begins_with("NPC_BORO") or id.begins_with("NPC_SARI"):
			var look: Array = Npc.LOOKS[id]
			jobs.append(["npc", func(): CharacterRig.create_human(look[0], float(look[1])).free()])
	for dir in [Look.NATURE_DIR, Look.PROPS_DIR, Look.VILLAGE_DIR]:
		var d := DirAccess.open(dir.get_base_dir())
		if d == null:
			continue
		for f in d.get_files():
			if f.ends_with(".gltf"):
				var nm := f.get_basename()
				jobs.append(["models", func(): Look.model_box(nm)])
	for id in Companion.LOOKS:
		var look: Array = Companion.LOOKS[id]
		jobs.append(["party", func(): CharacterRig.create_human(look[0], float(look[1])).free()])
	for id in Npc.LOOKS:
		var look: Array = Npc.LOOKS[id]
		jobs.append(["npc", func(): CharacterRig.create_human(look[0], float(look[1])).free()])
	for id in Content.table("enemies"):
		var eid: String = id
		jobs.append(["creatures", func(): CreatureVisual.create(eid, Color.WHITE).free()])
	var d2 := DirAccess.open(Look.MODEL_DIR.get_base_dir())
	if d2:
		for f in d2.get_files():
			if f.ends_with(".gltf"):
				var nm2 := f.get_basename()
				jobs.append(["kaykit", func(): Look.model_box(nm2)])
	return jobs


static func run(host: Node) -> void:
	if started or DisplayServer.get_name() == "headless":
		return
	started = true
	var tree := host.get_tree()
	var jobs := _jobs()
	var total := jobs.size()
	var i := 0
	while i < total:
		if not is_instance_valid(host) or not host.is_inside_tree():
			return  # the player already left the title screen: stop quietly
		# several small jobs per frame, but never more than about 6 ms of work
		var frame_start := Time.get_ticks_usec()
		while i < total and (Time.get_ticks_usec() - frame_start < 6000 or i == 0):
			var t0 := Time.get_ticks_usec()
			(jobs[i][1] as Callable).call()
			timings[jobs[i][0]] = float(timings.get(jobs[i][0], 0.0)) + (Time.get_ticks_usec() - t0) / 1000.0
			i += 1
			progress = float(i) / float(total)
		await tree.process_frame
