class_name GameRoot
extends Node
## Root of a running game session: streams one WorldArea at a time, owns
## the player and the HUD, and wires gameplay systems together.

const VOID_Y := -15.0
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

signal area_loaded(area_id: String)

@onready var world: Node3D = $World
@onready var ui: CanvasLayer = $UI

var player: Player
var area: WorldArea
var hud: Hud
var factories := {}
var _entry_spawn := Vector3.ZERO


func _ready() -> void:
	add_to_group("game_root")
	factories = {"trigger": CutsceneTrigger.create}
	hud = Hud.new()
	ui.add_child(hud)
	player = PLAYER_SCENE.instantiate()
	world.add_child(player)
	player.interactable_changed.connect(hud.set_prompt)
	EventBus.sync_state.connect(_sync_state)
	EventBus.travel_requested.connect(func(a, s): enter_area.call_deferred(a, s))
	if App.pending_load:
		App.pending_load = false
		var pos: Array = GameState.player.position
		enter_area(GameState.player.area, "", Vector3(pos[0], pos[1], pos[2]))
	else:
		enter_area(GameState.player.area, "default")
		App.new_game_started.emit()


func _process(delta: float) -> void:
	GameState.play_time += delta


func _physics_process(_delta: float) -> void:
	if player and player.global_position.y < VOID_Y:
		player.global_position = _entry_spawn
		player.velocity = Vector3.ZERO
		player.take_damage(10)
		EventBus.notify.emit("Zurück auf sicheren Boden.")


## Loads an area. spawn: spawn key; pos_override: exact position (save load).
func enter_area(area_id: String, spawn: String, pos_override = null) -> void:
	if area:
		world.remove_child(area)
		area.queue_free()
	area = WorldArea.new()
	world.add_child(area)
	area.build(area_id, factories)
	area.exit_requested.connect(_on_exit_requested, CONNECT_DEFERRED)
	GameState.player.area = area_id
	_entry_spawn = area.spawn_point(spawn)
	player.global_position = pos_override if pos_override != null else _entry_spawn
	player.velocity = Vector3.ZERO
	_sync_state()
	area_loaded.emit(area_id)
	EventBus.area_entered.emit(area_id)


func _on_exit_requested(target: String) -> void:
	enter_area(target, area.area_id)


func _sync_state() -> void:
	if player:
		var p := player.global_position
		GameState.player.position = [p.x, p.y, p.z]
