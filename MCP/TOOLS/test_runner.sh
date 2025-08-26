#!/usr/bin/env bash
# Close-to-Shore unified test runner
set -euo pipefail

MODE=${1:-all}
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"

RUN_ID=${RUN_ID:-$(date -u +"%Y%m%dT%H%M%SZ")}
OUT_FILE="$LOG_DIR/run-${RUN_ID}-testrunner.out"

echo "[TestRunner] RUN_ID=$RUN_ID" | tee -a "$OUT_FILE"
export RUN_ID

godot_cmd() {
    godot4 --headless --path "$ROOT_DIR/godot_project" "$@"
}

run_suite() {
    local name="$1"; shift
    echo "[TestRunner] Running $name..." | tee -a "$OUT_FILE"
    if "$@" 2>&1 | tee -a "$OUT_FILE"; then
        echo "[TestRunner] ✓ $name PASSED" | tee -a "$OUT_FILE"
        return 0
    else
        echo "[TestRunner] ✗ $name FAILED" | tee -a "$OUT_FILE"
        return 1
    fi
}

overall_success=true

case "$MODE" in
    all)
    run_suite "GUT: All" godot_cmd -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix test_ -gexit || overall_success=false
        ;;
    integration)
    run_suite "GUT: Integration" godot_cmd -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/integration -ginclude_subdirs -gprefix test_ -gexit || overall_success=false
        ;;
    ui)
    run_suite "GUT: UI" godot_cmd -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/ui -ginclude_subdirs -gprefix test_ -gexit || overall_success=false
        ;;
    smoke)
        run_suite "Smoke: Scenes from Index" godot_cmd -s res://scripts/tools/scene_smoke_runner.gd -- --index res://scripts/tools/scene_index.json || overall_success=false
        ;;
    e2e)
        run_suite "E2E: Scene Switch" godot_cmd -s res://scripts/tools/e2e_scene_switch_runner.gd || overall_success=false
        ;;
    *)
        echo "[TestRunner] Unknown MODE: $MODE" | tee -a "$OUT_FILE"
        exit 2
        ;;
esac

if [ "$overall_success" = true ]; then
    echo "[TestRunner] 🎉 ALL TESTS PASSED - Ready for next hop!" | tee -a "$OUT_FILE"
    exit 0
else
    echo "[TestRunner] ❌ SOME TESTS FAILED - Fix before proceeding" | tee -a "$OUT_FILE"
    exit 1
fi
