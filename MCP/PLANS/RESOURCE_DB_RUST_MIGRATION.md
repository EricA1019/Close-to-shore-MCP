# Resource Database + Rust Integration Plan (Phased)

This plan integrates the Resource Database with our Rust GDExtension and CLI/MCP tooling, adds agent-friendly DB operations, and cleans up legacy/deprecated code. It keeps gameplay/UI in GDScript while shifting heavy indexing/search/export and validation to Rust. Cross-references below point to concrete files to change or verify.

Decision: Use a single global index with multiple collections (items, abilities, buffs, etc.). Support multiple physical roots but aggregate into one runtime index. Use namespaced IDs (collection.key). Validation and tools operate on the global index.

---

## Folder organization and hygiene

- Rust (native extension and CLI)
  - `rust/gdext/src/resource_db/`
    - `mod.rs` (pub module)
    - `bridge.rs` (Godot-facing ResourceDbBridge class)
    - `search.rs` (tokenize/match/score helpers)
    - `types.rs` (Entry, Issue, Stats)
  - `rust/gdext/src/lib.rs` (register new classes)
  - `rust/cts/src/commands/db.rs` (new CLI db subcommands)
  - `rust/cts-core/` (shared helpers if needed)
- Godot project
  - `godot_project/native/gdext.gdextension` (already configured)
  - `godot_project/scripts/tools/db_runner.gd` (headless entry to call bridge)
  - Tests: `godot_project/tests/integration/test_resource_db_*.gd`
  - Optional fixtures: `godot_project/tests/fixtures/resource_db/`
- Docs & plans
  - This file: `MCP/PLANS/RESOURCE_DB_RUST_MIGRATION.md`
  - User docs: `godot_project/docs/RESOURCE_DB.md` (new)
- VS Code tasks and CI
  - `.vscode/tasks.json` (add CTS DB tasks)
  - `.github/workflows/cts-ci.yml` (add db build/test/validate)

Hygiene and consolidation:
- Prefer the canonical ASCII plugin at `godot_project/addons/ascii_grid/`. Review duplicated vendor folder `godot_project/addons/Godot-4-ASCII-Grid/` and plan removal or aliasing after tests pass.
- Keep `addons/resource_databases/` editor plugin intact (authoring). Add a runtime bridge; don’t fork editor UI logic.
- Keep GUT plugin as-is.
- Phase out legacy Python MCP tools as we replace them with `cts` commands (see Phase 4).

---

## Phase 0 — Inventory and baseline (no functional changes)

Goals
- Confirm current DB plugin structure and where content lives.
- Establish baseline green: build, tests, headless runs, CI.

Actions
- Inventory user Python tools (MCP) that overlap with new CLI:
  - `MCP/GODOT_TOOLS/*.py` and `MCP/TOOLS/*.py` (see workspace listing)
- Confirm GDExt config:
  - `godot_project/native/gdext.gdextension` (entry_symbol `gdext_rust_init`, compatibility `4.2`)
- Note duplicated ASCII plugin directories for later cleanup:
  - `addons/ascii_grid/` and `addons/Godot-4-ASCII-Grid/addons/ascii_grid/`

Deliverables
- This plan committed.
- Tracking issues created for each phase.

---

## Phase 1 — ResourceDbBridge scaffold (compile-time + headless smoke)

Goals
- Add a minimal Rust bridge class, callable in headless, that scans DB roots and returns basic stats.

Changes
- Rust GDExt (new):
  - `rust/gdext/src/resource_db/mod.rs`
  - `rust/gdext/src/resource_db/types.rs` (Entry {collection, key, title, tags, path, meta}, Issue, Stats)
  - `rust/gdext/src/resource_db/bridge.rs` (class ResourceDbBridge)
  - Register in `rust/gdext/src/lib.rs`
- Godot runner (new):
  - `godot_project/scripts/tools/db_runner.gd` (exposes build_index + print JSON stats to stdout)
- Tests (new):
  - `godot_project/tests/integration/test_resource_db_loads.gd` (build_index, assert ok, stats counts >= 0)

Bridge API (initial)
- build_index(root_dirs: PackedStringArray = ["res://data", "res://addons/resource_databases"]) -> int  // returns entry count
- stats() -> Dictionary { collections: String[], total_entries: int, updated_at: int }
- list_collections() -> PackedStringArray

