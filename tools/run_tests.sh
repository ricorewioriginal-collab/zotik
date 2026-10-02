#!/usr/bin/env bash
# Runs the headless test suite of game/zotik.
# Usage: GODOT=/path/to/godot4.7 tools/run_tests.sh [--json=/abs/path.json] [filter]
# A hard timeout turns a hanging run (e.g. a runner that fails to compile) into a failure.
set -euo pipefail
GODOT="${GODOT:?set GODOT to a Godot 4.7 binary}"
PROJ="$(cd "$(dirname "$0")/../game/zotik" && pwd)"
timeout 300 "$GODOT" --headless --path "$PROJ" --import >/dev/null 2>&1 || true
timeout "${TEST_TIMEOUT:-600}" "$GODOT" --headless --path "$PROJ" -s res://tests/run_tests.gd -- "$@"
