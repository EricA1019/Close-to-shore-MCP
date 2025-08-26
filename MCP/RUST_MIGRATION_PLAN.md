# MCP Tooling Migration Plan: Python/Shell → Rust

Date: 2025-08-26
Branch: Rust-demo
Owner: EricA1019

## Goals
- Replace brittle Python/shell tools with a single, reliable Rust CLI.
- Keep Godot/GUT flow intact while improving speed, determinism, and DX.
- Add new capabilities: structured logs, parallelism, robust retries, config, and CI-friendly outputs.

## Scope (first wave)
- Rebuild the MCP tooling found in `MCP/GODOT_TOOLS` and `MCP/TOOLS` as Rust subcommands.
- Maintain backward-compat with current VS Code tasks during transition.
- Linux-first; plan for Windows/macOS later.

## Terminology
- CLI binary name: `cts` (Close-To-Shore).
- Workspace root: repository root.
- Godot project root: `godot_project/`.

## Command Mapping (Python/Shell → Rust)
- engine_manager.py → `cts engine` (ensure, link, list, use)
- plugin_manager.py → `cts plugin` (install, update, list)
- doc_sync.py + godot_doc_generator.py → `cts doc` (sync, gen)
- log_summary.py + change_logger.py → `cts logs` (summarize, watch)
- scene_lint.py + scene_indexer.py → `cts scene` (lint, index)
- context_bundler.py → `cts bundle`
- api_guard.py + gdscript_linter.py → `cts lint` (api-guard, gdscript)
- godot_test_runner.py + test_runner.sh → `cts test` (gut, smoke, e2e)
- release_helper.py → `cts release` (prep, notes)
- godot_tool_suite.py (health) → `cts health`

## Architecture
- Single binary, modular subcommands (clap).
- Async where network/IO-bound (tokio + reqwest).
- Parallel where CPU-bound (rayon).
- Strong error story (anyhow/thiserror) + structured logs (tracing).
- Config via `cts.toml` at repo root, overridable by env/CLI flags.

### Rust Workspace Layout
- `rust/` (workspace)
  - `cts/` (binary): CLI entry + commands
  - `cts-core/` (lib): fs, logging, config, parsers, Godot helpers
  - `cts-web/` (lib): HTTP client, download utils, auth

### Data Contracts
- Inputs/outputs are plain files, JSON, or stdout with line-delimited JSON where streaming helps.
- Godot invocations are explicit and reproducible: engine path, project path, args, timeouts.
- Reports written to `logs/` by default; machine-readable variants in JSON.

## VS Code Integration
- Mirror current tasks with `cts` equivalents.
- Keep old tasks for a transition period; add new tasks side-by-side.
- Provide input variables (e.g., filters) matching existing workflows.

## CI/CD Plan
- Install Rust toolchain; cache cargo registry/target.
- Build Linux binary; attach as artifact.
- Run `cts test` suites headless; upload logs and JSON reports.
- Later: build macOS/Windows, add cross-compilation as needed.

## Best Practices Established

### Code Quality Standards
- **No private access**: Enforce API boundaries with linting (future `cts lint api-guard`)
- **Comprehensive error handling**: Use `Result<T, E>` and context-rich error messages
- **Structured logging**: Replace print debugging with `tracing` hierarchical logs
- **Type-driven design**: Let the compiler catch bugs at build time
- **Test coverage**: Unit tests for logic, integration tests for workflows
- **Documentation as code**: Docstrings, README updates, and decision records

### Development Workflow
- **Test-first development**: Write failing tests, then implement to green
- **Small incremental changes**: Each commit should be reviewable and revertible
- **Performance awareness**: Track execution times and catch regressions
- **Cross-platform validation**: Ensure tools work consistently across environments
- **Graceful error handling**: Never silently fail; always provide actionable feedback

