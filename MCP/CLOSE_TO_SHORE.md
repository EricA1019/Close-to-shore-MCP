# Close-to-Shore MCP (System-Agnostic)

Short hops, loud logs, data-driven content, always-green tests.

## Philosophy: Stability Through Investment

Close-to-Shore (CTS) embodies the principle of **investing effort early for long-term stability and scalability**. We choose tools and patterns that may require more upfront work but pay dividends in reliability, maintainability, and developer experience.

### Core Values
- **Stability over speed**: Choose robust foundations even if they take longer to set up
- **Scalability over simplicity**: Design for growth from day one
- **Documentation over assumptions**: Every decision should be traceable and teachable
- **Tests over trust**: Verify behavior at every level, never assume it works
- **Tools over toil**: Invest in automation and tooling to reduce manual work

### The CTS Investment Mindset
We deliberately choose more work upfront when it leads to:
- **Fewer production bugs** through strong typing and comprehensive testing
- **Faster iteration cycles** through reliable automation and quick feedback
- **Better onboarding** through comprehensive documentation and examples
- **Easier debugging** through structured logging and clear error messages
- **Reduced maintenance burden** through self-documenting code and robust tooling

## 0) Core Principles
- **Short hops**: tiny, runnable vertical slices that can be completed and validated quickly
- **Always green**: tests pass and the program boots without errors at all times
- **Data-driven first**: content lives in data files (JSON/DB/resources); systems discover content
- **Avoid hard-coding**: prefer tables/registries over branches and magic numbers
- **Auto-populated UI**: containers spawn controls based on data/state, not manual wiring
- **Traceable logs**: tagged, structured logs; never silently fail
- **Test everything**: unit, integration, smoke, and end-to-end tests at appropriate levels
- **Document decisions**: capture why, not just what, in living documentation
- **Privacy by design**: no accessing private members (`_prefixed`) across module boundaries

## Definition of Done (per hop)
1) Unit + integration + smoke + game-flow tests green
2) Data schemas validated (JSON or DB migrations applied)
3) App boots and demonstrates the hop feature
4) Player test completed and documented
5) Logs clean of unexpected warnings/errors
6) No hard-wired paths (safe fallbacks allowed)
7) Commit + tag; docs updated

## Workflow (6 steps)
1) Planning & Setup: read project/docs/ROADMAP.md, set scope, baseline tests, boot validation
2) Test-First: write failing tests (unit/integration/game-flow), author schemas
3) Implement: iterate to green, run often
4) Integrate & Validate: full suite, schema checks, manual boot
5) Player Validation: ask human to play; document feedback in project/docs/DEV_LOG.md
6) Docs & Completion: update project docs, tag, propose improvements

## Documentation Requirements
Every project must have:
- project/docs/ROADMAP.md: high-level checklist of planned hops
- project/docs/DEV_LOG.md: chronological decisions and issues
- project/docs/HOP_SUMMARIES.md: brief summary of each completed hop
- project/docs/README.md: project overview and setup
- project/docs/PROJECT_INDEX.md: living index of systems, scenes, data, tests

## Agent Protocol
1) Always check project/docs/ folder before starting any work
2) Follow MCP workflows and protocols unless ambiguous
3) Use TAVILY_PROTOCOL.md for clarification needs
4) Document every hop in project/docs/HOP_SUMMARIES.md
5) Update project/docs/DEV_LOG.md with decisions and issues

## Tool Selection Strategy

### Rust for Stability & Performance
Use Rust when:
- **Long-term reliability** is critical (tooling, CI/CD, core libraries)
- **Performance** matters (hot paths, concurrent operations, large data processing)
- **Cross-platform** deployment is needed (single binary distribution)
- **Strong typing** helps prevent bugs (parsers, data validation, APIs)
- **Concurrent operations** are required (parallel testing, downloads, processing)

Examples: `cts` CLI tooling, GDExtensions for compute-heavy operations, system utilities

### Python for Rapid Prototyping
Use Python when:
- **Quick iteration** is more valuable than long-term maintenance
- **Exploratory work** where requirements are unclear
- **One-off scripts** that won't be run frequently
- **Godot integration** where GDScript is already the primary language
- **Data analysis** and visualization tasks

Examples: Experiment scripts, data migration helpers, analysis notebooks

