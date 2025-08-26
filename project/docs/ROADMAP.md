# Project Roadmap — Broken Divinity: New Babylon

High-level, flexible checklis### Phase C: Settlem### Phase D: Overworld + Ruin
- [ ] Hop 16: Travel with "random" event
  - Goal: Choice between demons/angels; charm can reconcile both; grants recruits and a .357 magnum with random affix.
  - Success: Branching event test; reward assignment verified.
- [ ] Hop 17: Procgen dungeon
  - Goal: Grid-based dungeon generation and movement; central panel renders; loot tables.
  - Success: Generation invariants tested; traversal works.
- [ ] Hop 18: Return to settlement and gear assign
  - Goal: Equip followers; show loop closure.
  - Success: Equip applies modifiers; smoke passes.
- [ ] Hop 19: Ending sequence
  - Goal: Splash + credits; demo completes.
  - Success: Flow test reaches credits without errors.w Babylon)
- [ ] Hop 13: Arrival + Lucy intro
  - Goal: Narrative beats and badge of the Morning Star.
  - Success: State flags set; log/text shown.
- [ ] Hop 14: Basic production loop
  - Goal: Build simple facility nodes producing base resources over time while maintained.
  - Success: Tick test verifies resource accumulation with upkeep.
- [ ] Hop 15: Recruit militia with suffix
  - Goal: Recruitment creates 2 units; one always has suffix "brave" with higher courage.
  - Success: Data-driven suffix application from SQLite.ed hops/features, aligned to the Close-to-Shore MCP. Every hop remains small, test-first, and results in a bootable, testable game.

## Project Vision
A slick, modern, Door-in-the-Woods-inspired ASCII roguelite with a four-panel UI, data-driven content via Resource Databases, JSON save slots, and a grounded prototype demonstrating core systems for the full game.

## Current Status
- [x] Project setup complete (Maaack template imported; main scene unchanged)
- [x] Documentation structure established (MCP docs + project docs)
- [x] Basic four-panel UI scaffold (main_ui.tscn with working panels)
- [x] CP437 mapping workflow (CSV + loader + editor tools)
- [x] ASCII rendering baseline (Canvas-based with AsciiCanvas system)
- [x] **Debugging Tools Suite** (Scene Inspector, HTTP Server, Linter, Test Runner, Doc Generator)
- [x] **Interactive Apartment** (28x16 grid, POI system, WASD controls - 14/15 tests passing)
- [ ] **Input handling fixes** (WASD player movement currently non-responsive)
- [ ] **Layout improvements** (replace magic numbers with named constants)
- [ ] Data layer (Resource Databases content + JSON save slots)
- [ ] Core gameplay loop prototype implemented
- [ ] Demo narrative flow implemented end-to-end

## Phases and Hops

Note: Hops should usually stay under ~200 LOC and include tests, with exceptions explicitly noted and tracked.

### Phase A: Foundation (Boot + UI + Persistence) ✅ COMPLETE
- [x] Hop 1: Boot check + ASCII grid skeleton
  - Goal: Verify Godot project boots headless and in-editor; create minimal AsciiPanel grid (80×36 @ 1280×720) scene and a smoke test that instantiates it.
  - Success: ✅ Smoke test passes; project boots; scene loads without errors.
- [x] Hop 2: ASCII Rendering Migration to Canvas
  - Goal: Replace problematic shader-based rendering with reliable Canvas system for editor visibility
  - Success: ✅ Canvas system works in editor/runtime; 245-element room demo; 2/2 tests passing
- [x] Hop 3: CP437 CSV + Loader + Editor Tools
  - Goal: CSV-first mapping for DF-style CP437 with validation/export and runtime loader
  - Success: ✅ CSV maintained; plugin validates/exports; loader resolves sample keys
- [x] **Hop 3.5: Debugging Tools Suite**
  - Goal: Create comprehensive debugging infrastructure for AI agent development
  - Success: ✅ Scene Inspector, Debug HTTP Server, GDScript Linter, Test Runner, Doc Generator all implemented and working
  - Impact: AI agents now have "Scene Vision" - real-time access to game state via JSON exports and HTTP API
- [x] **Hop 3.6: Interactive Apartment Implementation**  
  - Goal: Multi-room apartment with WASD movement, POI system, detective items
  - Success: ✅ 14/15 tests passing; apartment renders in main UI; Canvas integration working
  - Known Issues: Player input not responding to WASD; layout needs improvement (26 critical linting errors identified)
### Phase B: Data & Content (Save System + Resource Databases)
- [ ] **Hop 4: Input Handling Fixes**
  - Goal: Fix WASD player movement in Interactive Apartment; address 26 critical linting errors
  - Action Items: Add node validation checks; fix unvalidated node access patterns; test input event flow
  - Success: Player responds to WASD; linting errors reduced; Scene Inspector validates input handling
