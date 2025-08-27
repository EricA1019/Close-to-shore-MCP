# Broken Divinity — Demo (Godot 4)

A small Godot 4 demo that boots through an Opening scene into a custom Main UI, built on top of the Maaacks Game Template. Features **Canvas-based ASCII rendering** for reliable cross-platform text display, plus a CSV‑first CP437 tile index with an editor plugin.

**This project follows the [Close-to-Shore MCP methodology](MCP/CLOSE_TO_SHORE.md)** for stable, test-driven development with heavy tooling investment for long-term reliability.

## Development Philosophy

This is a **learning project** focused on:
- **Stability over speed**: Choosing robust foundations even when they require more upfront work
- **Tool investment**: Building reliable automation that pays dividends over time
- **Comprehensive testing**: Unit, integration, smoke, and end-to-end validation
- **Documentation-driven development**: Every decision captured and explained
- **Cross-platform reliability**: Single-binary tools that work consistently everywhere

See [MCP/CLOSE_TO_SHORE.md](MCP/CLOSE_TO_SHORE.md) for our complete development methodology and [MCP/TOOLING_PHILOSOPHY.md](MCP/TOOLING_PHILOSOPHY.md) for our approach to tool selection and development.

## Tooling

This project is Rust-first for tooling:
- **Rust** ([`rust/cts`](rust/)) for reliable, fast tooling (tests, docs, engine/scene tools, lints, health, release)
- **GDScript** for game logic and Godot integration

Key CTS commands:
- `cts test` — unified test runner (GUT, UI, smoke)
- `cts bundle` — MCP context bundler
- `cts engine` — ensure/link Godot binaries
- `cts scene` — index and lint scenes
- `cts lint` — api-guard and gdscript linter
- `cts docs` — fetch/search/sync docs
- `cts logs summarize` — aggregate run logs
- `cts health` — project health gate (PASS/WARN/FAIL)
- `cts release` — release preparation

### Resource Database

Canonical content (entities, items, abilities, statuses, tiles, layouts) lives in Godot Resource files (`.tres/.res`) and is indexed via our Rust bridge and CLI.

- How it works and how to query it: see `godot_project/docs/RESOURCE_DB.md`.
- Quick CLI: `cts db list|search|index|export|validate` (JSON outputs, CI-friendly)

### Native Extension (Rust)

- A minimal GDExtension (Rust) provides `HelloNode` with a `say_hello(name)` method.
- See `godot_project/docs/GDEXTENSION_SETUP.md` for build/copy and trust/allow steps.

## What's here

- Opening ➜ Main Menu ➜ Main UI flow restored (Opening is the main scene)
- **ASCII Canvas System**: Reliable cross-platform text rendering using Godot's Control._draw()
  - Working demos: `scenes/ascii_min_demo/ascii_min_demo_canvas.tscn`
  - Room examples with walls, floors, furniture (245+ rendered elements)
  - Migration from problematic shader approach to stable Canvas drawing
- Maaacks Template menus: main menu, options, credits, loading (wired and working)
- CP437 mapping workflow:
  - Source of truth: `res://data/config/cp437_index.csv`
  - JSON fallback: `res://data/config/cp437_index.json`
  - Loader: `res://scripts/systems/cp437_index_loader.gd` (prefers CSV, falls back to JSON)
  - Editor plugin: `CP437 Tools` (Validate CSV, Export JSON, Scratch Test)
- DF‑standard tiles (conservative subset) pre‑filled in the CSV

## ASCII Rendering Status: ✅ WORKING

- **Canvas Approach**: AsciiCanvas renders correctly in editor and runtime
- **Editor Visibility**: No more black screen issues
- **Cross-Platform**: Uses standard Godot APIs (Control._draw())
- **Performance**: Dirty region optimization for large scenes
- **Test Coverage**: 2/2 integration tests passing with content validation

### Quick Start: ASCII Demo

```bash
# Run working ASCII room demo
godot4 --path godot_project scenes/ascii_min_demo/ascii_min_demo_canvas.tscn
```

View ASCII room with walls (█), floor (.), furniture (T/C/B/=/□), and door (+)ity — Demo (Godot 4)

A small Godot 4 demo that boots through an Opening scene into a custom Main UI, built on top of the Maaacks Game Template. It also ships a CSV‑first CP437 tile index with an editor plugin to validate and export the mapping used by the game.

