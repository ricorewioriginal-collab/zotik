extends SceneTree
## Headless test runner.
## godot --headless --path game/zotik -s res://tests/run_tests.gd [-- filter]
## Exit code 0 = all passed, 1 = failures.

const DIR := "res://tests/unit/"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var filter := ""
	var json_path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--json="):
			json_path = a.trim_prefix("--json=")
		else:
			filter = a
	var results := []
	var files := Array(DirAccess.get_files_at(DIR)).filter(func(f): return f.begins_with("test_") and f.ends_with(".gd"))
	files.sort()
	var passed := 0
	var failed := 0
	for f in files:
		if filter != "" and not f.contains(filter):
			continue
		var script: GDScript = load(DIR + f)
		var methods := script.get_script_method_list().map(func(m): return m.name).filter(func(n): return n.begins_with("test_"))
		for m in methods:
			var t: TestCase = script.new()
			t.tree = self
			await t.before_each()
			await t.call(m)
			await t.after_each()
			if t.failures.is_empty():
				passed += 1
				results.append({"id": "%s::%s" % [f.get_basename(), m], "result": "PASS"})
				print("PASS %s::%s" % [f, m])
			else:
				failed += 1
				results.append({"id": "%s::%s" % [f.get_basename(), m], "result": "FAIL", "detail": "; ".join(t.failures)})
				print("FAIL %s::%s" % [f, m])
				for msg in t.failures:
					print("     - " + msg)
	print("RESULT passed=%d failed=%d" % [passed, failed])
	if json_path != "":
		var out := FileAccess.open(json_path, FileAccess.WRITE)
		if out:
			out.store_string(JSON.stringify({
				"last_run": Time.get_datetime_string_from_system(true),
				"engine": Engine.get_version_info().string,
				"runner": "tools/run_tests.sh",
				"result": "PASS" if failed == 0 and passed > 0 else "FAIL",
				"passed": passed, "failed": failed,
				"legacy_audit": "M00 legacy findings: docs/PHASE_1_AUDIT.md, tools/audit/m00_checks.sh",
				"tests": results}, "  "))
	quit(1 if failed > 0 or passed == 0 else 0)