### GDScript for Game Logic
Use GDScript when:
- **Scene tree integration** is required (Nodes, signals, lifecycle)
- **Designer iteration** speed is critical (gameplay, UI, content)
- **Godot-native features** are primary (animations, physics, resources)
- **Rapid prototyping** of game mechanics

Keep GDScript for orchestration; call Rust for heavy computation.

## Code Hygiene & Best Practices

### Universal Standards
- **No peeking at privates**: Never access `_prefixed` members across module/class boundaries
- **Fail fast and loud**: Use assertions, proper error types, and structured logging
- **Test-driven development**: Write failing tests first, then implement to green
- **Documentation as code**: README, docstrings, and inline comments are first-class citizens
- **Version everything**: Dependencies, tools, data schemas, APIs
- **Reproducible builds**: Lock files, container definitions, explicit tool versions

### Rust-Specific Practices
- **Strong error handling**: Use `Result<T, E>` and `anyhow`/`thiserror` for context
- **Structured logging**: Use `tracing` for hierarchical, filterable logs
- **Type-driven design**: Let the type system guide API design and catch bugs
- **Integration tests**: Test public APIs, not implementation details
- **Cargo workspace**: Organize related crates for code reuse and faster builds

### Python-Specific Practices  
- **Type hints**: Use `typing` annotations for documentation and tooling
- **Virtual environments**: Isolate dependencies per project
- **Linting**: Use `black`, `isort`, `mypy` for consistent formatting and type checking
- **Testing**: `pytest` with fixtures and parameterized tests
- **Keep it simple**: Favor readable code over clever optimizations

### GDScript-Specific Practices
- **Typed GDScript**: Use `class_name`, typed variables, and function signatures
- **Resource-driven**: Store data in `.tres` files, not hardcoded in scripts
- **Signal-based communication**: Prefer signals over direct references for decoupling
- **Scene composition**: Build complex scenes from simple, reusable components
- **Tool scripts**: Use `@tool` for editor helpers and validation

## Testing Philosophy

### Test Pyramid
1. **Unit tests** (70%): Fast, isolated, test single functions/classes
2. **Integration tests** (20%): Test component interactions and data flow  
3. **End-to-end tests** (10%): Test complete user workflows and system behavior

### Testing Levels by Language

#### Rust Testing
- **Unit tests**: `#[cfg(test)]` modules testing public APIs
- **Integration tests**: `tests/` directory testing crate interfaces
- **Property tests**: `proptest` for generating test cases
- **Benchmarks**: `criterion` for performance regression detection
- **Documentation tests**: Executable examples in docstrings

#### Python Testing
- **Unit tests**: `pytest` with fixtures and mocking
- **Integration tests**: Test module interactions and file I/O
- **Contract tests**: Verify API schemas and data formats
- **Smoke tests**: Quick validation that systems are working

#### GDScript Testing
- **GUT unit tests**: Test individual class methods and state changes
- **Integration tests**: Test scene loading, signal connections, resource handling
- **Smoke tests**: Load scenes and verify no errors
- **Manual tests**: Designer validation of gameplay and UI

### Test-Driven Workflow
1. **Red**: Write a failing test that describes desired behavior
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve code while keeping tests green
4. **Document**: Update documentation to reflect new behavior

## Documentation Standards

### Living Documentation
- **README.md**: Project overview, setup, and basic usage
- **CHANGELOG.md**: Chronological record of changes and decisions
- **API.md**: Public interfaces and usage examples
- **ARCHITECTURE.md**: System design and component relationships
- **CONTRIBUTING.md**: Development setup and contribution guidelines

### Code Documentation
- **Public APIs**: Comprehensive docstrings with examples
- **Complex algorithms**: Inline comments explaining the "why"
- **Configuration**: Document all settings and their effects
- **Error conditions**: Document when and why failures occur

### Decision Records
- **Why we chose Rust**: Performance, safety, and ecosystem benefits
- **Why we chose specific crates**: Trade-offs and alternatives considered
- **Architecture decisions**: Diagrams and rationale for system design
- **Failed experiments**: What we tried and why it didn't work

## MCP Tools & Ecosystem