## What’s here

- Opening ➜ Main Menu ➜ Main UI flow restored (Opening is the main scene)
- Maaacks Template menus: main menu, options, credits, loading (wired and working)
- CP437 mapping workflow:
  - Source of truth: `res://data/config/cp437_index.csv`
  - JSON fallback: `res://data/config/cp437_index.json`
  - Loader: `res://scripts/systems/cp437_index_loader.gd` (prefers CSV, falls back to JSON)
  - Editor plugin: `CP437 Tools` (Validate CSV, Export JSON, Scratch Test)
- DF‑standard tiles (conservative subset) pre‑filled in the CSV

## Quick Links

- **ASCII Rendering**: [docs/ASCII_RENDERING.md](godot_project/docs/ASCII_RENDERING.md) - Canvas system overview
- **Migration Guide**: [docs/CANVAS_MIGRATION_GUIDE.md](godot_project/docs/CANVAS_MIGRATION_GUIDE.md) - Shader to Canvas migration
- **Working Demo**: `godot_project/scenes/ascii_min_demo/ascii_min_demo_canvas.tscn`
- **Basic Room**: Enhanced demo with walls, floor, furniture (245 elements)

## Requirements

- Godot 4.x (open the folder that contains `project.godot`)
- Desktop OS: Linux/Windows/macOS

## Run it

1) Open the project in Godot (either the repository root if `project.godot` is there, or the `godot_project/` folder if present).
2) Press Play (F5). The Opening scene should display, then you can continue to the Main UI from the menu.

Optional CLI (if Godot is on PATH):

```bash
# If project.godot lives in ./godot_project
godot4 --path godot_project

# Or if project.godot is at repo root
godot4 --path .
```

## CP437 Tools (Editor Plugin)

Enable via: Project > Project Settings > Plugins > CP437 Tools (Enable)

- Validate CSV: Checks `cp437_index.csv` for duplicates, invalid codepoints, color format, and bad references
- Export JSON: Parses CSV and writes `cp437_index.json` for runtime fallback/inspection
- Scratch Test: Quick end‑to‑end smoke test of parse/resolve

CSV is the single source of truth. Edit CSV, then Validate and Export.

## Tasks (VS Code)

- CTS: Build Release, Build Context Bundle
- CTS: Engine Ensure/Link; Godot 4.5 managed run/editor
- CTS: Scene Index/Lint; Smoke: Scenes (and filter)
- CTS: Lint API Guard/GDScript (AST optional)
- CTS: Logs Summarize; CTS: Health Check
- CTS: Release Prep (dry-run)

Tip: Health is enforced in CI (fails on summary=fail). STRICT_LINT can be toggled to hard-fail GDScript findings.

## Logging and RUN_ID

- Central log bus writes minimal INFO+ to console and full DEBUG+ to a file sink.
- File sink path: `user://logs/run-<RUN_ID>.log` (Godot user data folder).
- The test runner also tees its terminal output to `logs/run-<RUN_ID>-testrunner.out` in the repo for quick inspection.
- RUN_ID is auto-generated by the runner, or you can set it manually with `RUN_ID=...` in your environment before launching Godot.

Agent Context: Run the “CTS: Build Context Bundle” task to generate `.mcp_context/context_bundle.md` that aggregates key docs (README, MCP docs, prompt templates).

## File map (key bits)

- `res://data/config/cp437_index.csv` — Tile/entity/material rules (maintained)
- `res://data/config/cp437_index.json` — Exported JSON (generated)
- `res://scripts/systems/cp437_index_loader.gd` — Typed loader that resolves tiles/material colors
- `res://addons/cp437_tools/` — Editor plugin (validate/export/scratch)
- Opening/main menu scenes: Maaacks template examples (Opening is set as main scene)

## Contributing

- Keep CSV authoritative; run Validate + Export after edits
- Small PRs preferred (one logical change)
- Add/update docs when behavior changes

## Licenses & Credits

- Code: MIT (unless stated otherwise in file headers)
- UI/Menu base: Maaacks Game Template (credit: Maaacks)
- CP437 font/index: Include appropriate font license and attribution (MIT/SIL as applicable); DF community for standardized tiles

See `project/docs/` for deeper notes, hop summaries, and roadmap if present.