Success criteria
- GDExt builds, loads in headless.
- Test passes in CI with zero orphans.

Status (2025-08-26)
- ResourceDbBridge is registered and callable in headless. Built `libgdext.so` is loading.
- `db_runner.gd` implemented and updated to parse args after `--`; supports `--roots=…`.
- VS Code: added task "DB: Build Index (headless)" to invoke the runner with configurable roots.
- Integration test `test_resource_db_loads.gd` passes; teardown fixed for RefCounted (no manual `free()`).

---

## Phase 2 — Search, get, and JSON snapshot export

Goals
- Provide agent-usable queries and a stable JSON snapshot.

Changes
- Rust GDExt (extend):
  - `search.rs` (tokenize by whitespace; case-insensitive contains; AND across tokens; scoring reserved)
  - `bridge.rs` methods (Godot-visible):
    - get(id: String) -> Dictionary | null
      - id format: `collection.key`; returns Entry or null
    - search(query: String, collection: String = "", limit: int = 50) -> Array[Dictionary]
      - match against `title`, `key`, and `tags`; case-insensitive; token AND
      - restrict by `collection` when provided; cap to `limit`
      - stable order: by `collection`, then `key`
    - save_index(path: String = "user://resource_db_index.json") -> bool
      - write JSON snapshot; false on IO error
    - load_index(path: String = "user://resource_db_index.json") -> bool
      - load snapshot; false on missing/invalid
  - Internal: keep Vec<Entry> and a HashMap<String, Entry> for O(1) get

- Godot runner support (`db_runner.gd` subcommands after `--`):
  - `list` → prints `{ "collections": String[] }`
  - `get --id=collection.key` → prints `{ "entry": Entry | null }`
  - `search --q=term [--collection=name] [--limit=N]` → prints `{ "results": Entry[] }`
  - `export [--out=user://resource_db_index.json]` → builds+saves snapshot; prints `{ "ok": bool, "out": String }`
  - Existing `build_index [--roots=…]` remains; all modes emit one-line JSON (NDJSON-friendly)

- Tests (new):
  - Fixtures under `godot_project/tests/fixtures/resource_db/` with 2–3 tiny collections (items, abilities) for deterministic assertions
  - `test_resource_db_get_and_search.gd`:
    - build over fixtures dir; `get` returns exact match and null on miss
    - `search` validates tokenization, case-insensitive matching, collection filtering, and limit
  - `test_resource_db_export_snapshot.gd`:
    - `save_index` writes `user://resource_db_index.json`
    - `load_index` reloads and serves `get`/`search` without rebuild

Success criteria
- All new tests pass headless; deterministic results
- JSON snapshot created at and loadable from `user://resource_db_index.json`
- Runner subcommands emit single-line JSON objects suitable for CLI piping

Output contracts (Phase 2)
- list → `{ "collections": ["items", "abilities", …] }`
- get → `{ "entry": Entry | null }`
- search → `{ "results": Entry[] }`
- export → `{ "ok": true, "out": "user://resource_db_index.json" }`
- build_index → `{ "ok": true, "count": number, "collections": String[] }`

Edge cases
- Missing/empty snapshot path: return false; do not panic
- Unknown collection filter: return empty results
- Large results: respect `limit` (default 50)
- Unicode: use lowercase/casefold where applicable for comparisons

---

### Optional step — Phase 2 developer ergonomics

Purpose
- Make day-to-day DB workflows fast and discoverable while Phase 2 soaks.

Additions
- VS Code tasks (`.vscode/tasks.json`):
  - "Test: GUT (Resource DB)" — run only DB integration tests for quick iteration.
  - "DB: Build Index (headless)" — headless `db_runner.gd -- build_index --roots=…` with prompt for roots.
  - (Optional) "DB: Search (prompt)" — headless `db_runner.gd -- search --q=… [--collection=…] [--limit=N]` and print JSON.
  - (Optional) "DB: Export Snapshot" — headless `db_runner.gd -- export [--out=user://resource_db_index.json]`.
- Runner smoke examples (for docs):
  - `godot4 --headless --path godot_project -s res://scripts/tools/db_runner.gd -- list`
  - `… -- search --q="screw" --collection=items --limit=10`
  - `… -- get --id=items.screwdriver`
  - `… -- export --out=user://resource_db_index.json`