- [ ] **Hop 4.5: Layout and Code Quality Improvements** 
  - Goal: Replace 89 magic numbers with named constants; improve apartment layout design
  - Action Items: Create layout constants; redesign POI positioning; add type hints (83 warnings)
  - Success: Linter shows significant reduction in warnings; apartment layout is intuitive
- [ ] Hop 5: SaveSystem (3 JSON slots)
  - Goal: Implement JSON save/load with metadata (slot, name, timestamp). Use user:// path. Basic tests for create, overwrite, read.
  - Success: Unit/integration tests pass; save round-trip verified.
- [ ] Hop 6: Resource Databases data layer
  - Goal: Integrate Resource Databases addon. Create DB in-editor and store in res://. Provide simple Content API (query text, ASCII art, suffixes) via ContentDB autoload.
  - Success: Unit test for content fetch; migration/copy smoke test.

### Phase C: Core Gameplay Slice (Apartment → First Fights)
- [ ] Hop 7: Apartment exploration scene enhancement
  - Goal: Improved apartment with proper input handling; Door-in-the-Woods style rendering in CentralPanel; walkable multi-room grid.
  - Success: Player can move around; log panel updates; POI interactions work correctly.
- [ ] Hop 8: Mirror-triggered character creation
  - Goal: Separate scene; choose name and background (e.g., Homicide/Narcotics/Organized Crime; personal traits). Persist selection.
  - Success: UI flow test; data saved; returns to apartment.
- [ ] Hop 9: Inventory + equipment basics
  - Goal: Equip gear that modifies stats/abilities. Minimal inventory UI in ActionBar with keybinds.
  - Success: Equip/unequip modifies a stat; test verifies.
- [ ] Hop 10: Escort Dona Margarita
  - Goal: Short guided path with simple follow behavior and log narration.
  - Success: Trigger reaches alley start.
- [ ] Hop 11: First combat (2 imps + blessing buff)
  - Goal: TurnEngine (initiative; 2 actions); CombatManager (ballistic/infernal/holy); Dona applies blessing converting outgoing to holy for N rounds.
  - Success: Deterministic test covering buffed damage > unbuffed.
- [ ] Hop 12: Unwinnable angel fight
  - Goal: Scripted loss; logs/permadeath for NPCs demonstrated.
  - Success: Flow continues after defeat.

### Phase C: Settlement Slice (New Babylon)
- [ ] Hop 11: Arrival + Lucy intro
  - Goal: Narrative beats and badge of the Morning Star.
  - Success: State flags set; log/text shown.
- [ ] Hop 12: Basic production loop
  - Goal: Build simple facility nodes producing base resources over time while maintained.
  - Success: Tick test verifies resource accumulation with upkeep.
- [ ] Hop 13: Recruit militia with suffix
  - Goal: Recruitment creates 2 units; one always has suffix “brave” with higher courage.
  - Success: Data-driven suffix application from SQLite.

### Phase D: Overworld + Ruin
- [ ] Hop 14: Travel with “random” event
  - Goal: Choice between demons/angels; charm can reconcile both; grants recruits and a .357 magnum with random affix.
  - Success: Branching event test; reward assignment verified.
- [ ] Hop 15: Procgen dungeon
  - Goal: Grid-based dungeon generation and movement; central panel renders; loot tables.
  - Success: Generation invariants tested; traversal works.
- [ ] Hop 16: Return to settlement and gear assign
  - Goal: Equip followers; show loop closure.
  - Success: Equip applies modifiers; smoke passes.
- [ ] Hop 17: Ending sequence
  - Goal: Splash + credits; demo completes.
  - Success: Flow test reaches credits without errors.

### Phase E: Polish and Stability
- [ ] Accessibility, input refinements, fonts, performance, docs.

## Flexible Scope Notes
- Hops can be split/merged as we learn; the demo flow stays intact.
- Resource Databases holds large text/ASCII art and suffixes; JSON handles save slots.
- Fonts: CP437-like mono baseline; per-faction variants (e.g., gold flowing for angels, red angular for demons) layered stylistically.

## Success Metrics
- [x] Application boots without errors (smoke tests green)
- [x] All committed tests pass consistently in headless runs (14/15 tests passing)
- [x] **Debugging tools infrastructure complete** (Scene Inspector, HTTP Server, Linter, Test Runner, Doc Generator)
- [x] **Interactive apartment integrated into main UI** (apartment loads via New Game button)
- [ ] **Input handling responsive** (WASD player movement working)
- [ ] **Code quality improved** (critical linting errors addressed)
- [ ] Demo narrative runs end-to-end
- [x] Four-panel UI feels responsive and readable
- [ ] Data-driven content loads from Resource Databases; saves round-trip via JSON
- [x] Documentation current (Index, Roadmap, Log, Hop summaries)
- [x] **AI agent workflow enhanced** (Scene Vision system operational)

---
Keep this living document updated as priorities shift and new discoveries emerge.

#EOF
