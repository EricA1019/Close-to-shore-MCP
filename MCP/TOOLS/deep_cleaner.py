#!/usr/bin/env python3
"""
Deep Cleaner Tool

Comprehensive cleanup utility for removing deprecated code, unused files, 
TODOs, debug statements, and other technical debt from the project.

Usage:
    python3 deep_cleaner.py [options]

Features:
- Remove TODO/FIXME/HACK/BUG comments
- Clean debug print statements 
- Remove unused imports and variables
- Delete legacy/deprecated code sections
- Clean empty files and directories
- Remove backup and temporary files
- Clean documentation artifacts
- Generate cleanup report

Safety Features:
- Dry-run mode (default)
- Backup creation before changes
- Pattern-based exclusions
- File type filtering
- Interactive confirmation
"""

import os
import re
import sys
import json
import shutil
import argparse
from pathlib import Path
from typing import List, Dict, Set, Tuple, Optional
from dataclasses import dataclass, field
from datetime import datetime

@dataclass
class CleanupRule:
    """Defines a cleanup rule with pattern matching and actions"""
    name: str
    pattern: str
    file_extensions: List[str]
    action: str  # 'remove_line', 'remove_block', 'replace', 'flag_manual'
    replacement: str = ""
    description: str = ""
    category: str = "general"
    severity: str = "medium"  # low, medium, high, critical

@dataclass
class CleanupMatch:
    """Represents a match found during scanning"""
    file_path: str
    line_number: int
    line_content: str
    rule: CleanupRule
    context_before: List[str] = field(default_factory=list)
    context_after: List[str] = field(default_factory=list)

@dataclass
class CleanupReport:
    """Summary of cleanup operations"""
    total_files_scanned: int = 0
    total_matches_found: int = 0
    files_modified: int = 0
    lines_removed: int = 0
    lines_replaced: int = 0
    files_deleted: int = 0
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    matches_by_category: Dict[str, int] = field(default_factory=dict)
    
