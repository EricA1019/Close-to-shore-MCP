# Deprecated Tools and Folders (Phase 4)

This document tracks legacy scripts and folders superseded by CTS and the Rust Resource DB.

Status legend: Planned → Marked → Removed

## Python tools slated for removal

- MCP/GODOT_TOOLS/scene_indexer.py — superseded by `cts scene index` (Planned)
- MCP/GODOT_TOOLS/doc_search.py — superseded by `cts docs search` (Planned)
- MCP/TOOLS/godot_tool_suite.py — umbrella script; verify unique features (Planned)
- MCP/TOOLS/godot_test_runner.py — replaced by `cts test` and VS Code tasks (Planned)

Keep until Rust parity:
- MCP/GODOT_TOOLS/engine_manager.py — keep until `cts engine` fully replaces workflows.
- MCP/GODOT_TOOLS/plugin_manager.py — review after `cts plugin` is implemented.
- MCP/GODOT_TOOLS/doc_sync.py — review after `cts docs` covers syncing.

## Godot addons cleanup

- Prefer `godot_project/addons/ascii_grid/`.
- Candidate for removal: `godot_project/addons/Godot-4-ASCII-Grid/` after reference audit and green tests (Planned).

## Process

- Mark items as Deprecated in PR descriptions and CHANGELOG.
- Remove only after CI stays green for one week and no references found by code search.

