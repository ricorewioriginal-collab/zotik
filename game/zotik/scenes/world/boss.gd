class_name Boss
extends Enemy
## Multi-phase boss (phases from data). Phase changes adjust attack and
## cooldown multipliers, switch the state-driven colour and may summon helpers.

signal phase_changed(index: int)

const SURGE_LENGTH := 60.0

var phase := 0
var summons: Array[Enemy] = []
var hazards: Array[Node3D] = []
var hazard_timer := 0.0


## Phase hazard (data "hazard"): a telegraphed eruption under Zotik that
## hits after `delay` if he is still inside `radius`, or (kind "surge") a
## water band across the whole arena at his depth that hits everyone within
## `width`/2 – sidestep forwards or backwards. Dodge i-frames apply.
func _physics_process(delta: float) -> void:
	super(delta)
	var hz: Dictionary = data.phases[phase].get("hazard", {})
	if hz.is_empty() or is_dead() or is_broken() or Dialogue.is_active() or state == State.IDLE:
		return
	hazard_timer -= delta
	if hazard_timer <= 0.0 and target and not target.dead:
		hazard_timer = float(hz.interval)
		spawn_hazard(target.global_position, hz)


func spawn_hazard(at: Vector3, hz: Dictionary) -> Node3D:
	var h := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	if hz.get("kind", "") == "surge":
		h.name = "PLACEHOLDER_water_surge"
		var b := BoxMesh.new()
		b.size = Vector3(SURGE_LENGTH, 0.05, float(hz.width))
		h.mesh = b
		mat.albedo_color = Color(0.2, 0.5, 1.0, 0.5)
	else:
		h.name = "PLACEHOLDER_root_eruption"
		var m := CylinderMesh.new()
		m.top_radius = float(hz.radius)
		m.bottom_radius = float(hz.radius)
		m.height = 0.05
		h.mesh = m
		mat.albedo_color = Color(0.9, 0.4, 0.1, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	h.material_override = mat
	get_parent().add_child(h)
	h.global_position = Vector3(0.0 if hz.get("kind", "") == "surge" else at.x, 0.03, at.z)
	hazards.append(h)
	get_tree().create_timer(float(hz.delay), false, true).timeout.connect(_erupt.bind(h, hz))
	return h


func _erupt(h: Node3D, hz: Dictionary) -> void:
	if not is_instance_valid(h):
		return
	hazards.erase(h)
	if is_instance_valid(target) and not is_dead():
		var flat := Vector2(target.global_position.x - h.global_position.x, target.global_position.z - h.global_position.z)
		var hit := absf(flat.y) <= float(hz.width) / 2.0 if hz.get("kind", "") == "surge" else flat.length() <= float(hz.radius)
		if hit:
			target.take_damage(int(hz.damage) + Stats.defense())  # hazard ignores armour
	h.queue_free()


func _clear_hazards() -> void:
	for h in hazards:
		if is_instance_valid(h):
			h.queue_free()
	hazards.clear()


func take_hit(attack_value: int, break_amount: float = 0.0, interrupt: bool = false) -> int:
	var dmg := super(attack_value, break_amount, interrupt)
	_update_phase()
	return dmg


func _update_phase() -> void:
	if is_dead():
		_clear_hazards()
		for s in summons:
			if is_instance_valid(s) and not s.is_dead():
				s.queue_free()
		summons.clear()
		return
	var phases: Array = data.phases
	var ratio := float(hp) / float(max_hp)
	var idx := 0
	for i in phases.size():
		if ratio <= float(phases[i].from_hp_ratio):
			idx = i
	if idx > phase:
		for i in range(phase + 1, idx + 1):
			_enter_phase(i)


func _enter_phase(i: int) -> void:
	phase = i
	var ph: Dictionary = data.phases[i]
	attack_mult = float(ph.get("attack_mult", 1.0))
	cooldown_mult = float(ph.get("cooldown_mult", 1.0))
	if ph.has("summon"):
		for n in int(ph.get("summon_count", 1)):
			var e: Enemy = Enemy.create({"enemy": ph.summon, "spawn": "%s_SUMMON_%d_%d" % [spawn_id, i, n], "pos": [0, 0, 0]})
			get_parent().add_child(e)
			e.global_position = global_position + Vector3(-3.0 + 6.0 * n, 0, 3.0)
			e.home = e.position
			summons.append(e)
	_set_tint(Color.WHITE)
	EventBus.notify.emit("%s: %s" % [data.name, ph.get("name", "")])
	phase_changed.emit(i)


func reset_encounter() -> void:
	_clear_hazards()
	hazard_timer = 0.0
	for s in summons:
		if is_instance_valid(s):
			s.queue_free()
	summons.clear()
	phase = 0
	attack_mult = 1.0
	cooldown_mult = 1.0
	super()


func base_color() -> Color:
	return Color.html(data.phases[phase].get("color", "#4a2a7a"))


func engaged() -> bool:
	return not is_dead() and (state != State.IDLE or hp < max_hp)
