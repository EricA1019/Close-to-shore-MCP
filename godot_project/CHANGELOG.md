# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
- TBD

## [0.1.1-mcp-logging-upgrade] - 2025-08-23
### Added
- MCP Context Bundler: `MCP/TOOLS/context_bundler.py` + VS Code task “MCP: Build Context Bundle”.
- Dual-channel logging via `res://scripts/autoload/log_bus.gd` (INFO+ console, DEBUG+ file at `user://logs/run-<RUN_ID>.log`).
- Test Runner wrapper `MCP/TOOLS/test_runner.sh` that sets RUN_ID and tees output to `logs/run-<RUN_ID>-testrunner.out`.
- MCP tools stubs and tasks: `log_summary.py`, `scene_lint.py`, `release_helper.py`.

### Changed
- VS Code tasks updated: GUT tasks depend on bundler; added Runner tasks for All/Integration.

### Notes
- All integration tests passing under Godot 4.x headless.

## [0.1.0-partial-stabilization] - 2025-08-23
### Added
- ASCII terminal integrated into `MainPanel` with `TermRect` and `TermRoot`/`TermLabel`.
- New binder `scripts/ui/ascii_location_title.gd` to reflect `LocationState` in ASCII title.
- Integration tests:
  - `tests/integration/test_ascii_in_main_panel.gd`
  - `tests/integration/test_ascii_location_binding.gd`

### Changed
- Relaxed type hints and switched to path-based `extends` in ASCII addon to support headless tests (Godot 4.3) and avoid class cache issues.
- Fixed `TermLabel` grid-building bugs for no-wrap and arbitrary modes.
- Fixed `TermContainer` border drawing and title alignment; added Resource typing for exported properties.
- Set a `custom_minimum_size` on `MainPanel` to avoid zero-size rendering in headless tests.

### Known Issues
- Apartment ASCII area renders black; only the status/location tag updates reliably. Content rendering is pending.
- Some addon scripts have reduced static typing to support headless; we can revisit after stabilizing CI.
