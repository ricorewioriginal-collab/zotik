extends Node
## Runs dialogues and in-engine cutscenes (both are line sequences with
## optional effects). Requests arriving while one is running are queued.
## Effects run when a sequence ends; npc_talked is emitted for NPC dialogues.

signal started(seq_id: String)
signal line_shown(speaker: String, text: String)
signal finished(seq_id: String)

var active_id := ""
var active_npc := ""
var lines: Array = []
var index := -1
var queue: Array = []   # [{id, npc, table}]
var _table := ""


func is_active() -> bool:
	return active_id != ""


func _ready() -> void:
	EventBus.cutscene_requested.connect(play_cutscene)


## Picks the first NPC dialogue whose gates hold.
func select_for_npc(npc_id: String) -> String:
	for entry in Content.get_entry("npcs", npc_id).get("dialogues", []):
		if Conditions.all(entry.when):
			return entry.dialogue
	return ""


func talk_to(npc_id: String) -> void:
	var dlg := select_for_npc(npc_id)
	if dlg != "":
		_request(dlg, npc_id, "dialogues")


func play_cutscene(cut_id: String) -> void:
	_request(cut_id, "", "cutscenes")


func _request(id: String, npc: String, table: String) -> void:
	if is_active():
		queue.append({"id": id, "npc": npc, "table": table})
		return
	_begin(id, npc, table)


func _begin(id: String, npc: String, table: String) -> void:
	active_id = id
	active_npc = npc
	_table = table
	lines = Content.get_entry(table, id).get("lines", [])
	index = -1
	started.emit(id)
	advance()


## Shows the next line or ends the sequence.
func advance() -> void:
	if not is_active():
		return
	index += 1
	if index < lines.size():
		line_shown.emit(Content.speaker_name(lines[index][0]), lines[index][1])
		return
	var id := active_id
	var npc := active_npc
	var fx: Array = Content.get_entry(_table, id).get("effects", [])
	active_id = ""
	active_npc = ""
	lines = []
	Effects.run(fx)
	if npc != "":
		EventBus.npc_talked.emit(npc, id)
	EventBus.dialogue_finished.emit(id)
	finished.emit(id)
	if not queue.is_empty() and not is_active():
		var n: Dictionary = queue.pop_front()
		_begin(n.id, n.npc, n.table)


func current_speaker_id() -> String:
	return lines[index][0] if is_active() and index < lines.size() else ""


func reset() -> void:
	active_id = ""
	active_npc = ""
	lines = []
	queue.clear()