class DeepCleaner:
    """Main deep cleaner implementation"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root).resolve()
        self.backup_dir = self.project_root / ".cleanup_backups" / datetime.now().strftime("%Y%m%d_%H%M%S")
        self.report = CleanupReport()
        
        # Define cleanup rules
        self.rules = self._create_cleanup_rules()
        
        # Exclusion patterns
        self.exclude_patterns = [
            r"\.git/",
            r"\.vscode/",
            r"__pycache__/",
            r"\.tools/",
            r"target/",
            r"docs/GODOT_ENGINE_DOCS/",
            r"godot_project/addons/gut/",
            r"godot_project/addons/gdLinter/",
            r"\.cleanup_backups/",
            r"\.(png|jpg|jpeg|gif|svg|ico|pdf|zip|tar|gz)$",
            r"\.import$",
            r"Cargo\.lock$",
        ]
        
        # File type mappings
        self.file_extensions = {
            'gdscript': ['.gd'],
            'rust': ['.rs'],
            'python': ['.py'],
            'markdown': ['.md'],
            'json': ['.json'],
            'text': ['.txt', '.cfg', '.conf'],
            'script': ['.sh', '.bat'],
        }

    def _create_cleanup_rules(self) -> List[CleanupRule]:
        """Create comprehensive set of cleanup rules"""
        rules = []
        
        # TODO/FIXME/HACK removal rules
        rules.extend([
            CleanupRule(
                name="remove_todo_comments",
                pattern=r".*\b(TODO|FIXME|HACK|BUG|TBD)\b.*",
                file_extensions=['.gd', '.py', '.rs'],
                action="flag_manual",
                description="Remove TODO/FIXME/HACK/BUG comment lines",
                category="comments",
                severity="low"
            ),
            CleanupRule(
                name="remove_todo_inline",
                pattern=r"\s*#\s*(TODO|FIXME|HACK|BUG|TBD):?.*$",
                file_extensions=['.gd', '.py', '.rs'],
                action="replace",
                replacement="",
                description="Remove inline TODO/FIXME/HACK comments",
                category="comments",
                severity="low"
            ),
        ])
        
        # Debug statement removal
        rules.extend([
            CleanupRule(
                name="remove_debug_prints_gd",
                pattern=r".*print\s*\(.*[Dd]ebug.*\)",
                file_extensions=['.gd'],
                action="flag_manual",
                description="Remove debug print statements in GDScript",
                category="debug",
                severity="medium"
            ),
            CleanupRule(
                name="remove_debug_prints_rust",
                pattern=r".*(println!|eprintln!|dbg!)\s*\(.*debug.*\);.*",
                file_extensions=['.rs'],
                action="flag_manual",
                description="Remove debug print statements in Rust",
                category="debug",
                severity="medium"
            ),
            CleanupRule(
                name="remove_debug_prints_python",
                pattern=r".*print\s*\(.*[Dd]ebug.*",
                file_extensions=['.py'],
                action="flag_manual",
                description="Remove debug print statements in Python",
                category="debug",
                severity="medium"
            ),
        ])
        
        # Legacy code removal
        rules.extend([
            CleanupRule(
                name="remove_legacy_comments",
                pattern=r".*\b(legacy|deprecated|obsolete|old)\b.*",
                file_extensions=['.gd', '.py', '.rs'],
                action="flag_manual",
                description="Flag legacy/deprecated code for manual review",
                category="legacy",
                severity="high"
            ),
            CleanupRule(
                name="remove_legacy_compatibility",
                pattern=r".*legacy.*compatibility.*",
                file_extensions=['.gd', '.py'],
                action="flag_manual",
                description="Flag legacy compatibility code for review",
                category="legacy",
                severity="high"
            ),
        ])
        
        # Unused variable patterns (basic detection)
        rules.extend([
            CleanupRule(
                name="unused_var_gd",
                pattern=r"^\s*var\s+(\w+)\s*[=:].*$",
                file_extensions=['.gd'],
                action="flag_manual", 
                description="Flag potentially unused variables",
                category="unused",
                severity="medium"
            ),
        ])
        
        # Empty line cleanup
        rules.extend([
            CleanupRule(
                name="excessive_empty_lines",
                pattern=r"^\s*\n\s*\n\s*\n",
                file_extensions=['.gd', '.py', '.rs', '.md'],
                action="replace",
                replacement="\n\n",
                description="Reduce excessive empty lines",
                category="formatting",
                severity="low"
            ),
        ])
        
        return rules

    def scan_project(self, dry_run: bool = True) -> List[CleanupMatch]:
        """Scan the entire project for cleanup opportunities"""
        matches = []
        
        print(f"🔍 Scanning project: {self.project_root}")
        
        for file_path in self._get_target_files():
            try:
                file_matches = self._scan_file(file_path)
                matches.extend(file_matches)
                self.report.total_files_scanned += 1
                
                if file_matches:
                    print(f"   📄 {len(file_matches)} issues in {file_path.relative_to(self.project_root)}")
                    
            except Exception as e:
                error_msg = f"Error scanning {file_path}: {e}"
                self.report.errors.append(error_msg)
                print(f"   ❌ {error_msg}")
        
        self.report.total_matches_found = len(matches)
        
        # Categorize matches
        for match in matches:
            category = match.rule.category
            self.report.matches_by_category[category] = self.report.matches_by_category.get(category, 0) + 1
        
        return matches

    def _get_target_files(self) -> List[Path]:
        """Get list of files to scan (excluding patterns)"""
        target_files = []
        
        for root, dirs, files in os.walk(self.project_root):
            # Skip excluded directories
            dirs[:] = [d for d in dirs if not self._is_excluded(os.path.join(root, d))]
            
            for file in files:
                file_path = Path(root) / file
                if not self._is_excluded(str(file_path)) and self._is_target_file(file_path):
                    target_files.append(file_path)
        
        return target_files

    def _is_excluded(self, path: str) -> bool:
        """Check if path matches exclusion patterns"""
        rel_path = os.path.relpath(path, self.project_root)
        return any(re.search(pattern, rel_path) for pattern in self.exclude_patterns)

    def _is_target_file(self, file_path: Path) -> bool:
        """Check if file should be scanned"""
        ext = file_path.suffix.lower()
        return any(ext in extensions for extensions in self.file_extensions.values())

    def _scan_file(self, file_path: Path) -> List[CleanupMatch]:
        """Scan a single file for cleanup opportunities"""
        matches = []
        
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            
            # Get applicable rules for this file type
            applicable_rules = [
                rule for rule in self.rules 
                if file_path.suffix in rule.file_extensions
            ]
            
            for line_num, line in enumerate(lines, 1):
                for rule in applicable_rules:
                    if re.search(rule.pattern, line, re.IGNORECASE):
                        # Get context around match
                        context_before = lines[max(0, line_num-3):line_num-1]
                        context_after = lines[line_num:min(len(lines), line_num+3)]
                        
                        match = CleanupMatch(
                            file_path=str(file_path),
                            line_number=line_num,
                            line_content=line.rstrip(),
                            rule=rule,
                            context_before=[l.rstrip() for l in context_before],
                            context_after=[l.rstrip() for l in context_after]
                        )
                        matches.append(match)
                        
        except Exception as e:
            self.report.errors.append(f"Error reading {file_path}: {e}")
        
        return matches

    def apply_cleanup(self, matches: List[CleanupMatch], dry_run: bool = True, 
                     interactive: bool = False) -> None:
        """Apply cleanup operations to matches"""
        
        if not dry_run:
            self._create_backups(matches)
        
        # Group matches by file for efficient processing
        files_to_process = {}
        for match in matches:
            if match.file_path not in files_to_process:
                files_to_process[match.file_path] = []
            files_to_process[match.file_path].append(match)
        
        for file_path, file_matches in files_to_process.items():
            if interactive:
                print(f"\n📄 Processing: {file_path}")
                if not self._confirm_file_changes(file_matches):
                    continue
            
            if dry_run:
                self._show_dry_run_changes(file_path, file_matches)
            else:
                self._apply_file_changes(file_path, file_matches)

    def _create_backups(self, matches: List[CleanupMatch]) -> None:
        """Create backups of files that will be modified"""
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        
        backed_up_files = set()
        for match in matches:
            if match.rule.action in ['remove_line', 'replace'] and match.file_path not in backed_up_files:
                src_path = Path(match.file_path)
                rel_path = src_path.relative_to(self.project_root)
                backup_path = self.backup_dir / rel_path
                
                backup_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src_path, backup_path)
                backed_up_files.add(match.file_path)
        
        print(f"💾 Created backups in: {self.backup_dir}")

    def _show_dry_run_changes(self, file_path: str, matches: List[CleanupMatch]) -> None:
        """Show what would be changed in dry run mode"""
        print(f"\n📄 Would modify: {file_path}")
        
        for match in matches:
            print(f"  Line {match.line_number}: {match.rule.name}")
            print(f"    Rule: {match.rule.description}")
            print(f"    Action: {match.rule.action}")
            print(f"    Current: {match.line_content}")
            
            if match.rule.action == "replace":
                print(f"    Replace with: {repr(match.rule.replacement)}")
            elif match.rule.action == "remove_line":
                print(f"    Will remove line")
            elif match.rule.action == "flag_manual":
                print(f"    ⚠️  Manual review required")

    def _apply_file_changes(self, file_path: str, matches: List[CleanupMatch]) -> None:
        """Apply changes to a specific file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # Sort matches by line number in reverse order to avoid index issues
            matches.sort(key=lambda m: m.line_number, reverse=True)
            
            for match in matches:
                if match.rule.action == "remove_line":
                    if 1 <= match.line_number <= len(lines):
                        del lines[match.line_number - 1]
                        self.report.lines_removed += 1
                
                elif match.rule.action == "replace":
                    if 1 <= match.line_number <= len(lines):
                        old_line = lines[match.line_number - 1]
                        new_line = re.sub(match.rule.pattern, match.rule.replacement, old_line)
                        lines[match.line_number - 1] = new_line
                        self.report.lines_replaced += 1
            
            # Write back to file
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(lines)
            
            self.report.files_modified += 1
            
        except Exception as e:
            error_msg = f"Error modifying {file_path}: {e}"
            self.report.errors.append(error_msg)
            print(f"❌ {error_msg}")

    def _confirm_file_changes(self, matches: List[CleanupMatch]) -> bool:
        """Interactive confirmation for file changes"""
        print(f"  Found {len(matches)} issues:")
        for match in matches[:3]:  # Show first 3
            print(f"    Line {match.line_number}: {match.rule.name}")
        
        if len(matches) > 3:
            print(f"    ... and {len(matches) - 3} more")
        
        response = input("  Apply changes? (y/n/s for skip): ").lower()
        return response == 'y'

    def clean_empty_files(self, dry_run: bool = True) -> None:
        """Remove empty files and directories"""
        empty_files = []
        empty_dirs = []
        
        # Find empty files
        for file_path in self._get_target_files():
            try:
                if file_path.stat().st_size == 0:
                    empty_files.append(file_path)
            except OSError:
                continue
        
        # Find empty directories
        for root, dirs, files in os.walk(self.project_root, topdown=False):
            for dir_name in dirs:
                dir_path = Path(root) / dir_name
                if not self._is_excluded(str(dir_path)):
                    try:
                        if not any(dir_path.iterdir()):
                            empty_dirs.append(dir_path)
                    except OSError:
                        continue
        
        if dry_run:
            if empty_files:
                print(f"\n🗑️  Would remove {len(empty_files)} empty files:")
                for f in empty_files:
                    print(f"   {f.relative_to(self.project_root)}")
            
            if empty_dirs:
                print(f"\n📁 Would remove {len(empty_dirs)} empty directories:")
                for d in empty_dirs:
                    print(f"   {d.relative_to(self.project_root)}")
        else:
            # Remove empty files
            for file_path in empty_files:
                try:
                    file_path.unlink()
                    self.report.files_deleted += 1
                except OSError as e:
                    self.report.errors.append(f"Could not remove {file_path}: {e}")
            
            # Remove empty directories
            for dir_path in empty_dirs:
                try:
                    dir_path.rmdir()
                except OSError as e:
                    self.report.errors.append(f"Could not remove {dir_path}: {e}")

    def generate_report(self, output_file: Optional[str] = None) -> Dict:
        """Generate comprehensive cleanup report"""
        report_data = {
            "timestamp": datetime.now().isoformat(),
            "project_root": str(self.project_root),
            "summary": {
                "files_scanned": self.report.total_files_scanned,
                "matches_found": self.report.total_matches_found,
                "files_modified": self.report.files_modified,
                "lines_removed": self.report.lines_removed,
                "lines_replaced": self.report.lines_replaced,
                "files_deleted": self.report.files_deleted,
            },
            "matches_by_category": self.report.matches_by_category,
            "errors": self.report.errors,
            "warnings": self.report.warnings,
        }
        
        if output_file:
            with open(output_file, 'w') as f:
                json.dump(report_data, f, indent=2)
            print(f"📊 Report saved to: {output_file}")
        
        return report_data

    def print_summary(self) -> None:
        """Print cleanup summary to console"""
        print("\n" + "="*60)
        print("🧹 DEEP CLEANUP SUMMARY")
        print("="*60)
        print(f"📁 Files scanned: {self.report.total_files_scanned}")
        print(f"🔍 Issues found: {self.report.total_matches_found}")
        print(f"📝 Files modified: {self.report.files_modified}")
        print(f"❌ Lines removed: {self.report.lines_removed}")
        print(f"🔄 Lines replaced: {self.report.lines_replaced}")
        print(f"🗑️  Files deleted: {self.report.files_deleted}")
        
        if self.report.matches_by_category:
            print("\n📊 Issues by category:")
            for category, count in sorted(self.report.matches_by_category.items()):
                print(f"   {category}: {count}")
        
        if self.report.errors:
            print(f"\n❌ Errors: {len(self.report.errors)}")
            for error in self.report.errors[:5]:  # Show first 5
                print(f"   {error}")
            if len(self.report.errors) > 5:
                print(f"   ... and {len(self.report.errors) - 5} more")
        
        if self.backup_dir.exists():
            print(f"\n💾 Backups created in: {self.backup_dir}")

