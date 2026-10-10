class_name GameRoot
extends Node
## Root of a running game session: streams one WorldArea at a time, owns
## the player and the HUD, and wires gameplay systems together.

const VOID_Y := -15.0
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

signal area_loaded(area_id: String)
signal chapter_complete

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
var world_map: WorldMap
var bounty_menu: BountyMenu
var bestiary_menu: BestiaryMenu
var arena_menu: ArenaMenu
var ngplus_menu: NgPlusMenu
var casino_menu: CasinoMenu
var arena_run: ArenaRun
var touch: TouchControls
var companions := {}  # PARTY_* -> Companion
var beacon: ObjectiveBeacon
var beacon_target := ""  # entity key or "exit:<area>"
var factories := {}
var _entry_spawn := Vector3.ZERO


func _ready() -> void:
	SaveSystem.autosave_ready = DisplayServer.get_name() != "headless"
	add_to_group("game_root")
	factories = {"trigger": CutsceneTrigger.create, "npc": Npc.create, "chest": Chest.create, "enemy": Enemy.create, "puzzle": PuzzleNode.create, "savepoint": Savepoint.create, "unique": UniquePedestal.create, "travel": TravelPoint.create, "platform": MovingPlatform.create, "lore": LoreBook.create, "bounty_board": BountyBoard.create, "casino": CasinoEntrance.create}
	Dialogue.reset()
	hud = Hud.new()
	hud.game = self
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
	var guide := GuideMenu.new()
	guide.name = "GuideMenu"
	ui.add_child(guide)
	guide.closed.connect(_update_control)
	world_map = WorldMap.new()
	ui.add_child(world_map)
	world_map.closed.connect(_update_control)
	bounty_menu = BountyMenu.new()
	ui.add_child(bounty_menu)
	bounty_menu.closed.connect(_update_control)
	bestiary_menu = BestiaryMenu.new()
	ui.add_child(bestiary_menu)
	bestiary_menu.closed.connect(_update_control)
	arena_menu = ArenaMenu.new()
	arena_menu.game = self
	ui.add_child(arena_menu)
	arena_menu.closed.connect(_update_control)
	casino_menu = CasinoMenu.new()
	ui.add_child(casino_menu)
	casino_menu.closed.connect(_update_control)
	ngplus_menu = NgPlusMenu.new()
	ui.add_child(ngplus_menu)
	ngplus_menu.closed.connect(_update_control)
	arena_run = ArenaRun.new()
	add_child(arena_run)
	touch = TouchControls.new()
	touch.game = self
	ui.add_child(touch)
	EventBus.menu_requested.connect(func(m): open_menu(arena_menu if m == "arena" else (ngplus_menu if m == "ngplus" else casino_menu)))
	inventory_menu.closed.connect(_update_control)
	EventBus.quest_updated.connect(func(_q): _update_objective())
	EventBus.quest_completed.connect(_on_quest_completed)
	shop_menu.closed.connect(_update_control)
	EventBus.shop_requested.connect(open_shop)
	Dialogue.finished.connect(_on_dialogue_finished)
	player = PLAYER_SCENE.instantiate()
	world.add_child(player)
	beacon = ObjectiveBeacon.new()
	world.add_child(beacon)
	EventBus.flag_changed.connect(func(_f, _v): update_beacon.call_deferred())
	EventBus.enemy_defeated.connect(func(_e): update_beacon.call_deferred())
	EventBus.chest_opened.connect(func(_c): update_beacon.call_deferred())
	player.interactable_changed.connect(hud.set_prompt)
	inventory_menu.player = player
	player.died.connect(_on_player_died)
	player.damaged.connect(func(_d): hud.flash_hurt())
	EventBus.sync_state.connect(_sync_state)
	EventBus.party_changed.connect(_sync_party)
	EventBus.travel_requested.connect(func(a, s): transition.call_deferred(a, s))
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
	return inventory_menu.visible or shop_menu.visible or quest_log.visible or save_menu.visible or pause_menu.visible or ui.get_node("GuideMenu").visible or world_map.visible or bounty_menu.visible or bestiary_menu.visible or arena_menu.visible or casino_menu.visible or ngplus_menu.visible


func _update_control() -> void:
	if is_instance_valid(player):
		player.control_enabled = not Dialogue.is_active() and not is_menu_open()
		_update_mouse()


## Mouse is captured for camera control while playing, free in menus.
func _update_mouse() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var capture := player.control_enabled and not player.dead and not (touch and (touch.force or TouchControls.wanted()))
	var want := Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != want:
		Input.mouse_mode = want


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and is_instance_valid(player):
		_update_mouse()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Android: app to background; browser: tab hidden; desktop: window closed
		SaveSystem.autosave()


func _exit_tree() -> void:
	SaveSystem.autosave_ready = false


## Places the beacon on the guided objective, or on the exit towards it.
func update_beacon() -> void:
	if not is_instance_valid(area):
		return
	beacon_target = ""
	var target := Navigator.step_target(Navigator.guided_quest())
	var pos = null
	if not target.is_empty():
		if target.area == area.area_id:
			var key: String = target.entity
			if key.begins_with("enemy:"):
				var best: Enemy = null
				for n in get_tree().get_nodes_in_group("enemy"):
					var e := n as Enemy
					if e and e.enemy_id == key.trim_prefix("enemy:") and not e.is_dead() and (best == null or e.global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position)):
						best = e
				if best:
					pos = best.global_position
			elif area.entities.has(key) and is_instance_valid(area.entities[key]):
				pos = area.entities[key].global_position
			beacon_target = key
		else:
			var r := Navigator.route(area.area_id, target.area)
			if r.has("exit") and area.exits.has(r.exit):
				pos = area.exits[r.exit].trigger.global_position - Vector3(0, 1.5, 0)
				beacon_target = "exit:" + r.exit
			elif r.has("travel"):
				for key in area.entities:
					if str(key).begins_with("TRAVEL_"):
						pos = area.entities[key].global_position
						beacon_target = key
	beacon.visible = pos != null
	if pos != null:
		beacon.global_position = pos


