# Broken Divinity — Demo (Godot 4)

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
