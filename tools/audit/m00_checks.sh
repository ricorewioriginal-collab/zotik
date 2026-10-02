#!/usr/bin/env bash
# M00 repository audit checks for game/legacy_starter/ZOTIK.
# Runs against a temporary copy; the legacy starter itself is never modified.
# Usage: GODOT=/path/to/Godot_v4.7-stable_linux.x86_64 tools/audit/m00_checks.sh
set -u
GODOT="${GODOT:?set GODOT to a Godot 4.7 binary}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

run() { timeout 120 "$GODOT" --headless "$@" 2>&1; }

echo "## Godot version"; run --version | tail -1

cp -a "$ROOT/game/legacy_starter/ZOTIK" "$WORK/orig"
echo "## A1 original project.godot loads"
if run --path "$WORK/orig" --quit-after 5 | grep -q "Error parsing"; then echo "FAIL"; else echo "PASS"; fi

cp -a "$WORK/orig" "$WORK/fixed"
sed -i 's/\("axis_value":1\.0)\]\)$/\1}/' "$WORK/fixed/project.godot"
echo "## A2 copy with closing brace on move_right loads"
if run --path "$WORK/fixed" --quit-after 5 | grep -q "Error parsing"; then echo "FAIL"; else echo "PASS"; fi

echo "## A3 GDScript --check-only"
for f in $(cd "$WORK/fixed" && find scripts -name '*.gd' | sort); do
  if run --path "$WORK/fixed" --check-only --script "$f" | grep -q "ERROR"; then echo "FAIL $f"; else echo "PASS $f"; fi
done

cat > "$WORK/fixed/probe.gd" <<'GD'
extends SceneTree
func _init():
	for k in [4194321, 4194325]:
		print("KEY ", k, " = ", OS.get_keycode_string(k))
	var b = load("res://scripts/break/BreakSystem.gd").new()
	var t := Node.new(); var n := [0, 0]
	b.break_completed.connect(func(_x): n[0] += 1)
	b.break_started.connect(func(_x): n[1] += 1)
	b.reduce(t, 100); b.reduce(t, 10); b.reduce(t, 10)
	print("BREAK completed_emits=", n[0], " started_emits=", n[1])
	var tl = load("res://scripts/timeline/TimelineSystem.gd").new()
	var fired := [0]
	tl.action_ready.connect(func(_a): fired[0] += 1)
	tl.register_actor(Node.new(), 200.0); tl.register_actor(Node.new(), 50.0)
	tl.advance(0.0)
	print("TIMELINE fired_on_zero_delta=", fired[0])
	var s = load("res://scripts/save/SaveManager.gd").new()
	s.save_game(1, {"a": 1})
	print("SAVE int_preserved=", typeof(s.load_game(1).get("a")) == TYPE_INT)
	var f := FileAccess.open("user://saves/slot_02.json", FileAccess.WRITE); f.store_string("{broken"); f = null
	print("SAVE corrupt_returns_empty=", s.load_game(2).is_empty())
	quit()
GD
echo "## A4 behaviour probes"
run --path "$WORK/fixed" -s probe.gd | grep -E '^(KEY|BREAK|TIMELINE|SAVE)'
