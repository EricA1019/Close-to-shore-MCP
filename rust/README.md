# CTS (Close-to-Shore) Rust Tooling

A unified command-line tool replacing the MCP Python/shell tooling with fast, reliable Rust implementations.

## Quick Start

```bash
# Build the tool
cd rust
cargo build

# Run tests
./target/debug/cts test integration

# Build context bundle
./target/debug/cts bundle

# Get help
./target/debug/cts --help
./target/debug/cts test --help
./target/debug/cts bundle --help
```

## Phase 1 Commands (Implemented)

### `cts test`
Replaces `MCP/TOOLS/test_runner.sh` and `godot_test_runner.py`.

```bash
# Run all tests
cts test all

# Run specific test suites
cts test integration
cts test ui
cts test smoke
cts test e2e

# With custom timeout and Godot binary
cts test integration --timeout 120 --godot /path/to/godot

# JSON output for CI
cts test integration --json
```

Features:
- Auto-detects Godot binary from `.tools/godot/bin/godot`, `godot4`, or `godot` in PATH
- Configurable timeouts per suite
- Writes logs to `logs/run-<timestamp>-testrunner.out` 
- Creates JSON summary at `logs/run-<timestamp>-summary.json`
- Proper exit codes (0 = success, 1 = failures)

### `cts bundle`
Replaces `MCP/TOOLS/context_bundler.py`.

```bash
# Create context bundle
cts bundle

# Skip missing files instead of erroring
cts bundle --skip-missing

# Custom output location
cts bundle --output my-context.md

# Add additional source files
cts bundle --sources additional_doc.md --sources another_file.md

# JSON output
cts bundle --json
```

Features:
- Bundles key project documentation into a single Markdown file
- Default sources: AGENT_PROMPT.md, MCP/CLOSE_TO_SHORE.md, MCP/TEST_POLICY.md, MCP/GODOT_WORKFLOW.md, MCP/PLUGINS.md, README.md
- Graceful handling of missing files with `--skip-missing`
- Timestamped headers for traceability

## VS Code Integration

New tasks added to `.vscode/tasks.json`:
- **CTS: Build Context Bundle** - `cts bundle --skip-missing`
- **CTS: Test All** - `cts test all`
- **CTS: Test Integration** - `cts test integration`
- **CTS: Test UI** - `cts test ui`
- **CTS: Test Smoke** - `cts test smoke`

Access via `Ctrl+Shift+P` → "Tasks: Run Task" → select CTS task.

## Architecture

```
rust/
├── cts/           # Main CLI binary
├── cts-core/      # Shared utilities (fs, godot helpers)
└── cts-web/       # HTTP utilities (for future phases)
```

### Key Dependencies
- **clap**: CLI framework with subcommands
- **tokio**: Async runtime for concurrent operations
- **tracing**: Structured logging
- **serde**: JSON/YAML serialization
- **anyhow**: Error handling
- **chrono**: Timestamps

## Comparison with Python Tools

| Feature | Python | Rust CTS |
|---------|--------|----------|
| **Speed** | ~4-5s startup | ~500ms startup |
| **Dependencies** | Python 3 + modules | Single binary |
| **Error handling** | Basic exceptions | Rich context with anyhow |
| **Logging** | Print statements | Structured tracing |
| **JSON output** | Manual formatting | Type-safe serde |
| **Timeouts** | Shell-level | Proper async timeouts |
| **Parallel ops** | Limited | Built-in with rayon/tokio |

## Future Phases

Phase 2: `cts engine`, `cts plugin`, `cts scene`
Phase 3: `cts lint`, `cts doc`, `cts logs`  
Phase 4: `cts release`, `cts health`

## Development

```bash
# Run tests
cargo test

# Format code
cargo fmt

# Lint
cargo clippy

# Install locally
cargo install --path cts
```

## Troubleshooting

**Godot binary not found:**
```bash
# Specify manually
cts test --godot /path/to/godot

# Or ensure it's in PATH
export PATH="/path/to/godot/dir:$PATH"
```

**Permission errors:**
```bash
chmod +x ./rust/target/debug/cts
```

**Build errors:**
```bash
# Clean and rebuild
cargo clean
cargo build
```
