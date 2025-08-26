# Project Index — Broken Divinity: New Babylon

Living index of systems, scenes, data, and tests. Keep this updated as the project evolves.

## Overview
Godot 4.5-based prototype using Maaack template, ASCII grid rendering, and a four-panel UI. Content is centralized in Resource Databases, with JSON saves (3 slots).

## Hop 1: Demo Boot & UI Restoration

- Main scene: opening_with_logo.tscn (routes to animated main menu)
- Main menu: all buttons (New Game, Options, Credits, Exit) now fully wired
- New Game launches five-panel Main UI (main_ui.tscn)
- Options menu restored (tabs: Controls, Audio, Video)
- Credits and Exit function as expected
- All broken/empty scenes/scripts restored from template
- Headless and editor boot confirmed
- See DEMO_SPEC.md for UI and flow details

## Hop 2: CP437 Mapping + Editor Tools

- CSV-based CP437 mapping at `godot_project/data/config/cp437_index.csv` (maintained source)
- Runtime loader prefers CSV and falls back to JSON at `godot_project/data/config/cp437_index.json`
- Editor plugin `addons/cp437_tools` provides Validate, Export, and Scratch Test (exercises loader)
- Added conservative DF-standard tiles: walls/doors/stairs/ramps/tracks/grates/coffins/stockpiles/workshop frames; furniture (bed/statue/table/chair/cabinet/chest/weapon rack/armor stand); fixtures (anvil/cage/restraint/lever states/hatch/floodgate); barrel/bin
- Mapping decisions and palette guidance in `project/docs/CP437_INDEX_BROKEN_DIVINITY.md` and `project/docs/TILE_INDEX.md`

## Core Systems

### UI Panels
- **Location**: `godot_project/scenes/` (TopBar, StatusPanel, LogPanel, ActionBar, CentralPanel host)
- **Purpose**: Four-panel layout reused across exploration, combat, and colony management
- **Key Classes**: TBD (`TopBar.gd`, `StatusPanel.gd`, `LogPanel.gd`, `ActionBar.gd`)
- **Dependencies**: InputMap, Themes, Font assets
- **Tests**: `godot_project/tests/smoke/test_ui_panels.gd` (planned)

### ASCII Grid (Renderer)
- **Location**: `godot_project/addons/ascii_grid/`
- **Purpose**: CP437-style ASCII grid (target ~80×36 @ 1280×720)
- **Key Classes**: `TermRect`, `TermElement`, `TermContainerVBox`, `TermLabel`
- **Usage in UI**: `MainPanel/TermRect` renders `TermRoot` children (Title, ApartmentMap, TestPattern)
- **Docs**: `godot_project/docs/ASCII_RENDERING.md`
- **Tests**: Integration tests validate non-clear shader textures; smoke runner prints diagnostics

### TurnEngine
- **Location**: `godot_project/scripts/systems/turn_engine.gd`
- **Purpose**: Round-based initiative; 2 actions per turn; movement/attack interchangeable
- **Key Classes**: `TurnEngine`, `InitiativeTracker`
- **Dependencies**: Entity stats, RNG
- **Tests**: Unit tests for initiative ordering and action budget

### CombatManager
- **Location**: `godot_project/scripts/systems/combat_manager.gd`
- **Purpose**: Damage typing (ballistic/infernal/holy), blessing status converting outgoing damage → holy for N rounds
- **Key Classes**: `CombatManager`, `Damage`, `StatusEffect`
- **Dependencies**: TurnEngine, Entities, RNG
- **Tests**: Unit test verifying holy conversion increases damage vs demons

### SaveSystem
- **Location**: `godot_project/scripts/systems/save_system.gd`
- **Purpose**: 3 JSON save slots, metadata (slot, name, timestamp)
- **Key Classes**: `SaveSystem`
- **Dependencies**: FileAccess, user://
- **Tests**: Integration tests for round-trip save/load

### Data Layer (Resource Databases)
- **Location**: `res://addons/resource_databases/` (editor) + `res://data/content_database.tres` (db file)
- **Purpose**: Centralize text/ASCII art, suffix tables; edited in-editor via plugin UI
- **Runtime Access**: `ContentDB` autoload (`scripts/autoload/content_db.gd`):
	- `ContentDB.get_entry("collection/id")` → Resource
	- `ContentDB.fetch("collection", "id")` → Resource
	- `ContentDB.fetch_collection("collection")` → Dictionary[int_id: Resource]
	- `ContentDB.fetch_category("collection", "tag")` → Dictionary[int_id: Resource]
- **Tests**: Unit test `test_content_db_autoload.gd`

## Scenes/UI Components

