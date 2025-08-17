# Close-to-Shore MCP Prompt Templates

Structured prompts for working with LLMs in Close-to-Shore projects.

## Standard Project Context Prompt

Use this as a base context for all AI interactions:

```
You are working on a Close-to-Shore MCP project. Key constraints and principles:

WORKFLOW:
- Short hops, always green tests
- Test-first development (TDD)
- Data-driven, avoid hard-coding
- Verbose logging with bracketed tags: [System]

PROJECT STRUCTURE:
- Check project/docs/ for roadmap, dev log, and project index
- Follow MCP/STYLE_GUIDE.md for coding conventions
- Follow MCP/CLOSE_TO_SHORE.md for workflow steps
- Use MCP/TAVILY_PROTOCOL.md for clarification needs
- Reference MCP/TEST_POLICY.md for testing standards

DOCUMENTATION REQUIREMENTS:
- Always update project/docs/DEV_LOG.md with decisions
- Document completed hops in project/docs/HOP_SUMMARIES.md
- Keep project/docs/PROJECT_INDEX.md current with systems/scenes

STYLE:
- Functions ≤ 40 lines; split when growing
- Guard clauses; return early
- End files with #EOF comment
- No hard-coded paths; use safe fallbacks
```

## Hop Planning Prompt

For planning individual development hops:

```
Plan next development hop: [brief description]

PROCESS:
1. Check project/docs/ROADMAP.md for context and priorities
2. Review project/docs/PROJECT_INDEX.md for existing systems
3. Check project/docs/DEV_LOG.md for recent decisions
4. Write failing tests first (unit, integration, game-flow)
5. Implement minimal viable changes to pass tests
6. Ensure all tests pass and application boots successfully
7. Update documentation with decisions and outcomes

DELIVERABLES:
- Test suite (all green)
- Working feature demonstration
- Updated project/docs/DEV_LOG.md
- Updated project/docs/HOP_SUMMARIES.md
- Commit with clear message

Focus on smallest possible change that delivers value.
```

## Code Review Prompt

For reviewing code against MCP standards:

```
Review this code against MCP/STYLE_GUIDE.md and MCP/CLOSE_TO_SHORE.md:

CHECKLIST:
- [ ] Functions ≤ 40 lines?
- [ ] Proper logging tags [System] used?
- [ ] Guard clauses for early returns?
- [ ] No hard-coded paths or magic numbers?
- [ ] Tests cover public API?
- [ ] Data-driven approach used?
- [ ] Error handling appropriate (assert/warn/error)?
- [ ] File ends with #EOF comment?

ARCHITECTURE:
- [ ] Follows singleton/autoload patterns appropriately?
- [ ] Uses signals over direct lookups?
- [ ] Public API only exposed on components?

Provide specific suggestions for improvement.
```

## Debug Session Prompt

For troubleshooting and debugging:

```
Debug session for: [issue description]

CONTEXT GATHERING:
1. Check recent project/docs/DEV_LOG.md entries
2. Review project/docs/PROJECT_INDEX.md for affected systems
3. Examine test output and failure messages
4. Check application logs for [Tagged] messages

DEBUGGING APPROACH:
- Add verbose logging with appropriate [Tags]
- Write minimal test case to reproduce issue
- Use guard clauses to validate assumptions
- Check data flow and state changes
- Verify no hard-coded dependencies

RESOLUTION:
- Fix root cause, not symptoms
- Update tests to prevent regression
- Document solution in project/docs/DEV_LOG.md
- Verify all tests remain green
```

## Architecture Decision Prompt

For making architectural choices:

```
Architecture decision needed: [decision description]

EVALUATION CRITERIA:
- Supports data-driven approach?
- Enables easy testing?
- Follows MCP principles?
- Maintains separation of concerns?
- Allows for future extensibility?

RESEARCH:
- Check project/docs/PROJECT_INDEX.md for existing patterns
- Review project/docs/DEV_LOG.md for previous decisions
- Consider impact on current test suite
- Evaluate against MCP/STYLE_GUIDE.md

DOCUMENTATION:
- Document decision rationale in project/docs/DEV_LOG.md
- Update project/docs/PROJECT_INDEX.md if needed
- Consider updating MCP/ files if pattern is reusable

Make the simplest choice that meets requirements.
```

## Testing Strategy Prompt

For comprehensive testing approach:

```
Create testing strategy for: [feature description]

TESTING LAYERS (per MCP/TEST_POLICY.md):
1. Unit Tests: Component isolation, public API only
2. Integration Tests: Cross-system workflows
3. Smoke Tests: Boot paths and critical functionality
4. Game-Flow Tests: End-to-end user scenarios

TEST-FIRST APPROACH:
- Write failing tests before implementation
- Test public APIs, not private methods
- Use clear, descriptive test names
- Ensure tests fail for correct reasons

VALIDATION:
- All tests pass consistently
- No flaky or intermittent failures
- Fast execution (< 30 seconds total)
- Clean test data and teardown

Document test strategy in project/docs/DEV_LOG.md
```

#EOF
