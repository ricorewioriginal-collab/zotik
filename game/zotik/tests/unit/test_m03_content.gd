extends TestCase


func test_all_tables_load() -> void:
	eq(Content.load_errors.size(), 0, "load errors: %s" % [Content.load_errors])
	for t in Content.TABLES:
		check(not Content.table(t).is_empty(), "table %s empty" % t)


func test_content_validates_clean() -> void:
	var errors := Content.validate()
	eq(errors.size(), 0, "validation errors: %s" % [errors])


func test_validator_detects_broken_reference() -> void:
	var q: Dictionary = Content.tables.quests.QUEST_MAIN_LUN_001
	var old = q.steps[0].condition.npc
	q.steps[0].condition.npc = "NPC_DOES_NOT_EXIST"
	var errors := Content.validate()
	q.steps[0].condition.npc = old
	check(errors.any(func(x): return x.contains("NPC_DOES_NOT_EXIST")), "broken npc ref not detected")


func test_validator_detects_bad_namespace_and_duplicates() -> void:
	Content.tables.items["healing_potion"] = {"name": "x", "type": "consumable"}
	Content.tables.flags["ITEM_HEALING_POTION_001"] = {}
	var errors := Content.validate()
	Content.load_all()
	check(errors.any(func(x): return x.contains("outside namespaces")), "namespace not detected")
	check(errors.any(func(x): return x.contains("duplicate id")), "duplicate not detected")
	eq(Content.validate().size(), 0, "reload restores clean content")


func test_canonical_phase1_ids_present() -> void:
	var errors := Content.validate()
	check(not errors.any(func(x): return x.begins_with("canonical")), "canonical ids missing")
	check(Content.item("WEAPON_WORLD_BLADE_001").get("unique", false), "world blade must be unique")


func test_legacy_items_migrated() -> void:
	var legacy := {}
	for id in Content.table("items"):
		if Content.item(id).has("legacy_id"):
			legacy[Content.item(id).legacy_id] = id
	for old in ["healing_potion", "moon_pendant", "moonblade", "rift_shard"]:
		check(legacy.has(old), "legacy item %s not migrated" % old)


func test_dialogues_marked_placeholder() -> void:
	# Invented text must be marked placeholder (C-10); only text copied from
	# a project document may be final, and it must cite its source.
	for t in ["dialogues", "cutscenes"]:
		for id in Content.table(t):
			var d := Content.get_entry(t, id)
			check(d.get("placeholder", false) or str(d.get("source", "")).length() > 5, "%s must be placeholder or cite a source (C-10)" % id)