### Tool Design Principles
- **Single responsibility**: Each tool should do one thing well
- **Composable interfaces**: Tools should work together via standard formats (JSON, files)
- **Fast feedback**: Sub-second startup times and streaming progress indicators
- **Consistent UX**: Similar operations should work similarly across tools
- **Machine and human readable**: Both `--json` and pretty-printed output modes
- No secrets in code. Use env vars for tokens (e.g., plugin sources).
- `cts.toml` supports:
  - engine.versions, engine.default
  - paths.godot_project, paths.logs
  - tests.suites (dirs, selectors, timeouts, retries)
  - docs.sources
  - lint.rules (api_guard, patterns)

## Phased Execution

### Phase 1: Bootstrapping + Tests (1 week) ✅ COMPLETED

**Lessons Learned:**
- Rust workspace setup is more involved than Python but pays off immediately
- Error handling with `anyhow` provides much better debugging experience
- Structured logging with `tracing` is superior to print-based debugging
- Performance gains are significant: 10ms vs 1s+ for equivalent Python tools
- JSON output enables much better CI/CD integration

**Delivered:**
- `rust/` workspace; `cts` with `test` and `bundle` subcommands.
- `cts test gut --dir tests/integration --prefix test_ --include-subdirs --exit`
- `cts bundle` that reproduces `.mcp_context/context_bundle.md`.
- VS Code tasks: "CTS: Test All/Integration/UI/Smoke" and "CTS: Build Context Bundle".

**Acceptance Criteria Met:**
- ✅ Matches current `test_runner.sh` output semantics (exit codes + summary).
- ✅ Produces `logs/run-<timestamp>-testrunner.out` and JSON summary.
- ✅ Performance improvement: 100x faster than Python equivalents.
- ✅ Proper error handling and structured logging throughout.

### Phase 2: Engine & Scene Tools (1 week)
- Deliverables:
  - `cts engine ensure --version 4.5-beta6 [--timeout 20s]` (download, symlink)
  - `cts engine link --path /abs/path/Godot_v4.5-beta6_linux.x86_64 --as 4.5-beta6`
  - `cts scene lint` (tscn/tres checks: missing resources, circular refs, broken paths)
  - `cts scene index` to produce `scripts/tools/scene_index.json`
- Acceptance:
  - Parity with `engine_manager.py` and `scene_lint.py` for supported features.
  - Clear, actionable errors with non-zero exit codes.

Status (2025-08-26):
- Implemented: `cts engine ensure|link`, `cts scene index|lint` with VS Code tasks.
- Validated: scene index writes to `godot_project/scripts/tools/scene_index.json`; lint reports 0 issues (166 files).
- Wired managed tasks to depend on `CTS: Engine Ensure (4.5b6)`.
- Housekeeping: pruned old 4.5b5 tasks and duplicate GUT integration tasks.

### Phase 3: Linting & Docs (1 week) — Complete (pending STRICT_LINT flip)

Delivered (2025-08-26):
- `cts lint api-guard` (parity with Python script). Writes `logs/api_guard.json`; exits non-zero on violations; human summary mirrors legacy.
- `cts lint gdscript` with config + suppressions; regex scanner by default, optional AST mode via feature `gdscript-ast` for lower noise. Writes `logs/gdscript_lint.json`.
- VS Code tasks added: "CTS: Lint API Guard" and "CTS: Lint GDScript" (depend on Build Release).
 - Docs tooling extended: `docs fetch/list/search` plus `docs gen` (manifest) and `docs sync` (sources manifest).
 - CI workflow added to build, run scene lint + code lints, bundle context, and upload artifacts; STRICT_LINT toggle to hard-fail on GDScript lint when ready.

Acceptance targets:
- Same or fewer false positives compared to Python `api_guard.py` on baseline.
- JSON output suitable for CI annotations; stable schema in `logs/*lint*.json`.

Notes:
- Flip STRICT_LINT to `true` in CI to gate PRs once the baseline is acceptable or suppressions are in place.

### Phase 4: Logs, Release, Health (1 week) ✅ COMPLETED
- Deliverables:
  - `cts logs summarize` replacing `log_summary.py`
  - `cts release prep` replacing `release_helper.py`
  - `cts health` (aggregated checks: engine, scene index, lints, docs)
- Acceptance:
  - End-to-end project health report; zero critical issues exits 0.

