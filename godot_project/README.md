# Broken Divinity: New Babylon

## Project Goals

This project is a Godot-based prototype for a roguelike, ASCII-styled game inspired by "Door in the Woods" and built for scalability and modularity. The core goals are:
- Use a four-panel, data-driven UI for all interactions (combat, colony management, exploration).
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
- **Four-Panel Layout:** Main, Output, Action, Debug (data-driven, reused everywhere).
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
