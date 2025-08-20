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