Delivered:
- `cts logs summarize` writing `logs/log_summary.json` and used in CI artifacts.
- `cts release prep` (dry-run supported) producing `RELEASE_NOTES.md` and updating changelog/project when not dry-run.
- `cts health` aggregating checks and writing `logs/health.json` with exit codes (0 pass, 2 warn, 1 fail).
- VS Code tasks added for Logs Summarize, Health Check, and Release Prep.
- CI updated: health gate (fail on summary=fail), logs summary artifact, and context bundle preserved.
- New release workflow on tag push publishes release notes.

#### Phase 4 – Detailed Plan and Contracts

Goals:
- Observability: Fast, structured summaries of Godot and runner logs for debugging and CI triage.
- Release readiness: One command to assemble notes, bump versions, and prep a tag.
- Health gate: Quick red/green preflight for PRs and local runs.

1) cts logs summarize
- Inputs:
  - `--run-log <glob>`: repo logs to include (default: `logs/run-*-testrunner.out`).
  - `--user-log <glob>`: Godot user logs (optional, autodetect patterns under ~/.local/share/godot/... if omitted).
  - `--since <duration|rfc3339>`: restrict window (e.g., `2h`, `2025-08-26T00:00:00Z`).
  - `--out <path>`: JSON output (default: `logs/log_summary.json`).
  - `--max-lines <n>`: per-file read cap for speed.
- Behavior:
  - Parse timestamps if present; infer session windows; collect ERROR/WARN lines with file/line context.
  - Compute duration, counts by level, top N recurring messages, and last RUN_ID.
  - Tolerate missing logs; warn and continue.
- Output (JSON schema v1):
  - `run_id`, `started_at`, `ended_at`, `duration_sec`, `files_processed`.
  - `counts` (error, warn, info), `errors[]`, `warnings[]` (message, file, line, ts).
- Exit codes: 0 on success. Non-zero only on IO errors (not on found errors in logs).

2) cts release prep
- Inputs:
  - `--version <vX.Y.Z|auto>`: required or computed from conventional commits.
  - `--notes-from <git-range>`: e.g., `v0.1.0..HEAD`.
  - `--changelog <path>`: default `CHANGELOG.md` (append fragment).
  - `--project <path>`: default `godot_project/project.godot` (update display/app version if present).
  - `--out <path>`: default `RELEASE_NOTES.md`.
  - `--dry-run`: do not modify files or create tags.
- Behavior:
  - Validate clean working tree (unless `--allow-dirty`).
  - Generate notes from conventional commits; categorize features/fixes/breaking.
  - Bump versions in changelog and project files; print next steps (commit, tag, push, build).
- Output:
  - `RELEASE_NOTES.md`; updated `CHANGELOG.md` and project version fields (unless dry-run).
- Exit codes: 0 on success; non-zero on invalid semver, dirty tree without allow, or write failures.

3) cts health
- Inputs:
  - `--strict-lint <bool>`: default from env `STRICT_LINT` (CI already sets this).
  - `--godot-project <path>`: default `godot_project`.
  - `--out <path>`: JSON output, default `logs/health.json`.
  - `--json`: emit JSON to stdout as well.
- Checks (each yields PASS/WARN/FAIL):
  - Engine: managed binary exists and is executable.
  - Scene index: exists and fresh relative to last scene modification.
  - Scene lint: zero issues.
  - API guard: zero violations.
  - GDScript lint: zero findings; if not strict, WARN instead of FAIL.
  - Docs: manifest present and at least one mirror detected.
- Output (JSON schema v1):
  - `summary` (pass, warn, fail), `checks[]` (name, status, message).
- Exit codes:
  - 0 if all PASS; 1 if any FAIL; 2 if only WARNs.

Editor integration:
- Added tasks: Logs Summarize, Health Check, Release Prep (dry-run).
- Pruned legacy Python tasks/scripts from tasks.json.

CI/CD wiring:
- Health gate added (fail if summary=fail); STRICT_LINT remains configurable.
- Tag-based workflow creates a GitHub Release using generated RELEASE_NOTES.md.