func open_shop(shop_id: String) -> void:
	shop_menu.open_shop(shop_id)
	_update_control()


func toggle_inventory() -> void:
	if inventory_menu.visible:
		inventory_menu.close_menu()
	elif not Dialogue.is_active() and not shop_menu.visible:
		inventory_menu.open()
	_update_control()


func _on_quest_completed(id: String) -> void:
	var notice: String = Content.get_entry("quests", id).get("completion_notice", "")
	if notice != "":
		EventBus.notify.emit(notice)
		chapter_complete.emit()


## Opens a menu panel if nothing else is open.
func open_menu(m: MenuPanel) -> void:
	if not Dialogue.is_active() and not is_menu_open():
		m.open()
	_update_control()


func open_world_map() -> void:
	world_map.open()
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
		lines.append(("» " if Content.get_entry("quests", id).get("type") == "main" else "• ") + Quests.objective(id))
	hud.set_objective("\n".join(lines))
	update_beacon.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	elif event.is_action_pressed("quest_log"):
		toggle_quest_log()
	elif event.is_action_pressed("bestiary"):
		if bestiary_menu.visible:
			bestiary_menu.close_menu()
		else:
			open_menu(bestiary_menu)
	elif event.is_action_pressed("help") and not is_menu_open() and not Dialogue.is_active():
		get_viewport().set_input_as_handled()
		pause_menu.open()
		_update_control()
	elif event is InputEventMouseButton and event.pressed and player.control_enabled and DisplayServer.get_name() != "headless":
		_update_mouse()
	elif event.is_action_pressed("menu") and not is_menu_open() and not Dialogue.is_active():
		get_viewport().set_input_as_handled()
		pause_menu.open()
		_update_control()


func _process(delta: float) -> void:
	GameState.play_time += delta
	if beacon.visible and beacon_target.begins_with("enemy:"):
		update_beacon()


func _physics_process(_delta: float) -> void:
	if player and player.global_position.y < VOID_Y:
		player.global_position = _entry_spawn
		player.velocity = Vector3.ZERO
		player.take_damage(10)
		EventBus.notify.emit("Zurück auf sicheren Boden.")


## Loads an area. spawn: spawn key; pos_override: exact position (save load).
func enter_area(area_id: String, spawn: String, pos_override = null) -> void:
	if arena_run.active():
		arena_run.abort()
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
	_sync_party()
	SaveSystem.autosave()
	for c in companions.values():
		c.snap_to_player()
	_update_objective()
	area_loaded.emit(area_id)
	EventBus.area_entered.emit(area_id)


func start_arena(id: String) -> bool:
	return arena_run.start(id, self)


## Death: the encounter in the current area resets, the player respawns at
## the area entry with full health. Quest/world progress is kept.
func _on_player_died() -> void:
	if arena_run.active():
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(player):
			arena_run.lose()
		return
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


## Spawns/removes companions so they match GameState.party.
func _sync_party() -> void:
	for id in companions.keys():
		if not id in GameState.party:
			companions[id].queue_free()
			companions.erase(id)
	for id in GameState.party:
		if not companions.has(id) and Content.has_id("party", id):
			var c := Companion.create(id, player)
			world.add_child(c)
			companions[id] = c
			c.snap_to_player()


func _on_exit_requested(target: String) -> void:
	transition(target, area.area_id)


var _veil: ColorRect
var _transitioning := false


## Area change with a short dark veil: the (synchronous) area build then happens
## behind a loading screen instead of a frozen picture. Without a window (tests,
## headless) it is a plain enter_area.
func transition(area_id: String, spawn: String) -> void:
	if DisplayServer.get_name() == "headless" or _transitioning:
		enter_area(area_id, spawn)
		return
	_transitioning = true
	if _veil == null:
		_veil = ColorRect.new()
		_veil.name = "LoadingVeil"
		_veil.color = Color(0.02, 0.03, 0.07, 1.0)
		_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_veil.mouse_filter = Control.MOUSE_FILTER_STOP
		var lb := UiStyle.title("Die Welt wird geladen …", 26, UiStyle.GOLD)
		lb.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lb.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_veil.add_child(lb)
		ui.add_child(_veil)
	_veil.modulate.a = 0.0
	_veil.show()
	var tin := create_tween()
	tin.tween_property(_veil, "modulate:a", 1.0, 0.18)
	await tin.finished
	await get_tree().process_frame  # make sure the veil is on screen before the heavy work
	enter_area(area_id, spawn)
	await get_tree().process_frame
	await get_tree().process_frame
	var tout := create_tween()
	tout.tween_property(_veil, "modulate:a", 0.0, 0.4)
	await tout.finished
	_veil.hide()
	_transitioning = false


func _sync_state() -> void:
	if player:
		var p := player.global_position
		GameState.player.position = [p.x, p.y, p.z]
