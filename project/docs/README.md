# [Project Name]

Broken Divinity: New Babylon is a Godot 4.5-based ASCII roguelite prototype using the Maaack template, featuring a five-panel UI, data-driven content, and a bootable main menu. All menu buttons are wired to correct scenes. Large research documentation (Godot, GUT, etc.) is excluded from git and kept local only.

## Quick Start

### Documentation Policy
- All project documentation (specs, logs, roadmap, index, hop summaries) is versioned in git.
- Large research docs (Godot, GUT, plugin docs, etc.) are **never** committed or pushed; keep these local only.

### Prerequisites
- [List required software, versions, etc.]
- [Any system requirements]

### Setup
```bash
# Clone the repository
git clone https://github.com/EricA1019/Broken-Divinity-Demo.git
cd Broken-Divinity-Demo

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
- Short hops with always-green tests
- Test-first development (TDD)
- Data-driven architecture
- Comprehensive documentation

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

See `project/docs/PROJECT_INDEX.md` for system overview and hop status.

- **ROADMAP.md**: High-level project plan and milestones
- **DEV_LOG.md**: Development decisions and issue resolutions
- **HOP_SUMMARIES.md**: Completed development hop summaries
- **PROJECT_INDEX.md**: Current systems and architecture overview

## Contributing

1. Follow the Close-to-Shore MCP methodology in `MCP/`
2. Update documentation with all changes
3. Ensure all tests pass before committing
4. Use provided tools for validation

## Architecture

[Brief overview of the main architectural decisions and patterns used]

## License

[License information]

---

*This project uses Close-to-Shore MCP methodology for sustainable, test-driven development.*

#EOF
