# Development Log

Chronological log of decisions, issues, and resolutions.

## Format
Each entry should include:
- **Date**: When the decision/issue occurred
- **Context**: What prompted this entry
- **Decision/Resolution**: What was decided or how issue was resolved
- **Rationale**: Why this approach was chosen
- **Impact**: How this affects the project going forward

---

## 2025-08-16

### Project Setup
**Context**: Starting new Close-to-Shore MCP project
**Decision**: Adopted Close-to-Shore MCP methodology with separated MCP/ and project/ folders
**Rationale**: Enables reuse of MCP methodology across multiple projects while keeping project-specific concerns separate
**Impact**: All future development will follow MCP principles of short hops, test-first development, and data-driven architecture

### Documentation Structure
**Context**: Need to establish consistent documentation practices
**Decision**: Implemented required documentation structure per MCP guidelines
**Rationale**: Ensures project maintainability and knowledge transfer
**Impact**: All hops must update relevant documentation before completion


## 2025-08-19

### Hop 1: Demo Boot & UI Restoration
**Context**: Initial demo boot was broken due to empty scenes/scripts and menu parse errors. Needed a working flow for UI, menus, and tests.
**Decision/Resolution**: Restored all broken/empty scenes/scripts from template. Wired main menu buttons (New Game, Options, Credits, Exit) to correct targets. Opening scene now routes to animated main menu, which launches the five-panel Main UI. All tests pass headless and in editor.
**Rationale**: Ensures a stable, testable foundation for future hops and feature work. Menu and UI logic now match spec and allow for iterative expansion.
**Impact**: Project is now bootable and testable. Documentation updated. Ready for next hop.

## 2025-08-24

### Hop 2: ASCII Rendering Migration to Canvas
**Context**: Shader-based ASCII rendering (TermRect) caused black screen in editor despite passing headless tests. Driver/OpenGL compatibility issues prevented reliable development.
**Decision/Resolution**: Migrated to Canvas-based rendering using Control._draw() with AsciiCanvas, AsciiCanvasBuffer, and AsciiCanvasCell classes. Maintained API compatibility with existing TermElement hierarchy.
**Rationale**: Canvas drawing uses standard Godot APIs for better cross-platform reliability. Dirty region optimization maintains performance. Dual-mode compatibility allows gradual migration.
**Impact**: 
- ✅ Editor visibility solved - ASCII content renders correctly in editor and runtime
- ✅ Working demos created: `ascii_min_demo_canvas.tscn` with 245-element room
- ✅ Test coverage: 2/2 integration tests passing with content validation
- ✅ Scalable architecture proven for both hand-made and procedural content
- 📖 All documentation updated to reflect Canvas approach
- 🔧 VS Code tasks added for Canvas testing and demo scenes

## 2025-08-25

### Debugging Tools Suite Implementation
**Context**: Need for improved AI agent workflow and debugging visibility in Godot development. Existing tooling insufficient for complex scene debugging and code quality assurance.
**Decision/Resolution**: Implemented comprehensive debugging tools suite with 6 major components:
1. **Scene Inspector** (`scripts/tools/scene_inspector.gd`) - Runtime scene tree export to JSON
2. **Debug HTTP Server** (`scripts/tools/debug_http_server.gd`) - REST API for external debugging access  
3. **GDScript Linter** (`MCP/TOOLS/gdscript_linter.py`) - Static code analysis with 198 issues found
4. **Test Runner** (`MCP/TOOLS/godot_test_runner.py`) - Automated GUT test execution and reporting
5. **Documentation Generator** (`MCP/TOOLS/godot_doc_generator.py`) - Auto-generate docs from source code
6. **Tool Suite Runner** (`MCP/TOOLS/godot_tool_suite.py`) - Orchestrates all tools with comprehensive reporting
**Rationale**: 
- "Scene Vision" system gives AI agents unprecedented visibility into game state via JSON exports
- External HTTP API allows debugging without modifying game code  
- Automated analysis catches issues early in development cycle
- Integrated workflow reduces manual validation steps
**Impact**:
- ✅ **Critical Issues Identified**: 26 unvalidated node access errors, 83 missing type hints, 89 magic numbers
- ✅ **AI Agent Workflow Enhanced**: Real-time scene inspection via HTTP endpoints
- ✅ **Quality Assurance Automated**: Single command runs full project analysis
- ✅ **Documentation Sync**: Auto-generated docs keep AI context current
- 🎯 **Next Actions**: Address input handling issues and code quality improvements identified by linter

