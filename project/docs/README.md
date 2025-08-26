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
# Broken Divinity: New Babylon — Demo

Godot 4.5-based prototype using Maaack template, ASCII grid rendering, and a five-panel UI. This demo showcases the boot flow, restored menus, and data-driven UI. All scenes and scripts are now functional and pass headless/editor tests.
├── data/           # Game data, configurations, schemas
├── tests/          # Test suites (unit, integration, smoke, game-flow)
├── src/            # Source code
└── [other folders]
 
- Godot Engine 4.5 beta 5 (Linux, Windows, Mac)
- Python 3.10+ (for test runner)
├── CLOSE_TO_SHORE.md
├── STYLE_GUIDE.md
├── TEST_POLICY.md
└── TOOLS/
git clone https://github.com/EricA1019/Broken-Divinity-Demo.git

cd Broken-Divinity-Demo/godot_project
## Development Workflow

This project follows the **Close-to-Shore MCP** methodology:
- Short hops with always-green tests
- Test-first development (TDD)
# Run tests (headless)
GODOT_BIN=/path/to/Godot_v4.5-beta5_linux.x86_64
$GODOT_BIN --headless --path . --quit --verbose
- Comprehensive documentation

# Start the application (editor)
$GODOT_BIN --editor --path .
1. Read `project/docs/ROADMAP.md` for current priorities
2. Check `project/docs/DEV_LOG.md` for recent decisions
3. Review `project/docs/PROJECT_INDEX.md` for system overview
 
See `project/docs/PROJECT_INDEX.md` for system overview and `project/docs/DEMO_SPEC.md` for UI/flow details.
3. Implement minimal changes to pass tests
4. Update documentation
5. Validate with `MCP/TOOLS/hop_validator.py`

## Testing

```bash
# Run all tests
./MCP/TOOLS/test_runner.sh all

# Run specific test suites
[unit test command]
[integration test command]
[smoke test command]
[game-flow test command]

# Use provided test runner
./MCP/TOOLS/test_runner.sh integration
```

## Documentation

- **ROADMAP.md**: High-level project plan and milestones
- **DEV_LOG.md**: Development decisions and issue resolutions
- **HOP_SUMMARIES.md**: Completed development hop summaries
- **PROJECT_INDEX.md**: Current systems and architecture overview
- MCP: Use the VS Code task “CTS: Build Context Bundle” to generate `.mcp_context/context_bundle.md` before running tests. Logs are written to `logs/run-<RUN_ID>-testrunner.out` (repo) and `user://logs/run-<RUN_ID>.log` (Godot).

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