Status (2025-08-26)
- Added tasks: "Test: GUT (Resource DB)", "DB: Build Index (headless)".
- Runner subcommands are live and emit single-line JSON; fixtures-based tests pass.

---

## Phase 3 — Validation rules and CI gate

Goals
- Detect broken cross-references, duplicates, and report in CI.

Changes
- Rust GDExt (extend):
  - `bridge.rs` method: validate() -> Dictionary
    - Returns `{ "issues": Issue[], "summary": { "errors": int, "warnings": int, "total": int } }`
  - Validation rules (initial set):
    - DB001 Duplicate ID
      - level: error; when multiple entries resolve to the same id `collection.key`.
      - message: "Duplicate id: <id>"
    - DB002 Missing Reference
      - level: error; when an entry declares a reference to an id that doesn’t exist.
      - message: "Missing reference <ref_id> from <id>"
    - DB003 Unknown Collection
      - level: warning; collection name not recognized by configuration (if we lock collections) or badly formed.
      - message: "Unknown collection: <collection>"
    - DB004 Invalid Schema
      - level: error; required fields missing or badly typed (title, key, collection).
      - message: "Invalid entry schema for <id>: <detail>"
    - DB005 Cyclic Reference
      - level: warning (configurable to error in strict); simple cycle detection across refs.
      - message: "Cyclic reference detected: <id1> -> … -> <id1>"
  - Issue shape (Dictionary):
    - `level`: "error" | "warning"
    - `code`: String (e.g., "DB001")
    - `message`: String
    - `id`: String (the entry’s id if applicable)
    - `path`: String (resource path, if applicable)
    - `ref_id`: String (for reference errors, optional)
    - `data`: Dictionary (extra fields for tooling, optional)

- Godot runner (`db_runner.gd`):
  - Add subcommand `validate` (after `--`):
    - Behavior: builds index (from `--roots=` if provided), runs `validate()`, prints one-line JSON:
      `{ "ok": boolean, "summary": {errors, warnings, total}, "issues": Issue[] }`
    - `ok` is true when `errors == 0`.

- CLI (new): `rust/cts/src/commands/db.rs`
  - Implemented now:
    - `cts db validate [--strict] [--roots res://dir1,res://dir2] [--out validate.json]`
      - Invokes Godot headless with `db_runner.gd validate` and parses the runner's one-line JSON.
      - Exit 0 if no errors (and warnings-only when not strict); exit 1 when errors (and any warnings when `--strict`).
  - Planned follow-ups (Phase 4):
    - `cts db index [--out path] [--roots …]`
    - `cts db list`
    - `cts db search --query … [--collection …] [--limit N]`
    - `cts db export [--out …]`

- Tests:
  - Fixtures: `godot_project/tests/fixtures/resource_db_invalid/`
    - Duplicate id case (two entries with same `collection.key`).
    - Missing ref case (entry with `refs: ["items.missing"]`).
    - Unknown collection (e.g., `weirdcollection.foo`).
    - Invalid schema (missing `title` or `key`).
    - Small 2-node cycle case: A -> B, B -> A.
  - `test_resource_db_validate.gd`:
    - Builds index from the invalid fixtures; calls `validate`; asserts counts and specific codes present.
    - Asserts that summary totals match number of synthetic invalids.

- CI workflow update:
  - In `.github/workflows/cts-ci.yml` (new/updated job): after gdext build and GUT tests, run:
  - `cts db validate --project-root . --roots res://data,res://addons/resource_databases --out logs/db_validate.json --strict`
  - Upload artifacts:
    - `logs/db_validate.json`
    - `godot_project/user/resource_db_index.json` (snapshot) if produced.

Output contracts (Phase 3)
- validate (runner) → `{ ok: bool, summary: {errors: int, warnings: int, total: int}, issues: Issue[] }`
- Issue (runner/CLI) → see Issue shape above; stable `code` values as listed.

Acceptance criteria
- Local and CI validation report matches known-invalid fixtures (codes and counts stable).
- CI gate fails when errors exist (and when warnings exist in `--strict` mode).
- No flakes: headless validate completes under normal CI time budgets.

