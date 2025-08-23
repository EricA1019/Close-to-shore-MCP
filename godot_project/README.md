# Broken Divinity: New Babylon (Demo)

This is a Godot 4.3 project. Current branch state focuses on integrating an ASCII UI pane and stabilizing headless tests.

## Current Status (2025-08-23)

- New Game shows the Apartment content flow, panels populate, and the status bar updates.
- ASCII pane integrated into `MainPanel` and bound to `LocationState` — the ASCII title reflects the current location.
- Headless GUT tests green for the ASCII integration and binding.
- Apartment ASCII content area still renders black; only the title shows. This is an accepted partial stabilization checkpoint.

## Notable Changes in this checkpoint

See `CHANGELOG.md` section `0.1.0-partial-stabilization` for details.

## Running Tests (headless)

Requires Godot 4.3 CLI (`godot4`). From the project root (`godot_project`):

```bash
godot4 --headless --path . -s addons/gut/gut_cmdln.gd -gexit -gdir=res://tests/integration -glog=1 -gselect=test_ascii_in_main_panel.gd
godot4 --headless --path . -s addons/gut/gut_cmdln.gd -gexit -gdir=res://tests/integration -glog=1 -gselect=test_ascii_location_binding.gd
```

## Dev Notes

- The ASCII addon was adjusted for headless robustness by preloading dependencies and using path-based `extends`. This reduces reliance on class cache order.
- `MainPanel` has a `custom_minimum_size` (480x270) to ensure TermRect can allocate non-zero images in tests.
- Binder script: `scripts/ui/ascii_location_title.gd` sets the ASCII title from `LocationState` and listens to `location_changed`.

## Rollback Instructions

To revert to this safe checkpoint later:

- Tag this commit as `v0.1.0-partial-stabilization` after pushing, or create a branch `safe/partial-stabilization-2025-08-23`.
- You can later check out that tag/branch to regain this working baseline.

## Next Steps

- Render actual ASCII content for the Apartment (not only title).
- Re-tighten types in the addon once CI is stable.
- Expand tests to cover keyboard navigation behaviors in ASCII pane.
