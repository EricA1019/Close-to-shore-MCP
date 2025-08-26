#!/usr/bin/env python3
"""
GDScript Static Analysis Tool
Analyzes GDScript files for common issues and enforces best practices
"""

import os
import re
import sys
import json
from pathlib import Path
from typing import List, Dict, Any, Optional

class GDScriptIssue:
    def __init__(self, file_path: str, line_number: int, issue_type: str, message: str, severity: str = "warning"):
        self.file_path = file_path
        self.line_number = line_number
        self.issue_type = issue_type
        self.message = message
        self.severity = severity
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "file": self.file_path,
            "line": self.line_number,
            "type": self.issue_type,
            "message": self.message,
            "severity": self.severity
        }

class GDScriptLinter:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.issues: List[GDScriptIssue] = []
        
        # Patterns for common issues
        self.patterns = {
            "missing_type_hint": re.compile(r'^(\s*)var\s+(\w+)\s*='),
            "missing_return_type": re.compile(r'^(\s*)func\s+(\w+)\s*\([^)]*\)\s*:?\s*$'),
            "missing_param_type": re.compile(r'func\s+\w+\s*\(([^)]*)\)'),
            "unvalidated_node_access": re.compile(r'(\$\w+|\.\w+|get_node\([^)]+\))\.(?!is_valid)'),
            "magic_numbers": re.compile(r'\b\d+\.?\d*\b(?![eE])'),
            "unused_signal": re.compile(r'signal\s+(\w+)'),
            "hardcoded_paths": re.compile(r'"res://[^"]*"'),
        }
    
    def analyze_project(self) -> List[GDScriptIssue]:
        """Analyze all GDScript files in the project"""
        self.issues.clear()
        
        # Find all .gd files
        gd_files = list(self.project_root.rglob("*.gd"))
        
        print(f"Analyzing {len(gd_files)} GDScript files...")
        
        for gd_file in gd_files:
            self._analyze_file(gd_file)
        
        return self.issues
    
    def _analyze_file(self, file_path: Path) -> None:
        """Analyze a single GDScript file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            relative_path = str(file_path.relative_to(self.project_root))
            
            for line_num, line in enumerate(lines, 1):
                self._analyze_line(relative_path, line_num, line.strip())
                
        except Exception as e:
            print(f"Error analyzing {file_path}: {e}")
    
    def _analyze_line(self, file_path: str, line_num: int, line: str) -> None:
        """Analyze a single line of code"""
        # Skip comments and empty lines
        if not line or line.startswith('#'):
            return
        
        # Check for missing type hints
        if self.patterns["missing_type_hint"].match(line):
            if ':' not in line:  # No type hint
                self.issues.append(GDScriptIssue(
                    file_path, line_num, "missing_type_hint",
                    "Variable declaration without type hint", "warning"
                ))
        
        # Check for missing return types
        if self.patterns["missing_return_type"].match(line):
            if '->' not in line:  # No return type
                self.issues.append(GDScriptIssue(
                    file_path, line_num, "missing_return_type",
                    "Function declaration without return type", "warning"
                ))
        
        # Check for unvalidated node access
        if self.patterns["unvalidated_node_access"].search(line):
            if "is_valid" not in line and "is_instance_valid" not in line:
                self.issues.append(GDScriptIssue(
                    file_path, line_num, "unvalidated_node_access",
                    "Node access without validation - consider using is_instance_valid()", "error"
                ))
        
        # Check for magic numbers (excluding common ones)
        magic_numbers = self.patterns["magic_numbers"].findall(line)
        for number in magic_numbers:
            if number not in ['0', '1', '2', '10', '100', '0.0', '1.0']:
                self.issues.append(GDScriptIssue(
                    file_path, line_num, "magic_number",
                    f"Magic number '{number}' should be a named constant", "info"
                ))
    
    def generate_report(self, output_format: str = "json") -> str:
        """Generate a report of all issues found"""
        if output_format == "json":
            return json.dumps([issue.to_dict() for issue in self.issues], indent=2)
        
        elif output_format == "text":
            report = f"GDScript Analysis Report\n{'='*50}\n\n"
            
            # Group by severity
            by_severity = {"error": [], "warning": [], "info": []}
            for issue in self.issues:
                by_severity[issue.severity].append(issue)
            
            for severity, issues in by_severity.items():
                if issues:
                    report += f"{severity.upper()}S ({len(issues)}):\n"
                    for issue in issues:
                        report += f"  {issue.file_path}:{issue.line_number} - {issue.message}\n"
                    report += "\n"
            
            report += f"Total issues: {len(self.issues)}\n"
            return report
        
        else:
            raise ValueError(f"Unknown output format: {output_format}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python gdscript_linter.py <project_root> [--format json|text]")
        sys.exit(1)
    
    project_root = sys.argv[1]
    output_format = "json"
    
    if "--format" in sys.argv:
        format_index = sys.argv.index("--format") + 1
        if format_index < len(sys.argv):
            output_format = sys.argv[format_index]
    
    if not os.path.exists(project_root):
        print(f"Error: Project root '{project_root}' does not exist")
        sys.exit(1)
    
    linter = GDScriptLinter(project_root)
    issues = linter.analyze_project()
    
    # Generate and print report
    report = linter.generate_report(output_format)
    print(report)
    
    # Save to file
    output_file = "gdscript_analysis.json" if output_format == "json" else "gdscript_analysis.txt"
    with open(output_file, 'w') as f:
        f.write(report)
    
    print(f"\nReport saved to {output_file}")
    
    # Exit with error code if critical issues found
    critical_issues = [issue for issue in issues if issue.severity == "error"]
    if critical_issues:
        print(f"\n{len(critical_issues)} critical issues found!")
        sys.exit(1)

if __name__ == "__main__":
    main()
