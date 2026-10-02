class_name ArenaRun
extends Node
## Runs one arena challenge (data/arena.json): spawns waves around the arena
## centre, advances when a wave is cleared, pays out on victory. Defeat is
## safe: no game over, Zotik is healed and placed at the arena entrance.

signal wave_started(index: int)
signal finished(won: bool)

var challenge_id := ""
var wave := -1
var alive: Array[Enemy] = []
var game: Node


func start(id: String, root: Node) -> bool:
	if not Content.has_id("arena", id) or not ArenaRun.unlocked(id):
		return false
	challenge_id = id
	game = root
	game.player.global_position = game.area.spawn_point("arena_center")
	game.player.revive_full()
	EventBus.notify.emit("Arena: %s beginnt!" % Content.get_entry("arena", id).name)
	_next_wave()
	return true


static func unlocked(id: String) -> bool:
	var flag: String = Content.get_entry("arena", id).get("requires_flag", "")
	return flag == "" or GameState.has_flag(flag)


func active() -> bool:
	return challenge_id != ""


func _next_wave() -> void:
	wave += 1
	var waves: Array = Content.get_entry("arena", challenge_id).waves
	if wave >= waves.size():
		_win()
		return
	var n := 0
	for grp in waves[wave]:
		for i in int(grp.count):
			var e := Enemy.create({"enemy": grp.enemy, "spawn": "SPAWN_ARENA_%d_%d" % [wave, n], "pos": [0, 0, 0]})
			game.area.add_child(e)
			var ang := TAU * n / 6.0
			e.global_position = Vector3(cos(ang) * 8.0, 0.2, -6.0 + sin(ang) * 6.0)
			e.home = e.position
			e.data = e.data.duplicate()
			e.data["aggro_range"] = 60.0
			e.defeated.connect(_on_defeated)
			alive.append(e)
			n += 1
	wave_started.emit(wave)
	EventBus.notify.emit("Welle %d / %d" % [wave + 1, waves.size()])


func _on_defeated(e: Enemy) -> void:
	alive.erase(e)
	if alive.is_empty() and active():
		_next_wave.call_deferred()


func _win() -> void:
	var data := Content.get_entry("arena", challenge_id)
	var first := not GameState.arena.has(challenge_id)
	GameState.arena[challenge_id] = int(GameState.arena.get(challenge_id, 0)) + 1
	Inventory.add_currency(int(data.get("reward_currency", 0)))
	if first:
		for r in data.get("first_clear", []):
			Inventory.add(r.id, int(r.get("count", 1)))
		Effects.run(data.get("on_first_clear", []))
	EventBus.notify.emit("Sieg im %s! +%d Lun" % [data.name, int(data.get("reward_currency", 0))])
	_end(true)


## Called by the game root instead of the normal death handling.
func lose() -> void:
	for e in alive:
		if is_instance_valid(e):
			e.queue_free()
	alive.clear()
	EventBus.notify.emit("Niederlage in der Arena – kein Verlust, versuch es nochmal!")
	game.player.revive_full()
	game.player.global_position = game.area.spawn_point("default")
	_end(false)


## Leaving the arena mid-run cancels the challenge without reward.
func abort() -> void:
	alive.clear()
	_end(false)


func _end(won: bool) -> void:
	challenge_id = ""
	wave = -1
	finished.emit(won)
