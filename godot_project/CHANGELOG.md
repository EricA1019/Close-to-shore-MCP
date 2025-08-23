# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
- TBD

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