Implementation checklist
- [ ] GDExt: implement `validate()` with the five rules above and return the structured summary.
- [ ] Runner: add `validate` subcommand and wire JSON output.
- [ ] CLI: add `db validate` with `--strict`, `--dirs`, `--out`; map exit codes.
- [ ] Tests: add invalid fixtures and `test_resource_db_validate.gd`.
- [ ] CI: add validation step and artifact uploads.
- [ ] Docs: update `RESOURCE_DB.md` with validation rules and examples.

Timeline (target)
- Day 1: GDExt validate() + runner subcommand + fixtures.
- Day 2: CLI command + tests + CI gate + docs refresh.

Status (2025-08-26)
- Completed locally (docs, code, tasks, tests):
  - GDExt: `validate()` implemented with DB001–DB005 and structured summary.
  - Runner: `validate` subcommand added; prints single-line JSON; accepts subcommands with or without `--` separator.
  - CLI: `cts db validate` implemented with `--strict`, `--roots`, `--out`; parses JSON and forwards exit codes correctly.
  - Tests: invalid fixtures + `test_resource_db_validate.gd` pass headless (codes present, counts correct).
  - VS Code: tasks added — "DB: Validate", "DB: Validate (strict)", and CTS equivalents.
- Pending: CI wiring. Add a step to run `cts db validate --strict` against real project roots and upload `logs/db_validate.json`.

Notes
- Godot may omit the `--` separator in some environments; the runner now detects subcommands directly (e.g., `… -s db_runner.gd validate`).

---

## Phase 4 — CI gate + CLI rounding + hygiene

Goals
- Finalize CI enforcement, round out CTS DB commands, and remove legacy overlaps while keeping editor UX intact.

Scope
- CI gate:
  - Add a GitHub Actions job (or extend existing) to run `cts db validate --strict` against `res://data,res://addons/resource_databases` on every PR.
  - Store report at `logs/db_validate.json` and upload as artifact.
  - Fail the job on any errors (and warnings, since `--strict`).
- CLI rounding (cts):
  - Implement `cts db list`, `cts db search`, `cts db export`, `cts db index` by shelling to the runner (reuse current patterns).
  - Add `--json` output and `--project-root` consistency across subcommands.
  - Optional: `--engine` to choose a managed Godot binary in `.tools/godot/bin/`.
- Hygiene (deprecations and plugin cleanup):
  - Remove or deprecate legacy Python tools superseded by CTS.
  - Consolidate ASCII plugin duplication once tests are green.

Deliverables
- Workflow file (e.g., `.github/workflows/cts-ci.yml`) updated with a DB validation step.
- CTS subcommands implemented: list/search/export/index with tests or smoke checks.
- Deprecated files removed or marked and documented in CHANGELOG.

Acceptance criteria
- CI fails when `cts db validate --strict` reports any issues; `logs/db_validate.json` is uploaded.
- Running `cts db list/search/export/index` locally produces correct JSON and exit codes.
- No references to removed Python scripts remain; GUT + smoke tests remain green.

Tasks checklist
- [ ] Create/modify CI workflow with a "DB Validate" job.
- [ ] Implement CTS: `db list` and `db search` (JSON passthrough, basic flags).
- [ ] Implement CTS: `db export` and `db index` (snapshot write and count output).
- [ ] Add VS Code tasks for the new CTS DB commands (optional).
- [ ] Deprecate/remove superseded Python tools (below) after CI is green.
- [ ] Remove ASCII plugin duplicate after usage audit and passing tests.

Targets for review/removal (post-adoption of CTS DB):
- Legacy Python tools superseded by `cts`:
  - `MCP/GODOT_TOOLS/scene_indexer.py` (superseded by `cts scene index` if applicable)
  - `MCP/GODOT_TOOLS/doc_search.py` (now `cts docs search`)
  - `MCP/TOOLS/godot_tool_suite.py` (umbrella script; confirm no unique features)
  - `MCP/TOOLS/godot_test_runner.py` (we run GUT directly via tasks/CI)
  - Keep: `engine_manager.py` (until Rust equivalent exists), `plugin_manager.py`, `doc_sync.py` equivalents if still used.
- ASCII plugin duplication:
  - Prefer `godot_project/addons/ascii_grid/`.
  - Plan deletion of `godot_project/addons/Godot-4-ASCII-Grid/` after confirming no references remain (search + tests pass).

