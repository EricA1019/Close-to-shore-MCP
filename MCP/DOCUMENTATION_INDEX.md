# Documentation Index

This document provides a roadmap to all project documentation.

## Core Methodology
- **[CLOSE_TO_SHORE.md](CLOSE_TO_SHORE.md)** - Complete development methodology, principles, and workflows
- **[TOOLING_PHILOSOPHY.md](TOOLING_PHILOSOPHY.md)** - Tool selection strategy and development approach
- **[RUST_MIGRATION_PLAN.md](RUST_MIGRATION_PLAN.md)** - Detailed plan for migrating Python tools to Rust

## Technical Documentation
- **[GODOT_WORKFLOW.md](GODOT_WORKFLOW.md)** - Godot-specific development patterns
- **[TEST_POLICY.md](TEST_POLICY.md)** - Testing standards and practices
- **[PLUGINS.md](PLUGINS.md)** - Plugin management and integration
- **[STYLE_GUIDE.md](STYLE_GUIDE.md)** - Code formatting and style standards

## Tool Documentation
- **[rust/README.md](../rust/README.md)** - Rust tooling overview and usage (CTS)
- Python tool docs (legacy):
  - **[TOOLS/README.md](TOOLS/README.md)**
  - **[GODOT_TOOLS/](GODOT_TOOLS/)**
  - Note: Many Python tasks are superseded by CTS commands. Prefer CTS equivalents.

## Project Documentation
- **[../README.md](../README.md)** - Project overview and quick start
- **[../godot_project/docs/](../godot_project/docs/)** - Game-specific documentation
  - Architecture and design decisions
  - Asset specifications and workflows
  - Integration and success documentation

## Process Documentation
- **[AGENT_TEST_GUIDE.md](AGENT_TEST_GUIDE.md)** - Testing procedures for AI agents
- **[WORKFLOW_PROJECT.md](WORKFLOW_PROJECT.md)** - Project workflow specifics
- **[UPGRADE_CHECKLIST.md](UPGRADE_CHECKLIST.md)** - Version upgrade procedures

## Reference
- **[MCP_TEST_REGISTRY.md](MCP_TEST_REGISTRY.md)** - Test registry and tracking
- **[PROMPT_TEMPLATE.md](PROMPT_TEMPLATE.md)** - Standard prompt formats
- **[TAVILY_PROTOCOL.md](TAVILY_PROTOCOL.md)** - External research protocols
 - Local mirrors (for offline search via CTS):
   - Rust Book: `../docs/rust-book/` (index.html)
   - Godot Rust (GDext): `../godot_project/docs/GODOT_RUST_GDEXT/` (index.html)
   - GUT docs: `../godot_project/docs/GUT_DOCS/gut.readthedocs.io/`
   - Resource Databases wiki: `../godot_project/docs/ResourceDatabases/ResourceDatabases.wiki/`

### CTS Docs Commands
- Fetch/update mirrors: `cts docs fetch`
- List mirrors: `cts docs list`
- Search mirrors: `cts docs search <query>`

### Current Migration Status
- Phase 1: complete (`cts test`, `cts bundle`)
- Phase 2: in progress (`cts engine ensure|link`, `cts scene index|lint`)
- VS Code tasks updated to use CTS for engine management and scene tools.

## Quick Navigation

### For New Contributors
1. Start with [CLOSE_TO_SHORE.md](CLOSE_TO_SHORE.md) for methodology
2. Review [TOOLING_PHILOSOPHY.md](TOOLING_PHILOSOPHY.md) for tool approach
3. Check [rust/README.md](../rust/README.md) for tool usage
4. Read [TEST_POLICY.md](TEST_POLICY.md) for testing standards

### For Development
1. [GODOT_WORKFLOW.md](GODOT_WORKFLOW.md) - Godot development patterns
2. [STYLE_GUIDE.md](STYLE_GUIDE.md) - Code formatting
3. [AGENT_TEST_GUIDE.md](AGENT_TEST_GUIDE.md) - Testing procedures

### For Tooling Work
1. [RUST_MIGRATION_PLAN.md](RUST_MIGRATION_PLAN.md) - Migration strategy
2. [rust/README.md](../rust/README.md) - Current tool status
3. [TOOLING_PHILOSOPHY.md](TOOLING_PHILOSOPHY.md) - Design principles

## Living Documentation

All documentation is considered "living" - it should be updated as the project evolves. When making significant changes:

1. Update relevant documentation alongside code changes
2. Consider whether new patterns deserve documentation
3. Mark outdated sections for review or removal
4. Update this index when adding new documents

## Documentation Standards

- **Clear headings**: Use descriptive section headers
- **Working examples**: Include runnable code snippets where applicable
- **Decision context**: Explain why choices were made, not just what was chosen
- **Update dates**: Note when documents were last revised
- **Cross-references**: Link to related documentation
- **Actionable content**: Focus on what readers can do with the information
