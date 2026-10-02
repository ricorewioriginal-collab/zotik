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
var dialogue_box: DialogueBox
var inventory_menu: InventoryMenu
var shop_menu: ShopMenu
var quest_log: QuestLog
var save_menu: SaveMenu
var pause_menu: PauseMenu
var factories := {}
var _entry_spawn := Vector3.ZERO


func _ready() -> void:
	add_to_group("game_root")
	factories = {"trigger": CutsceneTrigger.create, "npc": Npc.create, "chest": Chest.create, "enemy": Enemy.create, "puzzle": PuzzleNode.create, "savepoint": Savepoint.create}
	Dialogue.reset()
	hud = Hud.new()
	ui.add_child(hud)
	dialogue_box = DialogueBox.new()
	ui.add_child(dialogue_box)
	Dialogue.started.connect(_on_dialogue_started)
	inventory_menu = InventoryMenu.new()
	ui.add_child(inventory_menu)
	shop_menu = ShopMenu.new()
	ui.add_child(shop_menu)
	quest_log = QuestLog.new()
	ui.add_child(quest_log)
	quest_log.closed.connect(_update_control)
	save_menu = SaveMenu.new()
	ui.add_child(save_menu)
	save_menu.closed.connect(_update_control)
	pause_menu = PauseMenu.new()
	ui.add_child(pause_menu)
	pause_menu.closed.connect(_update_control)
	inventory_menu.closed.connect(_update_control)
	EventBus.quest_updated.connect(func(_q): _update_objective())
	shop_menu.closed.connect(_update_control)
	EventBus.shop_requested.connect(open_shop)
	Dialogue.finished.connect(_on_dialogue_finished)
	player = PLAYER_SCENE.instantiate()
	world.add_child(player)
	player.interactable_changed.connect(hud.set_prompt)
	inventory_menu.player = player
	player.died.connect(_on_player_died)
	EventBus.sync_state.connect(_sync_state)
	EventBus.travel_requested.connect(func(a, s): enter_area.call_deferred(a, s))
	if App.pending_load:
		App.pending_load = false
		var pos: Array = GameState.player.position
		enter_area(GameState.player.area, "", Vector3(pos[0], pos[1], pos[2]))
	else:
		enter_area(GameState.player.area, "default")
		App.new_game_started.emit()
		Dialogue.play_cutscene("CUT_LUN_DREAM_001")


func _on_dialogue_started(_id: String) -> void:
	player.control_enabled = false


func _on_dialogue_finished(_id: String) -> void:
	# Wait two physics frames so the key that closed the dialogue cannot
	# immediately re-trigger an interaction.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_update_control()


func is_menu_open() -> bool:
	return inventory_menu.visible or shop_menu.visible or quest_log.visible or save_menu.visible or pause_menu.visible


func _update_control() -> void:
	if is_instance_valid(player):
		player.control_enabled = not Dialogue.is_active() and not is_menu_open()


func open_shop(shop_id: String) -> void:
	shop_menu.open_shop(shop_id)
	_update_control()


func toggle_inventory() -> void:
	if inventory_menu.visible:
		inventory_menu.close_menu()
	elif not Dialogue.is_active() and not shop_menu.visible:
		inventory_menu.open()
	_update_control()


func open_save_menu() -> void:
	save_menu.open()
	_update_control()


func toggle_quest_log() -> void:
	if quest_log.visible:
		quest_log.close_menu()
	elif not Dialogue.is_active() and not is_menu_open():
		quest_log.open()
	_update_control()


func _update_objective() -> void:
	var lines := []
	for id in Quests.active_quests():
		lines.append(("★ " if id == Quests.MAIN else "• ") + Quests.objective(id))
	hud.set_objective("\n".join(lines))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	elif event.is_action_pressed("quest_log"):
		toggle_quest_log()
	elif event.is_action_pressed("menu") and not is_menu_open() and not Dialogue.is_active():
		get_viewport().set_input_as_handled()
		pause_menu.open()
		_update_control()


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
	_entry_spawn = WorldArea._v(Content.layout(area_id).get("spawns", {}).get(spawn, Content.layout(area_id).get("spawns", {}).get("default", [0, 0, 0])))
	player.global_position = pos_override if pos_override != null else _entry_spawn
	player.velocity = Vector3.ZERO
	area = WorldArea.new()
	world.add_child(area)
	area.build(area_id, factories)
	area.exit_requested.connect(_on_exit_requested, CONNECT_DEFERRED)
	GameState.player.area = area_id
	_sync_state()
	_update_objective()
	area_loaded.emit(area_id)
	EventBus.area_entered.emit(area_id)


## Death: the encounter in the current area resets, the player respawns at
## the area entry with full health. Quest/world progress is kept.
func _on_player_died() -> void:
	EventBus.notify.emit("Zotik ist gefallen …")
	await get_tree().create_timer(1.5).timeout
	if not is_instance_valid(player):
		return
	for n in get_tree().get_nodes_in_group("enemy"):
		(n as Enemy).reset_encounter()
	player.revive_full()
	player.global_position = _entry_spawn
	player.velocity = Vector3.ZERO
	EventBus.notify.emit("Zotik steht wieder auf.")


func _on_exit_requested(target: String) -> void:
	enter_area(target, area.area_id)


func _sync_state() -> void:
	if player:
		var p := player.global_position
		GameState.player.position = [p.x, p.y, p.z]
