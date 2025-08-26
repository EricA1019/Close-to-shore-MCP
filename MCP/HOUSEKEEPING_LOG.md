Housekeeping changes (2025-08-26)

Removed legacy VS Code tasks and rewired managed tasks to CTS engine ensure.

Candidate Python tools to retire (superseded by CTS) — not deleted yet:
- MCP/TOOLS/context_bundler.py (CTS bundle exists)
- MCP/TOOLS/mcp_server.py (still referenced by task: Start MCP Flask Server)
- MCP/GODOT_TOOLS/project_sync.py (check usage)
- MCP/GODOT_TOOLS/export_helper.py (check usage)
- MCP/GODOT_TOOLS/gut_test_runner.py (CTS test now runs suites)
- MCP/GODOT_TOOLS/task_launcher.py (check usage)

Removed unused VS Code tasks:
- All 4.5b5 desktop tasks
- Old MCP engine tasks (ensure/link)
- Duplicated GUT integration variants
- Unused smoke variant (MainUI render)

Next review targets:
- Remove remaining 4.5b5 references in docs if any.
- Consolidate duplicate top-level READMEs if overlapping with `godot_project/docs`.
- Consider deprecating `Start MCP Flask Server` if not relied on.