# [Project Name]

[Brief description of what this project does and why it exists]

## Quick Start

### Prerequisites
- [List required software, versions, etc.]
- [Any system requirements]

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
