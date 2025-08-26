# Project Workflow Template

Customize this template for your specific project's tools, CI/CD, and development environment.

## Development Environment Setup

### Prerequisites:
- [ ] Language runtime installed (specify version)
- [ ] Package manager configured
- [ ] IDE/Editor configured with project settings
- [ ] Version control initialized

### Local Setup Commands:
```bash
# Example commands - customize for your project
# git clone <repository>
# cd <project>
# <install dependencies>
# <run initial setup>
# <run tests to verify setup>
```

## Daily Development Workflow

### Starting Work:
1. Pull latest changes from main branch
2. Check project/docs/ROADMAP.md for current priorities
3. Review project/docs/DEV_LOG.md for recent decisions
4. Run full test suite to ensure clean baseline
5. Create feature branch for work

### During Development:
1. Follow MCP/CLOSE_TO_SHORE.md workflow steps
2. Write tests first (TDD approach)
3. Implement minimal changes to pass tests
4. Run tests frequently (every 5-10 minutes)
5. Commit small, logical changes

### Completing Work:
1. Full test suite passes
2. Manual smoke test completed
3. Update project/docs/HOP_SUMMARIES.md
4. Update project/docs/DEV_LOG.md with decisions
5. Create pull request with clear description

## Build and Test Commands

### Local Development:
```bash
# Run all tests
godot --headless --path godot_project -s addons/gut/gut_cmdln.gd

# Run specific test suite
godot --headless --path godot_project -s addons/gut/gut_cmdln.gd -gtest tests/unit/
godot --headless --path godot_project -s addons/gut/gut_cmdln.gd -gtest tests/integration/

# Build application
godot --headless --export "Linux/X11" build/

# Run application locally
godot --path godot_project
```

### Debugging and Analysis Tools:
```bash
# Full project analysis (health check + linting + tests + docs)
python3 MCP/TOOLS/godot_tool_suite.py . --full-analysis

# Code quality analysis
python3 MCP/TOOLS/gdscript_linter.py ./godot_project/scripts --format text

# Automated testing with reporting
python3 MCP/TOOLS/godot_test_runner.py .

# Generate project documentation
python3 MCP/TOOLS/godot_doc_generator.py . --format markdown --output docs

# Tool health check
python3 MCP/TOOLS/godot_tool_suite.py . --health

# Continuous testing (watch mode)
python3 MCP/TOOLS/godot_test_runner.py . --continuous
```

### VS Code Tasks:
- Configure tasks.json for one-key testing
- Set up launch configurations for debugging
- Add file watchers for automatic test runs

### Godot Runtime Debugging:
```bash
# Start debug HTTP server in Godot (add to AutoLoad)
# Access debugging endpoints:
curl http://localhost:8080/scene          # Export scene tree
curl http://localhost:8080/global-state   # Export autoload states
curl http://localhost:8080/health         # Server health check
curl "http://localhost:8080/nodes/find?name=Player"  # Find nodes by name
curl "http://localhost:8080/nodes/find?type=TermElement"  # Find nodes by type
```

## CI/CD Pipeline

### Automated Checks:
- [ ] Lint and code style validation
- [ ] Full test suite execution
- [ ] Build verification
- [ ] Security scanning (if applicable)

### Deployment Process:
- [ ] Staging deployment for testing
- [ ] Manual validation in staging
- [ ] Production deployment process
- [ ] Rollback procedures

## Quality Gates

### Before Merge:
- All tests pass (verify with: `python3 MCP/TOOLS/godot_test_runner.py .`)
- Code review completed
- Documentation updated
- No critical lint errors (`python3 MCP/TOOLS/gdscript_linter.py ./godot_project/scripts --format text`)
- Scene inspection validates expected structure (use Scene Inspector or Debug HTTP Server)

### Before Release:
- Full regression testing
- Performance validation
- Security review (if applicable)
- Documentation up to date (`python3 MCP/TOOLS/godot_doc_generator.py . --format markdown`)
- Full project analysis passes (`python3 MCP/TOOLS/godot_tool_suite.py . --full-analysis`)

## Project-Specific Tools

### Development Tools:
- [x] GDScript Linter - Static code analysis for quality and best practices
- [x] Scene Inspector - Runtime scene tree export for "Scene Vision" debugging  
- [x] Debug HTTP Server - REST API for external debugging access
- [x] Test Runner - Automated GUT test execution with comprehensive reporting
- [x] Documentation Generator - Auto-generate docs from source code
- [x] Tool Suite Runner - Orchestrates all tools with single commands
- [x] Godot debugger configuration
- [ ] Profiling tools setup
- [ ] Database tools (Resource Databases integration)
- [x] API testing tools (HTTP endpoints for debugging)

### AI Agent Integration:
- [x] "Scene Vision" system - AI can inspect game state via JSON exports
- [x] External debugging access via HTTP API (localhost:8080)
- [x] Automated code quality analysis and reporting
- [x] Continuous testing with file watching
- [x] Documentation sync with codebase

### Monitoring and Logging:
- [x] Local logging configuration (LogBus autoload)
- [x] Error tracking setup (GDScript linter identifies issues)
- [x] Performance monitoring (Test runner tracks execution times)
- [x] Health check endpoints (Debug HTTP Server /health endpoint)
- [x] Scene state monitoring (Scene Inspector real-time exports)

## Troubleshooting

### Common Issues:
- [x] Environment setup problems - Use `python3 MCP/TOOLS/godot_tool_suite.py . --health`
- [x] Test failures and debugging - Use `python3 MCP/TOOLS/godot_test_runner.py .` for detailed reports
- [x] Build issues - Check linting with `python3 MCP/TOOLS/gdscript_linter.py ./godot_project/scripts`
- [x] Runtime problems - Use Debug HTTP Server for real-time scene inspection
- [x] Input handling issues - Scene Inspector can show input event flow
- [x] Node access errors - Linter identifies unvalidated node access patterns

### Debugging Workflow:
1. **Static Analysis**: Run linter to identify code quality issues
2. **Test Validation**: Run test suite to catch regressions  
3. **Runtime Inspection**: Use Scene Inspector or HTTP API for live debugging
4. **Performance Analysis**: Check test execution times and bottlenecks
5. **Documentation Sync**: Generate docs to ensure AI context is current

### Real-time Debugging:
```bash
# Start Godot with Debug HTTP Server enabled
# Then inspect game state externally:
curl http://localhost:8080/scene | jq .          # Pretty-print scene tree
curl http://localhost:8080/global-state | jq .   # Check autoload states
```

### Getting Help:
- Check project/docs/DEV_LOG.md for previous solutions
- Review project/docs/PROJECT_INDEX.md for system overview
- Consult team documentation or resources

#EOF
