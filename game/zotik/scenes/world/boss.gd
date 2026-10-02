class_name Boss
extends Enemy
## Multi-phase boss (phases from data). Phase changes adjust attack and
## cooldown multipliers, switch the state-driven colour and may summon helpers.

signal phase_changed(index: int)

var phase := 0
var summons: Array[Enemy] = []


func take_hit(attack_value: int, break_amount: float = 0.0, interrupt: bool = false) -> int:
	var dmg := super(attack_value, break_amount, interrupt)
	_update_phase()
	return dmg


func _update_phase() -> void:
	if is_dead():
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
