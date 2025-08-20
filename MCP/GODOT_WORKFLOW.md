# Godot MCP Workflow

This document describes the workflow and best practices for using the MCP template with Godot projects.

- Use GUT for testing.
- Keep all plugins in `addons/`.
- Document all scenes and scripts in `docs/`.
- Follow MCP protocol for changes and documentation.

## Engine Version Management (Local Copy)

To keep development stable and reproducible, this project maintains a local copy of the preferred Godot editor/runner in `.tools/godot/`.

- Preferred version: Godot 4.5 beta 5.
- Ensure local binary exists:
	- VS Code Task: "MCP: Ensure Local Godot 4.5b5"
	- Resulting symlinks: `.tools/godot/bin/godot` and `.tools/godot/bin/godot4.5b5`
- All tasks use the local binary first, falling back to `godot4` if not present.

### Running Tests Headless

From `godot_project/`:

```
../.tools/godot/bin/godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gexit
```

### Updating the Local Engine Copy

When upgrading to a new beta or stable:
1. Add a new folder under `.tools/godot/<version-tag>/` and download the zip.
2. Update symlink targets in `.tools/godot/bin/`.
3. Update `project.godot` `config/features` if necessary.
4. Run smoke tests to validate.

