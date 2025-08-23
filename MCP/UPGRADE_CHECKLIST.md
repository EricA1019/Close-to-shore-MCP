# Upgrade Checklist — Broken Divinity Demo (MCP + Logging + Tooling)

This checklist tracks the full upgrade discussed: context bundling, dual-channel logging, improved test runner, tasks, and initial MCP tools. We'll check off items as they’re completed.

## Hop 1 — Agent Context Bundler
- [x] Create `.mcp_context/` output folder and add to `.gitignore`
- [x] Add bundler script `MCP/TOOLS/context_bundler.py` that emits `.mcp_context/context_bundle.md`
- [x] Bundle sources (include if present):
  - [x] `AGENT_PROMPT.md`
  - [x] `MCP/CLOSE_TO_SHORE.md`
  - [x] `MCP/TEST_POLICY.md`
  - [x] `MCP/GODOT_WORKFLOW.md`
  - [x] `MCP/PLUGINS.md`
  - [x] `README.md`
- [x] Add VS Code task: "MCP: Build Context Bundle"
- [x] Make test tasks depend on bundler (so the agent always has the latest context)

## Hop 2 — Dual-Channel Logging (Godot)
- [x] Extend `res://scripts/autoload/log_bus.gd` to support:
  - [x] Log levels (DEBUG, INFO, WARN, ERROR)
  - [x] Minimal console output (default INFO+)
  - [x] Verbose file sink at `user://logs/run-<RUN_ID>.log` (default DEBUG+)
  - [x] RUN_ID from env (`RUN_ID`) or auto timestamp
  - [x] Safe directory creation for `user://logs/`
  - [x] Backward-compatible signal: `signal message(msg: String)`
- [x] Add helpers: `debug/info/warn/error` and `set_level(s)/set_run_id(id)`
- [x] Integration test to verify log file creation and content
- [x] Add `logs/` (workspace) and `.mcp_context/` to `.gitignore`

## Hop 3 — Test Runner Wrapper
- [x] Enhance `MCP/TOOLS/test_runner.sh` to:
  - [x] Create a RUN_ID and export it for Godot
  - [x] Create `logs/` in repo and tee test output to `logs/run-<RUN_ID>-testrunner.out`
  - [x] Run GUT (all/integration) against `godot_project`
- [x] Add VS Code tasks:
  - [x] "Test: All (Runner)" depends on bundler
  - [x] "Test: Integration (Runner)" depends on bundler

## Hop 4 — Initial MCP Tools (stubs ok)
- [x] `MCP/GODOT_TOOLS/log_summary.py`: Summarize latest run log(s) from `user://logs` and workspace `logs/`
- [x] `MCP/GODOT_TOOLS/scene_lint.py`: Basic scene index validation using existing `scene_indexer.py`
- [x] `MCP/GODOT_TOOLS/release_helper.py`: Tag + changelog helper (stub CLI)
- [x] VS Code tasks to run the above

## Docs & Hygiene
- [x] Update `MCP/CLOSE_TO_SHORE.md` to mention the bundler and RUN_ID logging
- [x] Update `README.md` with new tasks and how to read logs
- [x] Update `CHANGELOG.md` with this upgrade
- [x] Commit + tag after tests are green

#EOF
