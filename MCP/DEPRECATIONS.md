# Deprecated Tools and Folders (Phase 4)

This document tracks legacy scripts and folders superseded by CTS and the Rust Resource DB.

Status legend: Planned → Marked → Removed

## Python tools removed or replaced

- MCP/GODOT_TOOLS/scene_indexer.py — superseded by `cts scene index` (Pending removal; references under audit)
- MCP/GODOT_TOOLS/doc_search.py — superseded by `cts docs search` (Pending removal)
- MCP/TOOLS/godot_tool_suite.py — replaced by direct scripts/tasks (Pending removal)
- MCP/TOOLS/godot_test_runner.py — Removed; use VS Code tasks or `MCP/TOOLS/test_runner.sh`

Keep until Rust parity:
- MCP/GODOT_TOOLS/engine_manager.py — keep until `cts engine` fully replaces workflows.
- MCP/GODOT_TOOLS/plugin_manager.py — review after `cts plugin` is implemented.
- MCP/GODOT_TOOLS/doc_sync.py — review after `cts docs` covers syncing.

## Godot addons cleanup

- Prefer `godot_project/addons/ascii_grid/`.
- Candidate for removal: `godot_project/addons/Godot-4-ASCII-Grid/` — Temporarily disabled via `.gdignore`; remove in a future PR after a week green.

## Process

- Mark items as Deprecated in PR descriptions and CHANGELOG.
- Remove only after CI stays green for one week and no references found by code search.