Process
- Mark files as deprecated in docs and PRs.
- Remove only after a full green run on CI and local smoke.

Success criteria
- No broken references; smaller, cleaner repo; reduced task surface.

---

## Phase 5 — Performance and caching

Goals
- Improve big DB load/search performance and incremental dev loops.

Changes
- Rust GDExt:
  - Batch resource loads; avoid keeping heavy Godot objects in memory (store POD only).
  - Add `render_into_images` style reuse for any image/textures if later used by UI.
  - Optional persisted cache: `user://resource_db_cache.bin` for faster re-index when unchanged (hash-based).
- CLI:
  - Skip re-index if cache valid; `--force` to rebuild.

Success criteria
- Measurable speedups on CI and local runs (log timings in `cts db index`).

---

## Phase 6 — Developer experience and docs

Goals
- Make DB operations easy for humans and the agent.

Changes
- VS Code tasks (`.vscode/tasks.json`):
  - "CTS: DB Index"
  - "CTS: DB Validate (strict)"
  - "CTS: DB Search (prompt)"
  - "Run GUT: DB"
- Docs (`godot_project/docs/RESOURCE_DB.md`):
  - Data model (Entry/Issue), naming (collection.key), reference patterns, authoring tips.
  - How to run: tasks and CLI examples.
- MCP Server (`MCP/TOOLS/mcp_server.py`):
  - Add endpoints: db.collections, db.search, db.get, db.export, db.validate, db.stats (shell out to `cts`).

Success criteria
- One-pagers for devs; agent endpoints documented and discoverable.

---

## Cross-reference: files to add or modify

Add (new)
- `rust/gdext/src/resource_db/{mod.rs, types.rs, bridge.rs, search.rs}`
- `rust/cts/src/commands/db.rs`
- `godot_project/scripts/tools/db_runner.gd`
- `godot_project/tests/integration/test_resource_db_loads.gd`
- `godot_project/tests/integration/test_resource_db_get_and_search.gd`
- `godot_project/tests/integration/test_resource_db_validate.gd`
- `godot_project/tests/fixtures/resource_db/` (small fixtures)
- `godot_project/docs/RESOURCE_DB.md`

Modify
- `rust/gdext/src/lib.rs` (register ResourceDbBridge)
- `rust/cts/src/commands/mod.rs` (wire db)
- `.github/workflows/cts-ci.yml` (add DB jobs)
- `.vscode/tasks.json` (new tasks)
- `MCP/TOOLS/mcp_server.py` (add endpoints)

Review/Remove (Phase 4)
- `MCP/GODOT_TOOLS/scene_indexer.py` (if fully covered by cts scene/db)
- `MCP/GODOT_TOOLS/doc_search.py`
- `MCP/TOOLS/godot_tool_suite.py`
- `MCP/TOOLS/godot_test_runner.py`
- `godot_project/addons/Godot-4-ASCII-Grid/` (after references removed)

---

## Data contracts

Entry (Dictionary)
- collection: String
- key: String
- title: String
- tags: PackedStringArray
- path: String (res://…)
- meta: Dictionary (lightweight, safe fields only)

Issue (Dictionary)
- level: "error" | "warning"
- code: String
- message: String
- path: String (resource path)
- ref_id: String (optional)

Stats (Dictionary)
- total_entries: int
- collections: PackedStringArray
- updated_at: int (unix seconds)

---

## Risks and rollback

- Headless resource load issues: Keep minimal Godot APIs; log paths and skip binary-only resources.
- Schema drift: Validation rules versioned, warnings first; strict in CI after soak.
- Plugin duplication: Stage removal behind a flag/PR; revert is trivial.
- Rollback: Keep GDScript fallback shims; disable GDExt via ProjectSettings or environment.

---

## Open questions

- Exact DB resource formats in use (tres/tres+json/custom)? Confirm fields for title/tags/meta.
- Cross-reference fields: do we standardize on `refs: String[]` or typed fields per collection?
- Should we add a DB cache persisted across CI jobs for faster indexing?

---

## Success criteria summary

- Headless build + DB tests green on CI.
- `cts db validate --strict` gate in CI.
- Stable JSON snapshot for agent; MCP endpoints provide list/search/get/export/validate.
- Deprecated tools removed post-adoption; single canonical ASCII plugin.
