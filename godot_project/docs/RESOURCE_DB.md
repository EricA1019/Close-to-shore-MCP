# Resource Database (Runtime + Tools)

This guide explains the Resource DB used by the game and how to interact with it from headless tools, the GDExtension bridge, and the Rust CLI (cts). It also documents the validation rules introduced in Phase 3. Canonical content is stored as Godot Resources (`.tres/.res`), not JSON.

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
- build_index [--roots=res://data,res://addons/resource_databases] [--no-cache|--use-cache] [--verify-hash=0.0..1.0]
  - Output: `{ "ok": bool, "count": number, "collections": String[], "cache": {hits,changed,deleted,verify_rate}, "timings": {discover_ms,hash_ms,parse_ms,total_ms} }`
- list
  - Output: `{ "collections": String[] }`
- get --id=collection.key
  - Output: `{ "entry": Entry | null }`
- search --q=term [--collection=name] [--limit=N]
  - Output: `{ "results": Entry[] }`
- export [--out=user://resource_db_index.json] [--no-cache|--use-cache] [--verify-hash=0.0..1.0]
  - Output: `{ "ok": bool, "out": String, "cache": {hits,changed,deleted,verify_rate}, "timings": {discover_ms,hash_ms,parse_ms,total_ms} }`
- validate (Phase 3)
  - Output: `{ "ok": bool, "summary": {errors, warnings, total}, "issues": Issue[], "timings": {discover_ms,hash_ms,parse_ms,total_ms} }`

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
- `cts db index [--out user://resource_db_index.json] [--roots res://dir1,res://dir2] [--no-cache] [--verify-hash 0.0..1.0]`
- `cts db validate [--strict] [--roots res://dir1,res://dir2] [--out validate.json] [--no-cache] [--verify-hash 0.0..1.0]`

Exit codes
- 0: success (no errors; and warnings-only when not strict)
- 1: validation errors (or warnings present in strict mode)
- 2+: runtime/IO errors

## VS Code tasks

Available now
- Test: GUT (Resource DB) — runs only DB tests for quick iteration
- DB: Build Index (headless) — builds index with configurable roots
- CTS: DB List / Search / Export / Index / Validate — wrappers around the CLI for common flows
  - Index task writes stats to `logs/db_index_stats.json` for quick inspection (cache and timings)

## Troubleshooting

- ContentDB warnings in headless runs: harmless unless assets are expected from ContentDB.
- Empty search results: ensure you are indexing the fixtures root or the project’s data roots.
- Snapshot load failures: verify `user://resource_db_index.json` exists and is valid JSON.

## Layouts collection example (Apartment)

- To drive the Interactive Apartment from the DB, seed an entry in the Resource DB index pointing to a layout resource:

  - Preferred: `res://data/layouts/apartment.tres` (resource that references a JSON grid or embeds grid data)
  - Transitional: `res://data/layouts/apartment.tres` (grid only) while POIs/entities use Resource IDs from DB

- Minimal grid fields (if JSON grid is used):
  - width: number (28)
  - height: number (16)
  - rows: string[height] of length width

InteractiveApartment will try `layouts.apartment` first and fall back to a built-in layout with a warning if missing.

### Hop 1 Checklist (Docs and Index Prep)

- Requirements
  - All canonical data lives in `.tres/.res` under `res://data/` (entities, items, abilities, statuses, tiles, layouts)
  - Index supports listing/searching/validation across collections
- Contracts
  - Runner: `build_index`, `list`, `get`, `search`, `export`, `validate` emit single-line JSON
  - CLI: `cts db list|search|index|export|validate` with exit codes and JSON passthrough
- Tests
  - `list` returns collections including `layouts`
  - `search --collection layouts --q apartment` returns at least one result
  - `validate --strict` fails on seeded bad refs; passes clean on fixtures
- DoD
  - Docs updated to Resource DB-first (no JSON as canonical store)
  - Indexing shows timings + cache stats; snapshot export works
  - Apartment scene loads from DB with safe fallback and warning


## MCP server endpoints (Phase 7)

The lightweight MCP stdlib HTTP server exposes endpoints that shell out to the `cts` CLI with a 30s timeout and return structured JSON.

Base: `MCP/TOOLS/mcp_server.py` (runs on http://localhost:5000 by default)

Endpoints
- GET /db/collections
  - Params: `roots` (optional; default `res://data,res://addons/resource_databases`)
  - Returns: `{ "collections": String[] }`
- GET /db/search
  - Params: `q` (required), `collection` (optional), `limit` (optional), `roots` (optional)
  - Returns: `{ "results": Entry[] }`
- POST /db/export
  - JSON body: `{ roots?: string, out?: string }`
  - Returns: `{ "ok": bool, "out": string, "cache": {...}, "timings": {...} }`
- POST /db/validate
  - JSON body: `{ roots?: string, strict?: boolean }`
  - Returns: 200 with `{ ok, summary, issues }` on success; 422 with `{ error, report }` on validation failure
- GET /db/index/stats
  - Params: `roots` (optional)
  - Returns: Stats JSON from the last index run, e.g., `{ cache: {...}, timings: {...}, count, collections }`

Examples (curl)
- `curl 'http://localhost:5000/db/collections'`
- `curl 'http://localhost:5000/db/search?q=apartment'`
- `curl -X POST 'http://localhost:5000/db/validate' -H 'Content-Type: application/json' -d '{"strict": true}'`

Note: The server prefers the locally built `rust/target/release/cts`; otherwise it falls back to `cts` in PATH.

