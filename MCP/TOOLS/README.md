# Godot Development Tools Suite

A comprehensive set of debugging and development tools designed to improve AI agent workflow with Godot projects.

## Doc Updater (doc_updater.py)

A rule-based Markdown updater to keep docs consistent with current terminology and our checklist format.

- Dry-run by default; add `--write` to apply changes
- Applies safe replacements outside code fences
- Rules available:
   - `std-http`: Replace "Python stdlib HTTP server" with "Python stdlib HTTP server"
   - `resource-db`: Prefer Resource Database (.tres/.res) phrasing over Resource Database (.tres/.res) wording
   - `cts-checklists`: Ensure a `### Checklist` section exists under CTS doc sections

Examples

```bash
# Preview changes across Markdown files (dry-run)
python3 MCP/TOOLS/doc_updater.py --include "**/*.md" --exclude "godot_project/addons/**"

# Apply specific rules repo-wide
python3 MCP/TOOLS/doc_updater.py --rules std-http resource-db --write

# Update specific files
python3 MCP/TOOLS/doc_updater.py --files rust/README.md godot_project/docs/RESOURCE_DB.md --write --verbose
```

## Overview

This tool suite provides "Scene Vision" capabilities for AI agents working with Godot, allowing them to inspect, analyze, and debug game state in real-time.

## Tools Included

### 1. GDScript Linter (`gdscript_linter.py`)
**Purpose:** Static analysis of GDScript files for common issues and best practices.

**Features:**
- Missing type hints detection
- Unvalidated node access warnings
- Magic number identification
- Missing return type annotations
- JSON and text output formats

**Usage:**
```bash
python3 gdscript_linter.py /path/to/project --format json
```

### 2. Test Runner (`godot_test_runner.py`)
**Purpose:** Automated GUT test execution and reporting.

**Features:**
- Automated test discovery
- Comprehensive test reporting
- Continuous testing mode (with watchdog)
- JSON and text output formats
- Test duration tracking

**Usage:**
```bash
python3 godot_test_runner.py /path/to/project
python3 godot_test_runner.py /path/to/project --continuous
```

### 3. Documentation Generator (`godot_doc_generator.py`)
**Purpose:** Automatic documentation generation from GDScript source code.

**Features:**
- Class documentation extraction
- Method and property documentation
- Signal and enum documentation
- Markdown and JSON output
- Scene file cataloging

**Usage:**
```bash
python3 godot_doc_generator.py /path/to/project --format markdown --output docs
python3 godot_doc_generator.py /path/to/project --format json
```

### 4. Scene Inspector (`scene_inspector.gd`)
**Purpose:** Runtime scene tree inspection and state export.

**Features:**
- Recursive scene tree export
- Global state inspection
- Node search by name/type
- JSON serialization for AI consumption

**Usage:** Include in Godot project and call methods programmatically.

### 5. Debug HTTP Server (`debug_http_server.gd`)
**Purpose:** HTTP API for external access to debugging tools.

**Features:**
- REST API endpoints
- Scene tree export via HTTP
- Global state inspection
- Node search capabilities
- Health check endpoint

**Endpoints:**
- `GET /scene` - Export scene tree
- `GET /global-state` - Export global state
- `GET /nodes/find?name=NodeName` - Find nodes by name
- `GET /nodes/find?type=NodeType` - Find nodes by type
- `GET /health` - Health check

### 6. Tool Suite Runner (`godot_tool_suite.py`)
**Purpose:** Main orchestrator for all tools.

**Features:**
- Run individual tools
- Full project analysis
- Health checks
- Tool setup and configuration
- Comprehensive reporting

**Usage:**
```bash
python3 godot_tool_suite.py /path/to/project --full-analysis
python3 godot_tool_suite.py /path/to/project --tool lint --tool-args --format json
python3 godot_tool_suite.py /path/to/project --setup
```

## Installation

1. Copy all tool files to your project's `MCP/TOOLS/` directory
2. Run setup to create convenience scripts:
   ```bash
   python3 godot_tool_suite.py /path/to/project --setup
   ```

## Dependencies

**Required:**
- Python 3.7+
- Godot 4.3+
- GUT testing framework (for test runner)

**Optional:**
- `watchdog` package for continuous testing: `pip install watchdog`

## Integration with AI Agents

These tools are specifically designed for AI agent workflows:

### Scene Vision System
The Scene Inspector and Debug HTTP Server provide "Scene Vision" - the ability for AI agents to see and understand the current state of a Godot game:

```python
# Example: AI agent inspecting scene state
import requests
scene_data = requests.get("http://localhost:8080/scene").json()
# AI can now analyze the scene tree, node properties, etc.
```

### Automated Analysis
The tool suite can be integrated into AI workflows for continuous analysis:

```bash
# Run full analysis and get exit code for CI/CD
python3 godot_tool_suite.py . --full-analysis
echo $?  # 0 = success, 1 = issues found
```

### Documentation for Context
Auto-generated documentation provides AI agents with up-to-date context about the codebase:

```bash
python3 godot_doc_generator.py . --format json
# Creates project_docs.json with complete class/method documentation
```

## Workflow Examples

### 1. Daily Development Check
```bash
./MCP/TOOLS/run_analysis.sh
```

### 2. Pre-Commit Validation
```bash
python3 MCP/TOOLS/gdscript_linter.py . --format text
python3 MCP/TOOLS/godot_test_runner.py .
```

### 3. Documentation Update
```bash
python3 MCP/TOOLS/godot_doc_generator.py . --format markdown --output docs
```

### 4. Continuous Testing During Development
```bash
python3 MCP/TOOLS/godot_test_runner.py . --continuous
```

## Output Files

The tools generate several output files for analysis:

- `gdscript_analysis.json` - Linting results
- `test_report.json` - Test execution results
- `project_docs.json` - Project documentation
- `project_analysis_report.json` - Comprehensive analysis report
- `docs/` - Markdown documentation directory

## Troubleshooting

### Tool Health Check
```bash
python3 godot_tool_suite.py /path/to/project --health
```

### Common Issues

1. **GDScript tools not working:** Ensure the scripts are added to your Godot project and AutoLoad is configured if needed.

2. **Test runner fails:** Verify GUT is installed and configured in your project.

3. **Permission errors:** Make sure shell scripts are executable:
   ```bash
   chmod +x MCP/TOOLS/*.sh
   ```

## Extending the Tools

Each tool is modular and can be extended:

1. **Add new linting rules:** Modify patterns in `gdscript_linter.py`
2. **Custom test reporting:** Extend the `TestResult` class
3. **Additional documentation:** Add parsers in `godot_doc_generator.py`
4. **New debug endpoints:** Add routes to `debug_http_server.gd`

## Best Practices

1. **Run tools regularly:** Integrate into your development workflow
2. **Use continuous testing:** Catch issues early with watch mode
3. **Document as you go:** Keep documentation comments up to date
4. **Monitor critical issues:** Address linting errors promptly
5. **Validate with AI:** Use the Scene Vision system to verify game state

## Contributing

When adding new tools:

1. Follow the established patterns
2. Add comprehensive error handling
3. Support both JSON and text output
4. Include in the main tool suite runner
5. Update this documentation

## License

These tools are part of the BrokenDivinityDemo project and follow the same licensing terms.
