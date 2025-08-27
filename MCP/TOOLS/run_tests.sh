#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
godot4 --headless --path "$ROOT_DIR/godot_project" -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gexit