### Rust Tooling (`cts` CLI)
- **cts test**: Unified test runner for all test types (GUT, smoke, integration)
- **cts bundle**: Documentation bundler for MCP context
- **cts engine**: Godot version management and binary linking
- **cts scene**: Scene validation and indexing
- **cts lint**: Code quality checks (API guard, GDScript analysis)
- **cts doc**: Documentation generation and synchronization
- **cts logs**: Log aggregation and analysis
- **cts release**: Release automation and changelog generation
- **cts health**: Project health dashboard and validation

### Development Environment
- **VS Code**: Primary editor with integrated tasks and debugging
- **Godot Engine**: Game engine with headless testing support
- **Git**: Version control with conventional commits
- **Cargo**: Rust package manager and build system
- **GUT**: Godot unit testing framework
- **Pytest**: Python testing framework for utilities

### CI/CD Pipeline
- **GitHub Actions**: Automated testing and builds
- **Rust binary distribution**: Cross-platform releases
- **Test reporting**: JUnit XML and JSON outputs
- **Documentation deployment**: Automated docs updates
- **Performance monitoring**: Benchmark tracking and alerts

## Implementation Notes (Tools)
- Use the "CTS: Build Context Bundle" task before tests; it generates `.mcp_context/context_bundle.md` to ensure the agent has all prompts/protocols.
- Test runs export RUN_ID; Godot logs to `user://logs/run-<RUN_ID>.log` with level-tagged lines. The test runner also tees to `logs/run-<RUN_ID>-testrunner.out` in the repo.
- **Rust tooling**: Use `cts` CLI for all automation (faster, more reliable than Python scripts)
- **Structured logging**: All tools output JSON for machine parsing and human-readable for development
- **Performance tracking**: Benchmark critical paths and track regressions over time

## Lessons Learned

### From Python to Rust Migration
- **Investment pays off**: Initial Rust setup took longer, but tools are now 100x faster and more reliable
- **Error handling matters**: Proper error types and context make debugging much easier
- **Single binary distribution**: Eliminates "works on my machine" Python environment issues
- **Structured logging**: Tracing provides much better debugging information than print statements
- **Type safety catches bugs**: Many runtime errors became compile-time errors

### Testing Insights
- **Test isolation**: Each test should be completely independent and deterministic
- **Golden file testing**: Store expected outputs and compare for regression detection
- **Performance testing**: Track execution time to catch performance regressions early
- **Smoke testing**: Quick validation that basic functionality works before deeper testing

### Documentation Learnings
- **Document decisions, not just code**: Future developers need to understand "why"
- **Living documentation**: Keep docs close to code and update them together
- **Examples over explanations**: Show working code rather than describing it
- **Searchable logs**: Structured logging makes finding issues much faster

### Development Workflow
- **Small commits**: Make it easy to bisect and understand changes
- **Always-green main**: Never commit broken code to the main branch
- **Automated validation**: CI should catch what humans forget to check
- **Fast feedback loops**: Optimize for quick iteration cycles

## ## Quick checklist per hop:
- [ ] Generate context bundle (`cts bundle`)
- [ ] Run tests via runner (`cts test all` or `cts test integration`)
- [ ] Inspect logs (repo tail + Godot user log)
- [ ] Validate code quality (`cts lint`, `cts health`)
- [ ] Update docs (README/CHANGELOG/HOP_SUMMARIES)
- [ ] Performance check (compare execution times)
- [ ] Commit + tag with descriptive message
- [ ] Document lessons learned and decisions made

## Evolution & Continuous Improvement

This document evolves as we learn. Key areas for ongoing refinement:

### Process Improvements
- **Automation opportunities**: What manual steps can be eliminated?
- **Feedback loops**: How can we get faster validation of changes?
- **Knowledge transfer**: How do we onboard new contributors effectively?
- **Tool ergonomics**: What friction points slow down development?

### Technical Debt Management
- **Regular refactoring**: Schedule time to improve code quality
- **Dependency updates**: Keep tools and libraries current
- **Performance monitoring**: Track and address performance regressions
- **Security reviews**: Regular audits of dependencies and practices

### Learning Culture
- **Post-mortem reviews**: Learn from both successes and failures
- **Experimentation**: Try new tools and approaches in controlled settings
- **Knowledge sharing**: Document and share insights across the team
- **External learning**: Stay current with industry best practices

Living document — refine as habits evolve.

#EOF
