# Deep Cleaner Tool

A comprehensive code cleanup utility for removing deprecated code, TODOs, debug statements, and other technical debt from the BrokenDivinityDemo project.

## Features

- ✅ **Remove TODO/FIXME/HACK/BUG comments** - Clean up development markers
- ✅ **Clean debug print statements** - Remove debug prints in GDScript, Rust, and Python  
- ✅ **Flag legacy/deprecated code** - Identify outdated code sections for manual review
- ✅ **Detect unused variables** - Basic detection of potentially unused variables
- ✅ **Format cleanup** - Remove excessive empty lines and trailing whitespace
- ✅ **Empty file removal** - Clean up empty files and directories
- ✅ **Safety features** - Backups, dry-run mode, interactive confirmations

## Quick Start

### Using VS Code Tasks

1. **Scan project** (safe): `Ctrl+Shift+P` → "Tasks: Run Task" → "Clean: Deep Clean (dry-run)"
2. **Interactive cleanup**: `Ctrl+Shift+P` → "Tasks: Run Task" → "Clean: Interactive (Shell)"
3. **Remove TODOs only**: `Ctrl+Shift+P` → "Tasks: Run Task" → "Clean: Remove TODOs/FIXMEs"

### Using Shell Script

```bash
# Scan project for issues (safe)
./MCP/TOOLS/deep_clean.sh scan

# Interactive cleanup with confirmations
./MCP/TOOLS/deep_clean.sh clean-interactive

# Remove only TODO/FIXME comments  
./MCP/TOOLS/deep_clean.sh clean-todos

# Remove debug statements
./MCP/TOOLS/deep_clean.sh clean-debug

# Flag legacy code for review (dry-run only)
./MCP/TOOLS/deep_clean.sh clean-legacy

# Remove empty files and directories
./MCP/TOOLS/deep_clean.sh clean-empty
```

### Using Python Directly

```bash
# Basic scan
python3 MCP/TOOLS/deep_cleaner.py --project-root . --dry-run

# Clean specific categories
python3 MCP/TOOLS/deep_cleaner.py --project-root . --apply --categories comments debug

# Interactive mode
python3 MCP/TOOLS/deep_cleaner.py --project-root . --apply --interactive

# Generate report only
python3 MCP/TOOLS/deep_cleaner.py --project-root . --dry-run --report logs/cleanup_report.json
```

## Safety Features

### Automatic Backups
- All modified files are backed up to `.cleanup_backups/TIMESTAMP/`
- Original file structure is preserved
- Backups are created before any changes

### Dry-Run Mode (Default)
- Shows what would be changed without applying modifications
- Default behavior for safety
- Use `--apply` flag to actually make changes

### Git Integration
- Warns about uncommitted changes
- Checks git status before destructive operations
- Respects `.gitignore` patterns

### Exclusion Patterns
The following are automatically excluded from cleanup:
- `.git/`, `.vscode/`, `__pycache__/`
- `docs/GODOT_ENGINE_DOCS/`
- Third-party addons (`gut`, `gdLinter`, etc.)
- Binary files (images, archives, etc.)
- Generated files (`.import`, `Cargo.lock`)

## Categories

### Comments (`comments`)
- TODO/FIXME/HACK/BUG markers
- Development comments
- **Risk Level**: Low
- **Recommended**: Start here

### Debug (`debug`)  
- `print()` statements with "debug" 
- Rust `println!`, `dbg!` debug calls
- Python debug prints
- **Risk Level**: Medium
- **Recommended**: After review

### Legacy (`legacy`)
- Code marked as "legacy", "deprecated", "obsolete"
- Backward compatibility layers
- **Risk Level**: High  
- **Recommended**: Manual review only

### Unused (`unused`)
- Potentially unused variables (basic detection)
- **Risk Level**: High
- **Recommended**: Manual review only (many false positives)

### Formatting (`formatting`)
- Excessive empty lines
- Trailing whitespace  
- **Risk Level**: Low
- **Recommended**: Safe to apply

## Example Report

After running, check the generated report:

```json
{
  "timestamp": "2025-08-29T20:04:49",
  "summary": {
    "files_scanned": 636,
    "matches_found": 2281,
    "files_modified": 0,
    "lines_removed": 0,
    "lines_replaced": 0
  },
  "matches_by_category": {
    "comments": 23,
    "debug": 10, 
    "legacy": 39,
    "unused": 2209
  }
}
```

## Project Integration

### VS Code Tasks
All cleanup operations are available as VS Code tasks:
- Press `Ctrl+Shift+P`
- Type "Tasks: Run Task"  
- Select any "Clean:" task

### CI/CD Integration
Add to your CI pipeline:
```bash
# Check for TODO markers in CI
python3 MCP/TOOLS/deep_cleaner.py --project-root . --dry-run --categories comments --report ci_todos.json

# Fail build if TODOs found
if [ -s ci_todos.json ]; then echo "TODOs found, build failed"; exit 1; fi
```

### Git Hooks
Add as a pre-commit hook:
```bash
#!/bin/bash
# .git/hooks/pre-commit
./MCP/TOOLS/deep_clean.sh scan --categories debug
```

## Configuration

Customize cleanup rules in `MCP/TOOLS/deep_cleaner_config.json`:

```json
{
  "cleanup_rules": {
    "comments": {
      "enabled": true,
      "severity": "low"
    },
    "debug_statements": {
      "enabled": true, 
      "severity": "medium"
    }
  },
  "exclusions": {
    "directories": [".git/", "target/"],
    "file_patterns": ["\\.(png|jpg)$"]
  }
}
```

## Best Practices

### Recommended Workflow

1. **Start with scan**: Always run `scan` first to see what would be cleaned
2. **Review legacy items**: Manually check legacy code before removal
3. **Clean by category**: Start with low-risk categories (comments, formatting)
4. **Use interactive mode**: For first-time cleanup or uncertain changes
5. **Check git diff**: Review changes before committing

### Before Running Cleanup

- ✅ Commit current changes to git
- ✅ Run project tests to ensure everything works
- ✅ Review the scan results
- ✅ Start with dry-run mode

### After Running Cleanup

- ✅ Review git diff of changes
- ✅ Run tests to ensure nothing broke
- ✅ Commit cleanup changes separately
- ✅ Check backup files if needed

## Troubleshooting

### "No cleanup opportunities found"
- Check that you're in the project root
- Verify file extensions are supported (`.gd`, `.rs`, `.py`)
- Try different categories: `--categories comments debug legacy`

### "Permission denied" 
```bash
chmod +x MCP/TOOLS/deep_clean.sh
```

### False positives in unused variables
This is expected - the unused variable detection is basic pattern matching. Many matches in test files are normal (test setup variables). Use manual review for this category.

### Files not found
Ensure you're running from the project root directory:
```bash
cd /path/to/BrokenDivinityDemo
./MCP/TOOLS/deep_clean.sh scan
```

## Files Created

- `MCP/TOOLS/deep_cleaner.py` - Main cleanup tool
- `MCP/TOOLS/deep_clean.sh` - Shell script wrapper  
- `MCP/TOOLS/deep_cleaner_config.json` - Configuration file
- `.vscode/tasks.json` - Added VS Code tasks
- `logs/deep_clean_*.json` - Generated reports
- `.cleanup_backups/` - Backup directory (created when needed)

## Advanced Usage

### Custom Pattern Matching
Modify the `_create_cleanup_rules()` method in `deep_cleaner.py` to add custom patterns:

```python
CleanupRule(
    name="custom_pattern",
    pattern=r"your_regex_here",
    file_extensions=['.gd'],
    action="flag_manual",
    description="Your custom rule",
    category="custom"
)
```

### Batch Processing
Process multiple projects:
```bash
for project in project1 project2 project3; do
    cd "$project"
    python3 ../shared/deep_cleaner.py --project-root . --apply --categories comments
    cd ..
done
```

This deep cleaner is now integrated into your development workflow and ready to help maintain code quality across the entire BrokenDivinityDemo project!
