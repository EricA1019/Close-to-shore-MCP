# [Project Name]

[Brief description of what this project does and why it exists]

## Quick Start

### Prerequisites

### Setup
```bash
# Clone the repository
git clone [repository-url]
cd [project-directory]

# Install dependencies
[installation commands]

# Run tests to verify setup
[test command]

# Start the application
[run command]
```

## Project Structure

```
project/
├── docs/           # Project documentation
├── data/           # Game data, configurations, schemas
├── tests/          # Test suites (unit, integration, smoke, game-flow)
├── src/            # Source code
└── [other folders]

MCP/                # Close-to-Shore methodology (reusable)
├── CLOSE_TO_SHORE.md
├── STYLE_GUIDE.md
├── TEST_POLICY.md
└── TOOLS/
```

## Development Workflow

This project follows the **Close-to-Shore MCP** methodology:

### Before Starting Work:
1. Read `project/docs/ROADMAP.md` for current priorities
2. Check `project/docs/DEV_LOG.md` for recent decisions
3. Review `project/docs/PROJECT_INDEX.md` for system overview

### Development Process:
1. Plan hop using `MCP/CLOSE_TO_SHORE.md` guidelines
2. Write failing tests first
3. Implement minimal changes to pass tests
4. Update documentation
5. Validate with `MCP/TOOLS/hop_validator.py`

## Testing

```bash
# Run all tests
[full test command]

# Run specific test suites
[unit test command]
[integration test command]
[smoke test command]
[game-flow test command]

# Use provided test runner
./MCP/TOOLS/test_runner.sh
```

## Documentation


## Contributing

1. Follow the Close-to-Shore MCP methodology in `MCP/`
2. Update documentation with all changes
3. Ensure all tests pass before committing
4. Use provided tools for validation

## Architecture

[Brief overview of the main architectural decisions and patterns used]

## License

[License information]


*This project uses Close-to-Shore MCP methodology for sustainable, test-driven development.*

#EOF
## Broken Divinity: New Babylon


This project is a Godot-based prototype for a roguelike, ASCII-styled game inspired by "Door in the Woods" and built for scalability and modularity. The core goals are:
- Use a five-panel, data-driven UI for all interactions (combat, colony management, exploration):
	- Main Panel
	- Output Panel
	- Action Panel
	- Debug Panel
	- Status Panel (in-game time, status, location)
- Render the main game view with a modern ASCII grid (CP437-style font, Unicode, color-coded factions).
- Integrate a robust save system (3 slots, JSON-based, extensible for future SQLite integration).
- Build a workflow for iterative, test-driven development (steps, hops, phases, epochs).
- Lay the groundwork for a scalable, content-rich game world with centralized data management.

## Scene Flow (Demo/Prototype)

1. **Detective Wakes Up**
	- Player explores their apartment (first system, default UI scene, ASCII rendering).
	- Simple room to start, expandable to larger dungeons.

2. **Mirror: Character Creation**
	- Triggered by interacting with the mirror.
	- Separate scene for background selection (police, veteran, etc.) and personal touches.

3. **Gear Up**
	- Inventory system: equip items, modify stats, grant abilities.
	- Detective leaves apartment.

4. **Meet Dona Margarita**
	- First friendly NPC encounter.
	- Text event: creatures falling from the sky.
	- Lead Dona through the alley.

5. **First Combat: Imps**
	- Two imps with random suffixes (enemy system showcase).
	- Turn-based combat, initiative, damage types (ballistic, holy, infernal).
	- Dona buffs detective, permadeath for NPCs.

6. **Unwinnable Fight: Maddened Angel**
	- Both detective and Dona are slain.

7. **Lucifer's Offer**
	- Detective is visited by Lucifer, learns Yahweh is dead.
	- Offered near-immortality to solve the mystery.

8. **Arrive at New Babylon**
	- Settlement at the "body" of God, stable in chaos.
	- Detective receives the Morning Star badge (faction mechanics).

9. **Settlement Management**
	- Build shanty town, resource production.
	- Recruit militia (suffix system for troops).

10. **Ruins Exploration**
	 - Travel to ruins, random event (angels/demons, charm check).
	 - Recruit new followers, receive special weapon (affix system).

11. **Dungeon Crawl**
	 - Procedural dungeon, grid-based exploration, loot and gear assignment.

12. **Demo End**
	 - Return to settlement, Lucy explains basics, splash screen and credits.


## UI & System Overview
- **Five-Panel Layout:**
	- Main Panel: Top-down ASCII game view
	- Output Panel: Game log, feedback, narrative
	- Action Panel: Contextual actions, controls
	- Debug Panel: Developer/debug info
	- Status Panel: In-game time, player status, location
- **AsciiPanel:** Monospaced Unicode grid, 80×36 @ 1280×720.
- **TopBar:** Date/time/currency.
- **StatusPanel, LogPanel, ActionBar:** Auto-populate from state.
- **TurnEngine:** Initiative, 2 actions/turn, movement/attack interchangeable.
- **CombatManager:** Damage types, blessings, status effects.
- **SaveSystem:** 3 slots, JSON metadata.
- **Font System:** CP437-style, color-coded for factions.

## Development Workflow
1. Check project status and run test suite.
2. Make a detailed implementation plan.
3. Write tests for desired features (test-first).
4. Implement and iterate until tests pass and program boots without errors.
5. Playtest each hop before moving forward.
6. Workflow improvements, refactoring, documentation.
7. Update documentation and project index.

---
For more details, see the docs and follow the workflow for each new feature or system.
