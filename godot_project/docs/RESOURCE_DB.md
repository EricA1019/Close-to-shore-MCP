# Resource Database (Runtime + Tools)

This guide explains the Resource DB used by the game and how to interact with it from headless tools, the GDExtension bridge, and the Rust CLI (cts). It also documents the validation rules introduced in Phase 3.

## Overview

- Single global index across multiple collections (items, abilities, etc.) and roots.
- Each entry is identified by a namespaced id: `collection.key`.
- Entries are lightweight dictionaries (POD data) — safe to serialize and pass to tools.

## Data model

Entry (Dictionary)
- collection: String
- key: String
- title: String
- tags: PackedStringArray
- path: String (res://...)
- meta: Dictionary (optional, safe fields only)

Issue (Dictionary)
- level: "error" | "warning"
- code: String (e.g., "DB001")
- message: String
- id: String (the entry’s id if applicable)
- path: String (resource path, if applicable)
- ref_id: String (for reference errors, optional)
- data: Dictionary (extra fields for tooling, optional)

Stats (Dictionary)
- total_entries: int
- collections: PackedStringArray
- updated_at: int (unix seconds)

## Headless runner

Script: `res://scripts/tools/db_runner.gd`

Subcommands (after `--`; or directly, Godot sometimes omits `--`):
- build_index [--roots=res://data,res://addons/resource_databases]
  - Output: `{ "ok": bool, "count": number, "collections": String[] }`
- list
  - Output: `{ "collections": String[] }`
- get --id=collection.key
  - Output: `{ "entry": Entry | null }`
- search --q=term [--collection=name] [--limit=N]
  - Output: `{ "results": Entry[] }`
- export [--out=user://resource_db_index.json]
  - Output: `{ "ok": bool, "out": String }`
- validate (Phase 3)
  - Output: `{ "ok": bool, "summary": {errors, warnings, total}, "issues": Issue[] }`

Examples
- `godot4 --headless --path godot_project -s res://scripts/tools/db_runner.gd list`
- `godot4 --headless --path godot_project -s res://scripts/tools/db_runner.gd -- search --q="screw" --collection=items --limit=10`
- `godot4 --headless --path godot_project -s res://scripts/tools/db_runner.gd -- get --id=items.screwdriver`
- `godot4 --headless --path godot_project -s res://scripts/tools/db_runner.gd -- export --out=user://resource_db_index.json`
- `godot4 --headless --path godot_project -s res://scripts/tools/db_runner.gd validate`

## Validation rules (Phase 3)

- DB001 Duplicate ID
  - level: error
  - Trigger: multiple entries resolve to the same id `collection.key`.
- DB002 Missing Reference
  - level: error
  - Trigger: an entry declares a reference to an id that doesn’t exist.
- DB003 Unknown Collection
  - level: warning
  - Trigger: collection name not recognized by configuration (if enforced) or malformed.
- DB004 Invalid Schema
  - level: error
  - Trigger: missing required fields (title/key/collection) or invalid types.
- DB005 Cyclic Reference
  - level: warning (configurable to error with `--strict`)
  - Trigger: cycles detected across `refs`.

The runner’s `validate` prints a one-line JSON object. `ok` is true when `errors == 0`.

## Rust CLI (cts)

The CLI mirrors runner capabilities and sets exit codes for CI usage.

Commands
- `cts db list [--roots res://dir1,res://dir2]`
- `cts db search --query term [--collection name] [--limit N] [--roots res://dir1,res://dir2]`
- `cts db export [--out user://resource_db_index.json] [--roots res://dir1,res://dir2]`
- `cts db index [--out user://resource_db_index.json] [--roots res://dir1,res://dir2]`
- `cts db validate [--strict] [--roots res://dir1,res://dir2] [--out validate.json]`

Exit codes
- 0: success (no errors; and warnings-only when not strict)
- 1: validation errors (or warnings present in strict mode)
- 2+: runtime/IO errors

## VS Code tasks

Available now
- Test: GUT (Resource DB) — runs only DB tests for quick iteration
- DB: Build Index (headless) — builds index with configurable roots
- CTS: DB List / Search / Export / Index / Validate — wrappers around the CLI for common flows

## Troubleshooting

- ContentDB warnings in headless runs: harmless unless assets are expected from ContentDB.
- Empty search results: ensure you are indexing the fixtures root or the project’s data roots.
- Snapshot load failures: verify `user://resource_db_index.json` exists and is valid JSON.

