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

---


## 2025-08-19

### Hop 1: Main Menu Restoration & Documentation Policy
**Context**: Main menu loaded but buttons were not wired; base scenes/scripts were empty; large research docs present locally
**Decision/Resolution**: Restored all base menu and options scenes/scripts, wired all main menu buttons to correct scenes, and updated documentation to clarify exclusion of large research docs (Godot, GUT, etc.) from git
**Rationale**: Ensures project boots, all menu flows work, and repo remains lean and focused on code/assets
**Impact**: Main menu now boots and all buttons work; documentation policy enforced; all tests pass headless

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