### Apartment Scene
- **Location**: `godot_project/scenes/game_scene/apartment/`
- **Purpose**: Initial exploration room; mirror triggers character creation
- **Controllers**: `ApartmentController.gd`
- **Dependencies**: AsciiPanel, UI Panels, Data Layer
- **Tests**: Game-flow test for mirror interaction (planned)

### Character Creation Scene
- **Location**: `godot_project/scenes/opening/character_creation/`
- **Purpose**: Name, background, personal traits
- **Controllers**: `CharacterCreation.gd`
- **Dependencies**: SaveSystem, Data Layer
- **Tests**: UI flow test

### Alley Combat Scene
- **Location**: `godot_project/scenes/game_scene/alley/`
- **Purpose**: First combat vs imps; Dona blessing
- **Controllers**: `CombatController.gd`
- **Dependencies**: TurnEngine, CombatManager, AsciiPanel
- **Tests**: Deterministic combat test

### Settlement (New Babylon)
- **Location**: `godot_project/scenes/game_scene/settlement/`
- **Purpose**: Production loop, recruit militia
- **Controllers**: `SettlementController.gd`
- **Dependencies**: Data Layer, SaveSystem
- **Tests**: Resource tick test

### Ruin (Dungeon)
- **Location**: `godot_project/scenes/game_scene/ruin/`
- **Purpose**: Procgen dungeon; loot; travel
- **Controllers**: `DungeonController.gd`
- **Dependencies**: AsciiPanel, TurnEngine
- **Tests**: Generation invariants

## Data Architecture

### Configuration
- **Location**: `godot_project/data/config/`
- **Format**: JSON
- **Purpose**: Settings, input mappings, UI config

### Game Data
- **Location**: `godot_project/data/game/`
- **Format**: Resource Databases (`.tres`), JSON (saves)
- **Purpose**: Suffixes, text, ASCII art, loot tables

### Schemas
- **Location**: `godot_project/data/schemas/`
- **Purpose**: JSON schemas for saves and config

## Test Organization

### Unit Tests
- **Location**: `godot_project/tests/unit/`
- **Coverage**: TurnEngine, CombatManager, SaveSystem utilities
- **Runner**: GUT headless

### Integration Tests
- **Location**: `godot_project/tests/integration/`
- **Coverage**: Scene composition, ContentDB access, save round-trips
- **Runner**: GUT headless

### Smoke Tests
- **Location**: `godot_project/tests/smoke/`
- **Coverage**: Project boot, main scenes load
- **Runner**: GUT headless

### Scene Smoke Tests
- Index: `godot_project/scripts/tools/scene_index.json` (list scenes to quickly validate instancing)
- Runner: `godot_project/scripts/tools/scene_smoke_runner.gd` (headless; loads each scene for one frame)
- VS Code Tasks:
	- "Smoke: Scenes from Index" — run all listed scenes
	- "Smoke: Scenes (Filter)" — prompt for substring (e.g., `apartment`)
	- Maintainers: add new scene paths to the JSON; no new tasks required

### Game Flow Tests
- **Location**: `godot_project/tests/game_flow/`
- **Coverage**: Apartment → Mirror → Alley → Angel → Settlement → Ruin → Credits
- **Runner**: GUT headless

## External Dependencies

### Core Libraries
- Maaack Game Template: structure and automation
- GUT: testing framework
- ascii_grid: ASCII rendering (primary)
- Resource Databases addon: data access

### Development Tools
- VS Code tasks.json for running editor and tests

## Build and Deployment

### Build Process
- **Command**: Godot export presets (TBD)
- **Output**: `build/` (TBD)
- **Dependencies**: Godot 4.5

### Deployment
- **Target**: Desktop (Linux initially)
- **Process**: Use export preset; verify smoke tests in build
- **Configuration**: Environment flags for debug/release

## Key Files and Locations

### Configuration Files
- `godot_project/project.godot`: Engine/project settings
- `.vscode/tasks.json`: Tasks for editor/tests/tools

### Entry Points
- `res://addons/maaacks_game_template/examples/scenes/opening/opening_with_logo.tscn`: Current main scene (keep)
- `addons/gut/gut_cmdln.gd`: Test runner entry

### Documentation
- Project docs in `project/docs/`
- MCP methodology in `MCP/`

## Development Notes

### Current Focus
Phase A: Foundation (Boot, UI scaffold, Save/DB)

### Technical Debt
TBD as systems are implemented

### Performance Considerations
ASCII grid draw cost at 80×36; consider batching and font atlas; keep logs efficient

---
Update this index whenever you add new systems, refactor existing ones, or change the project structure.

#EOF