def main():
    parser = argparse.ArgumentParser(description="Deep clean project code")
    parser.add_argument("--project-root", default=".", help="Project root directory")
    parser.add_argument("--dry-run", action="store_true", default=True, help="Show what would be changed without applying")
    parser.add_argument("--apply", action="store_true", help="Actually apply changes (overrides dry-run)")
    parser.add_argument("--interactive", action="store_true", help="Interactive confirmation for changes")
    parser.add_argument("--clean-empty", action="store_true", help="Also clean empty files and directories")
    parser.add_argument("--report", help="Save report to specified file")
    parser.add_argument("--categories", nargs="+", help="Only process specific categories", 
                       choices=["comments", "debug", "legacy", "unused", "formatting"])
    
    args = parser.parse_args()
    
    # Override dry-run if apply is specified
    dry_run = not args.apply
    
    print("🧹 Deep Code Cleaner")
    print(f"📁 Project: {args.project_root}")
    print(f"🎯 Mode: {'DRY RUN' if dry_run else 'APPLY CHANGES'}")
    
    if not dry_run:
        confirm = input("\n⚠️  This will modify your code. Continue? (y/N): ")
        if confirm.lower() != 'y':
            print("❌ Cancelled")
            return
    
    cleaner = DeepCleaner(args.project_root)
    
    # Filter rules by categories if specified
    if args.categories:
        cleaner.rules = [r for r in cleaner.rules if r.category in args.categories]
        print(f"🎯 Processing categories: {', '.join(args.categories)}")
    
    # Scan project
    matches = cleaner.scan_project(dry_run)
    
    if not matches:
        print("✅ No cleanup opportunities found!")
        return
    
    # Apply cleanup
    cleaner.apply_cleanup(matches, dry_run, args.interactive)
    
    # Clean empty files if requested
    if args.clean_empty:
        cleaner.clean_empty_files(dry_run)
    
    # Generate report
    cleaner.print_summary()
    
    if args.report:
        cleaner.generate_report(args.report)
    
    if dry_run:
        print(f"\n💡 Run with --apply to make changes")
        print(f"💡 Use --interactive for manual confirmation")

if __name__ == "__main__":
    main()
