# MCP — Minimal Change Process

MCP (Minimal Change Process) is a small, test-driven workflow for making low-risk changes ("hops") that keep the project runnable and testable at every step.

Why use MCP
- Keep the blast radius small: each hop should be focused and small.
- Ensure continuous test coverage: every hop is verified via headless GUT runs.
- Make rollbacks easy: create short-lived backup branches before risky edits.

MCP loop (recommended)
1. Start from a clean commit on `main` or create a short-lived branch (e.g. `wip/<short>-<ts>`).
2. Add a small, focused test that describes the desired behavior (failing test first).
3. Implement the minimal code change to make the test pass.
4. Run the headless integration tests locally and fix regressions.
5. Repeat until the feature/hop is complete.
6. Squash or tidy commits and merge the branch.

Local commands (examples)
```bash
# Full integration test run (headless)
${HOME}/Desktop/Godot_v4.5-beta5_linux.x86_64 --headless --path /path/to/repo \
  -s res://addons/gut/gut_cmdln.gd -gdir=res://scenes/tests/integration -ginclude_subdirs -gprefix=test_ -gexit

# Run a single test file
${HOME}/Desktop/Godot_v4.5-beta5_linux.x86_64 --headless --path /path/to/repo \
  -s res://addons/gut/gut_cmdln.gd -gdir=res://scenes/tests/integration -ginclude_subdirs -gprefix=test_ -gexit res://scenes/tests/integration/test_some_file.gd
```

Best practices
- Keep hops ~200 LOC or smaller.
- Prefer incremental edits and narrow unit/integration tests.
- If a hop breaks many tests, revert to the backup branch and split the hop.
- Use the VS Code tasks in the repo to run common GUT tasks.

Safety
- Create a backup branch before risky edits: `git branch wip/<short>-<ts>`.
- Use `git reset --hard HEAD` and `git clean -fd` only after you have a backup branch.