### Interactive Apartment Implementation  
**Context**: Need for multi-room apartment exploration with WASD controls and interactive POIs for detective game mechanics.
**Decision/Resolution**: Built complete InteractiveApartment class extending TermElement with 28x16 grid, POI system, detective items (.38 service pistol, bourbon whiskey, brown leather jacket). Achieved 14/15 tests passing with apartment successfully integrated into main UI.
**Rationale**: Test-driven approach ensures robust foundation. Canvas compatibility provides editor visibility. POI system creates framework for interactive narrative elements.
**Impact**:
- ✅ **Major Milestone**: Apartment renders in main UI, accessible via New Game button
- ✅ **Test Coverage**: 14/15 tests passing validates core functionality  
- ✅ **Architecture Proven**: TermElement Canvas integration working correctly
- ⚠️ **Known Issues**: Player input not responding to WASD (unvalidated node access patterns identified by linter)
- 🔧 **Layout Needs Work**: Magic numbers throughout positioning code need constants
- 🚀 Foundation ready for ASCII game development

---

## Template Entries (Remove after first real entry)

### [Date] - [Topic]
**Context**: [What situation prompted this decision/issue]
**Decision/Resolution**: [What was decided or how the issue was resolved]
**Rationale**: [Why this approach was chosen over alternatives]
**Impact**: [How this affects current and future development]

### [Date] - [Technical Decision]
**Context**: [Technical challenge or choice point]
**Decision/Resolution**: [Technical approach chosen]
**Rationale**: [Technical and business reasons for the choice]
**Impact**: [Effects on architecture, performance, maintainability]

---

*Keep entries concise but complete. Future developers (including yourself) should understand the context and reasoning behind decisions.*

## 2025-08-20

### Hop 2: CP437 Mapping + Editor Tools
**Context**: Adopt DF-style CP437 with maintainable mappings and quick iteration. JSON-only was cumbersome for non-engineers.
**Decision/Resolution**: Added CSV source (`data/config/cp437_index.csv`), updated runtime loader to prefer CSV with JSON fallback, and built an editor plugin (CP437 Tools) with Validate, Export, and Scratch Test. Imported conservative DF-standard tiles (walls/doors/stairs/ramps/tracks/grates/coffins/stockpiles/workshop frames; furniture like bed/statue/table/chair; fixtures like anvil/cage/restraint/levers; barrel/bin/hatch/floodgate).
**Rationale**: CSV is easier to edit/diff. Editor tools reduce errors and help debug. Using common DF glyphs preserves player familiarity.
**Impact**: Designers can tune tiles/colors without code. Loader provides runtime parity. Future integration into the renderer is straightforward.

#EOF
## Template Entries (Remove after first real entry)

### [Date] - [Topic]
**Context**: [What situation prompted this decision/issue]
**Decision/Resolution**: [What was decided or how the issue was resolved]
**Rationale**: [Why this approach was chosen over alternatives]
**Impact**: [How this affects current and future development]

### [Date] - [Technical Decision]
**Context**: [Technical challenge or choice point]
**Decision/Resolution**: [Technical approach chosen]
**Rationale**: [Technical and business reasons for the choice]
**Impact**: [Effects on architecture, performance, maintainability]

---

*Keep entries concise but complete. Future developers (including yourself) should understand the context and reasoning behind decisions.*

#EOF

