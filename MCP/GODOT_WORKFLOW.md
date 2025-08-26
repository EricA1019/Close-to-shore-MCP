# Godot MCP Workflow

This document describes the workflow and best practices for using the MCP template with Godot projects.

- Use GUT for testing.
- Keep all plugins in `addons/`.
- Document all scenes and scripts in `docs/`.
- Follow MCP protocol for changes and documentation.

## MCP Context & Tasks

- Run the VS Code task “CTS: Build Context Bundle” before tests. It generates `.mcp_context/context_bundle.md` from key docs so the agent always has current prompts/protocols.
- Use runner tasks for tests:
	- “Test: All (Runner)” — sets a RUN_ID, runs GUT headless, and tees to `logs/run-<RUN_ID>-testrunner.out`.
	- “Test: Integration (Runner)” — same, limited to `tests/integration`.
- Direct Godot GUT tasks exist too (All/UI/Integration) and are configured to depend on the bundler.

API hygiene:
- Run “CTS: Lint API Guard” to scan for external access of private members (names prefixed with `_`). Fix violations by adding proper public getters or signals.
- Run “CTS: Lint GDScript” for quick checks (TODO markers, debug prints, sleep without await). Triage results and suppress noise with follow-up rules as needed.
- Define and follow the Event Contract in `project/docs/EVENT_CONTRACT.md` (signals + write APIs). Prefer emitting changes via signals over direct reads.

## Engine Version Management (Local Copy)

To keep development stable and reproducible, this project maintains a local copy of the preferred Godot editor/runner in `.tools/godot/`.

- Preferred version: managed via CTS engine commands (e.g., 4.5 beta 6).
- Ensure local binary exists:
	- VS Code Task: "MCP: Ensure Local Godot 4.5b6" or use CTS: `cts engine ensure --version 4.5-beta6`
	- Resulting symlinks: `.tools/godot/bin/godot` and `.tools/godot/bin/godot-<version>`
- All tasks use the managed binary first, falling back to `godot4` if not present.

### Running Tests Headless

From `godot_project/`:

```
../.tools/godot/bin/godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gexit
```

Or from repo root using the runner wrapper:

```
bash MCP/TOOLS/test_runner.sh all
```

Artifacts:
- Repo log: `logs/run-<RUN_ID>-testrunner.out`
- Godot user log: `user://logs/run-<RUN_ID>.log`

### Updating the Local Engine Copy

When upgrading to a new beta or stable:
1. Add a new folder under `.tools/godot/<version-tag>/` and download the zip.
2. Update symlink targets in `.tools/godot/bin/`.
3. Update `project.godot` `config/features` if necessary.
4. Run smoke tests to validate.

## Logging & RUN_ID

- The project’s `LogBus` writes INFO+ to console and DEBUG+ to `user://logs/run-<RUN_ID>.log`.
- The RUN_ID is provided by the test runner; you can override by exporting `RUN_ID` before launching Godot.
- Use the task “MCP: Log Summary” for a quick tail/summary of the latest run.

### Tail logs (Linux)

Runner log (repo):

```bash
tail -n 100 -f "$(ls -t logs/run-*-testrunner.out | head -n1)"
```

Godot runtime log (user://):

```bash
tail -n 100 -f "$(ls -t ~/.local/share/godot/app_userdata/*/logs/run-*.log | head -n1)"
```

If you know the RUN_ID:

```bash
tail -n 100 -f "logs/run-<RUN_ID>-testrunner.out"
tail -n 100 -f "~/.local/share/godot/app_userdata/*/logs/run-<RUN_ID>.log"
```

