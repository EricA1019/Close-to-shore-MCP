#!/bin/bash
# Deep Cleaner Wrapper Script
# Provides convenient commands for code cleanup operations

set -e

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLEANER_SCRIPT="$PROJECT_ROOT/MCP/TOOLS/deep_cleaner.py"
LOGS_DIR="$PROJECT_ROOT/logs"
CONFIG_FILE="$PROJECT_ROOT/MCP/TOOLS/deep_cleaner_config.json"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    if [[ ! -f "$CLEANER_SCRIPT" ]]; then
        print_error "Deep cleaner script not found: $CLEANER_SCRIPT"
        exit 1
    fi

    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
🧹 Deep Cleaner - Code Cleanup Tool

Usage: $0 <command> [options]

Commands:
  scan                 - Scan project for cleanup opportunities (dry-run)
  clean               - Apply all cleanup operations  
  clean-todos         - Remove TODO/FIXME/HACK comments
  clean-debug         - Remove debug print statements
  clean-legacy        - Flag legacy/deprecated code (review only)
  clean-empty         - Remove empty files and directories
  clean-interactive   - Interactive cleanup with confirmations
  report              - Generate cleanup report only
  help               - Show this help message

Options:
  --dry-run          - Show what would be changed without applying
  --force           - Skip confirmation prompts
  --categories CAT   - Only process specific categories (comments,debug,legacy,unused,formatting)
  --config FILE     - Use custom configuration file
  --report FILE     - Save report to specific file

Examples:
  $0 scan                           # Scan project (safe)
  $0 clean-todos --dry-run         # See what TODO cleanup would do
  $0 clean-debug                   # Remove debug statements
  $0 clean --categories comments,debug  # Clean specific categories
  $0 clean-interactive             # Interactive cleanup

Safety Features:
  - Dry-run mode by default for most operations
  - Automatic backups before changes
  - Git status checking
  - Interactive confirmations

Reports saved to: $LOGS_DIR/
Backups saved to: $PROJECT_ROOT/.cleanup_backups/

EOF
}

# Function to check git status
check_git_status() {
    if [[ -d "$PROJECT_ROOT/.git" ]]; then
        if ! git -C "$PROJECT_ROOT" diff-index --quiet HEAD --; then
            print_warning "You have uncommitted changes in git."
            if [[ "${FORCE:-false}" != "true" ]]; then
                read -p "Continue anyway? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    print_error "Cancelled by user"
                    exit 1
                fi
            fi
        fi
    fi
}

# Function to run cleaner with common options
run_cleaner() {
    local args=("$@")
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$LOGS_DIR/deep_clean_${timestamp}.json"
    
    # Add common options
    args+=("--project-root" "$PROJECT_ROOT")
    args+=("--report" "$report_file")
    
    print_status "Running deep cleaner..."
    print_status "Project: $PROJECT_ROOT"
    print_status "Report: $report_file"
    
    if python3 "$CLEANER_SCRIPT" "${args[@]}"; then
        print_success "Cleanup completed successfully"
        print_status "Report saved to: $report_file"
        
        # Show summary if report exists
        if [[ -f "$report_file" ]]; then
            echo
            print_status "Quick Summary:"
            python3 -c "
import json, sys
try:
    with open('$report_file') as f:
        data = json.load(f)
    summary = data.get('summary', {})
    print(f\"  Files scanned: {summary.get('files_scanned', 0)}\")
    print(f\"  Issues found: {summary.get('matches_found', 0)}\")
    print(f\"  Files modified: {summary.get('files_modified', 0)}\")
    print(f\"  Lines removed: {summary.get('lines_removed', 0)}\")
    print(f\"  Lines replaced: {summary.get('lines_replaced', 0)}\")
except Exception as e:
    print(f\"Could not parse report: {e}\")
"
        fi
    else
        print_error "Cleanup failed"
        exit 1
    fi
}

# Main command handling
main() {
    check_prerequisites
    
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        "scan")
            print_status "Scanning project for cleanup opportunities..."
            run_cleaner --dry-run "$@"
            ;;
        
        "clean")
            check_git_status
            print_warning "This will modify your code files!"
            if [[ "${FORCE:-false}" != "true" ]]; then
                read -p "Continue? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    print_error "Cancelled by user"
                    exit 1
                fi
            fi
            run_cleaner --apply "$@"
            ;;
        
        "clean-todos")
            print_status "Cleaning TODO/FIXME/HACK comments..."
            run_cleaner --apply --categories comments "$@"
            ;;
        
        "clean-debug")
            print_status "Cleaning debug statements..."
            run_cleaner --apply --categories debug "$@"
            ;;
        
        "clean-legacy")
            print_status "Flagging legacy/deprecated code for review..."
            run_cleaner --dry-run --categories legacy "$@"
            ;;
        
        "clean-empty")
            print_status "Cleaning empty files and directories..."
            run_cleaner --apply --clean-empty "$@"
            ;;
        
        "clean-interactive")
            check_git_status
            print_status "Starting interactive cleanup..."
            run_cleaner --apply --interactive "$@"
            ;;
        
        "report")
            print_status "Generating cleanup report..."
            run_cleaner --dry-run "$@"
            ;;
        
        "help"|"--help"|"-h")
            show_usage
            ;;
        
        *)
            print_error "Unknown command: $command"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Handle script options
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

main "$@"
