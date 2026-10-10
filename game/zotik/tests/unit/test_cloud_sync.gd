extends TestCase

const C := preload("res://core/cloud_sync.gd")
const DIR := "user://test_cloud_saves/"


func before_each() -> void:
	SaveSystem.save_dir = DIR
	SaveSystem.reset_migrations()
	for slot in range(SaveSystem.AUTO_SLOT, SaveSystem.SLOT_COUNT + 1):
		SaveSystem.delete_slot(slot)
	GameState.reset_new_game()


func after_each() -> void:
	before_each()
	SaveSystem.save_dir = "user://saves/"


func test_merge_newer_wins_per_slot() -> void:
	var local := {"zotik_save_1": {"v": "a", "t": 100}, "zotik_save_2": {"v": "b", "t": 300}, "zotik_save_3": {"v": "c", "t": 50}}
	var remote := {"zotik_save_1": {"v": "A", "t": 200}, "zotik_save_2": {"v": "B", "t": 300.0}, "zotik_save_0": {"v": "Z", "t": 10}}
	var m := C.merge(local, remote)
	eq(m.apply.keys().size(), 2, "apply count")
	check(m.apply.has("zotik_save_1") and m.apply.has("zotik_save_0"), "remote newer/missing applied")
	eq(m.push.keys(), ["zotik_save_3"], "only local-newer pushed, ties ignored")


func test_doc_round_trip_plain_and_compressed() -> void:
	var small := {"zotik_save_1": {"v": "x", "t": 1}}
	var d1 := C.encode_doc(small)
	check(not d1.begins_with("z:"), "small stays plain JSON")
	eq(C.decode_doc(d1).keys(), small.keys(), "plain round trip")
	var big := {"zotik_save_1": {"v": "y".repeat(60000), "t": 2}}
	var d2 := C.encode_doc(big)
	check(d2.begins_with("z:") and d2.length() < 5000, "large doc is gzip-compressed")
	eq(C.decode_doc(d2).zotik_save_1.v.length(), 60000, "compressed round trip")
	eq(C.decode_doc("not json"), {}, "garbage gives empty")
	# gzip written by another implementation (Node zlib, like the browser's CompressionStream)
	eq(C.decode_doc("z:H4sIAAAAAAAAA6tWqsovycyOL04sS403VLKqVipTslLKSMzJyVfSUSpRsjKtrQUAY+6s2iQAAAA=").zotik_save_1.v, "hallo", "foreign gzip decodes")


func test_raw_text_and_store_raw_round_trip() -> void:
	GameState.player = {"area": "AREA_LUN_FOREST", "position": [1.0, 0.0, 2.0], "hp": 50, "max_hp": 100}
	eq(SaveSystem.save_slot(1), SaveSystem.Status.OK, "save")
	var text := SaveSystem.raw_text(1)
	check(text != "", "raw text exists")
	check(C.envelope_ms(text) > 0, "save time parsed")
	eq(SaveSystem.raw_text(2), "", "empty slot has no raw text")
	check(SaveSystem.store_raw(2, text), "store into other slot")
	eq(SaveSystem.slot_info(2).status, SaveSystem.Status.OK, "stored slot loads")
	check(not SaveSystem.store_raw(3, "{\"broken\":1}"), "invalid text refused")
	check(not SaveSystem.store_raw(9, text), "bad slot refused")


func test_signed_out_by_default() -> void:
	var c := C.new()
	check(not c.signed_in(), "fresh instance is signed out")
	c.free()
