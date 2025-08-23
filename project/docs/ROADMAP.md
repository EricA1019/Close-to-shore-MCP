# Project Roadmap — Broken Divinity: New Babylon

High-level, flexible checklist of planned hops/features, aligned to the Close-to-Shore MCP. Every hop remains small, test-first, and results in a bootable, testable game.

## Project Vision
A slick, modern, Door-in-the-Woods-inspired ASCII roguelite with a four-panel UI, data-driven content in SQLite, JSON save slots, and a grounded prototype demonstrating core systems for the full game.

## Current Status
- [x] Project setup complete (Maaack template imported; main scene unchanged)
- [x] Documentation structure established (MCP docs + project docs)
- [ ] Basic four-panel UI scaffold
- [x] CP437 mapping workflow (CSV + loader + editor tools)
- [ ] ASCII rendering baseline (CP437-like mono font)
- [ ] Data layer (SQLite content + JSON save slots)
- [ ] Core gameplay loop prototype implemented
- [ ] Demo narrative flow implemented end-to-end

## Phases and Hops

Note: Hops should usually stay under ~200 LOC and include tests, with exceptions explicitly noted and tracked.

### Phase A: Foundation (Boot + UI + Persistence)
- [ ] Hop 1: Boot check + ASCII grid skeleton
  - Goal: Verify Godot project boots headless and in-editor; create minimal AsciiPanel grid (80×36 @ 1280×720) scene and a smoke test that instantiates it.
  - Success: Smoke test passes; project boots; scene loads without errors.
- [x] Hop 2: CP437 CSV + Loader + Editor Tools
  - Goal: CSV-first mapping for DF-style CP437 with validation/export and runtime loader
  - Success: CSV maintained; plugin validates/exports; loader resolves sample keys
- [ ] Hop 3: SaveSystem (3 JSON slots)
  - Goal: Implement JSON save/load with metadata (slot, name, timestamp). Use user:// path. Basic tests for create, overwrite, read.
  - Success: Unit/integration tests pass; save round-trip verified.
- [ ] Hop 4: SQLite data layer
  - Goal: Integrate SQLite plugin. Read-only seed DB in res:// copied to user:// on first run. Provide simple Content API (query suffixes/text assets).
  - Success: Unit test for content fetch; migration/copy smoke test.

### Phase B: Core Gameplay Slice (Apartment → First Fights)
- [ ] Hop 5: Apartment exploration scene
  - Goal: Default UI scene with Door-in-the-Woods style rendering in CentralPanel; walkable single-room grid.
  - Success: Player can move around; log panel updates.
- [ ] Hop 6: Mirror-triggered character creation
  - Goal: Separate scene; choose name and background (e.g., Homicide/Narcotics/Organized Crime; personal traits). Persist selection.
  - Success: UI flow test; data saved; returns to apartment.
- [ ] Hop 7: Inventory + equipment basics
  - Goal: Equip gear that modifies stats/abilities. Minimal inventory UI in ActionBar with keybinds.
  - Success: Equip/unequip modifies a stat; test verifies.
- [ ] Hop 8: Escort Dona Margarita
  - Goal: Short guided path with simple follow behavior and log narration.
  - Success: Trigger reaches alley start.
- [ ] Hop 9: First combat (2 imps + blessing buff)
  - Goal: TurnEngine (initiative; 2 actions); CombatManager (ballistic/infernal/holy); Dona applies blessing converting outgoing to holy for N rounds.
  - Success: Deterministic test covering buffed damage > unbuffed.
- [ ] Hop 10: Unwinnable angel fight
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
- SQLite holds large text/ASCII art and suffixes; JSON handles save slots.
- Fonts: CP437-like mono baseline; per-faction variants (e.g., gold flowing for angels, red angular for demons) layered stylistically.

## Success Metrics
- [ ] Application boots without errors (smoke tests green)
- [ ] All committed tests pass consistently in headless runs
- [ ] Demo narrative runs end-to-end
- [ ] Four-panel UI feels responsive and readable
- [ ] Data-driven content loads from SQLite; saves round-trip via JSON
- [ ] Documentation current (Index, Roadmap, Log, Hop summaries)

---
Keep this living document updated as priorities shift and new discoveries emerge.

#EOF
