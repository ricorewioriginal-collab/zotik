class_name TestCase
extends RefCounted
## Minimal assertion base for headless tests. Methods named test_* are run
## by tests/run_tests.gd; they may be coroutines (await).

var tree: SceneTree
var failures: Array[String] = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func eq(actual: Variant, expected: Variant, msg: String) -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s: expected %s (%s), got %s (%s)" % [msg, var_to_str(expected), type_string(typeof(expected)), var_to_str(actual), type_string(typeof(actual))])


func frames(n: int = 1) -> void:
	for i in n:
		await tree.process_frame


func physics_frames(n: int = 1) -> void:
	for i in n:
		await tree.physics_frame