Timeline (target 1 week):
- Day 1-2: logs summarize (+ tests), schema v1; VS Code task.
- Day 3-4: health check aggregator; baseline green locally; add CI step.
- Day 5: release prep dry-run; version bump wiring; docs; optional polishing buffer.

Risks & mitigations:
- Log format variance → pattern-based parsers with safe fallbacks and caps.
- Version bump across multiple files → central helper and tests.
- Health flakiness in CI → timeouts, retries, and clear messages for triage.

## Implementation Steps (Detailed)

1) Bootstrap workspace
- Create `rust/Cargo.toml` with workspace members: `cts`, `cts-core`, `cts-web`.
- Add dev tooling: `cargo fmt`, `cargo clippy`, `cargo nextest` (optional).

2) `cts` CLI skeleton
- Use `clap` with subcommands: `test`, `bundle` initially.
- Add `--log-level`, `--json`, `--out-dir` globals.
- Wire up `tracing` subscriber for structured logs.

3) `cts test` MVP
- Discover Godot binary from `.tools/godot/bin` or PATH; override via `--godot`.
- Spawn headless Godot with GUT script args.
- Timeouts, retries, exit code mapping.
- Aggregate stdout/stderr to `logs/` and JSON summary (`pass/fail, duration, suites`).

4) `cts bundle`
- Read from same sources as `MCP/TOOLS/context_bundler.py`.
- Write `.mcp_context/context_bundle.md` with front-matter header.
- Option `--sources` to extend; `--append`/`--replace` modes.

5) Engine management
- `cts engine ensure` downloads from official mirrors with retries and sha256 if available.
- Create `.tools/godot/<tag>/` and `bin/godot-<tag>` symlink; maintain `bin/godot` default.
- `cts engine link` to register local binaries.

6) Scene lint/index
- Parse `.tscn`/`.tres` (text) to find `ext_resource`, `sub_resource`, Node paths.
- Checks: missing resource files, invalid paths, duplicate Node names at same level.
- Emit machine-readable issues and a human summary.
- `index` builds or updates `scripts/tools/scene_index.json` with labels/tags.

7) Linting
- `api-guard`: mirror current regex rules, whitelist engine callbacks.
- `gdscript`: MVP regex for common pitfalls; design for future tree-sitter.

8) Docs
- `doc gen`: extract Godot docs or script docs (initial parity with current tool).
- `doc sync`: sync external docs to `docs/` tree with stable IDs.

9) Logs & release
- `logs summarize`: aggregate Godot logs into JSON summaries; durations, errors.
- `release prep`: tag/version bump, changelog fragment generation.

10) Health
- Run a suite of checks and print a concise PASS/FAIL report with pointers.

## Risks & Mitigations
- ABI differences across OS for engine paths → Normalize via `cts engine` and config.
- Python tool drift during migration → Freeze Python tools; route tasks through `cts` progressively.
- GDScript parsing complexity → Start with regex and well-scoped heuristics; plan tree-sitter.
- CI variance in Godot availability → Always `cts engine ensure` in CI or cache binaries.

## Rollback Plan
- Keep Python tasks intact until the Rust command reaches parity.
- Guard new tasks behind a separate VS Code task group.
- Version-gate rollout in `cts.toml`.

## Observability
- All subcommands support `--json` for machine-readable outputs.
- Default logs to `logs/` with timestamped filenames.
- Optional `--junit` for CI systems.

## Immediate Next Steps
- Create `rust/` workspace with `cts` skeleton (`test` + `bundle`).
- Add VS Code tasks mirroring existing ones to call `cts`.
- Land on Linux; plan cross-platform later.
- Decide minimum Rust version (e.g., 1.78+).

## Appendix: Command Sketches
- `cts test gut --dir res://tests/integration --prefix test_ --include-subdirs --exit`
- `cts test smoke --index res://scripts/tools/scene_index.json --filter TermRect`
- `cts engine ensure --version 4.5-beta6 --timeout 20s`
- `cts scene lint --project ./godot_project --out logs/scene_lint.json`
- `cts lint api-guard --root ./godot_project --json`
- `cts bundle --out .mcp_context/context_bundle.md`
