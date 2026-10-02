#!/usr/bin/env bash
# Full regression: unit/integration suite, then the golden path with a real
# process restart between save and load (docs/08_ACCEPTANCE_TESTS.md).
# Usage: GODOT=/path/to/godot4.7 tools/run_regression.sh [--json=/abs/path.json]
set -euo pipefail
GODOT="${GODOT:?set GODOT to a Godot 4.7 binary}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJ="$ROOT/game/zotik"
"$ROOT/tools/run_tests.sh" "$@"
echo "== restart check (new process)"
timeout 120 "$GODOT" --headless --path "$PROJ" -s res://tests/restart_check.gd
