#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)

# Lint GDScript (if linter exists)
if command -v python3 >/dev/null 2>&1; then
	python3 MCP/TOOLS/gdscript_linter.py || true
fi

# Run scene lint if available
if [ -f "$ROOT_DIR/MCP/GODOT_TOOLS/scene_lint.py" ]; then
	python3 "$ROOT_DIR/MCP/GODOT_TOOLS/scene_lint.py" || true
fi

# Run GUT tests
godot4 --headless --path "$ROOT_DIR/godot_project" -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gexit
