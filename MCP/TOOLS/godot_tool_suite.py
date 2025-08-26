#!/usr/bin/env python3
"""
Godot Development Tools Suite
Main runner for all Godot development and debugging tools
"""

import os
import sys
import json
import argparse
import subprocess
from pathlib import Path
from typing import Dict, List, Any, Optional

class GodotToolSuite:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.tools_dir = self.project_root / "MCP" / "TOOLS"
        
        # Ensure tools directory exists
        self.tools_dir.mkdir(parents=True, exist_ok=True)
        
        # Available tools
        self.tools = {
            "lint": {
                "script": "gdscript_linter.py",
                "description": "Analyze GDScript files for common issues",
                "args": ["--format"]
            },
            "test": {
                "script": "godot_test_runner.py",
                "description": "Run GUT tests and generate reports",
                "args": ["--continuous", "--godot-path"]
            },
            "docs": {
                "script": "godot_doc_generator.py",
                "description": "Generate project documentation",
                "args": ["--format", "--output"]
            },
            "inspect": {
                "script": "scene_inspector.gd",
                "description": "Runtime scene inspection (GDScript tool)",
                "args": []
            },
            "debug-server": {
                "script": "debug_http_server.gd",
                "description": "HTTP debug server (GDScript tool)",
                "args": []
            }
        }
    
    def run_tool(self, tool_name: str, args: Optional[List[str]] = None) -> bool:
        """Run a specific tool"""
        if tool_name not in self.tools:
            print(f"Unknown tool: {tool_name}")
            print(f"Available tools: {', '.join(self.tools.keys())}")
            return False
        
        tool_info = self.tools[tool_name]
        script_path = self.tools_dir / tool_info["script"]
        
        if not script_path.exists():
            print(f"Tool script not found: {script_path}")
            return False
        
        # Build command
        if script_path.suffix == ".py":
            cmd = ["python3", str(script_path), str(self.project_root)]
        else:
            print(f"GDScript tools must be run within Godot")
            return False
        
        if args:
            cmd.extend(args)
        
        try:
            print(f"Running: {' '.join(cmd)}")
            result = subprocess.run(cmd, cwd=self.project_root)
            return result.returncode == 0
        except Exception as e:
            print(f"Error running tool: {e}")
            return False
    
    def run_full_analysis(self) -> Dict[str, Any]:
        """Run comprehensive project analysis"""
        print("Running full project analysis...")
        
        results = {
            "timestamp": str(Path().resolve()),
            "project_root": str(self.project_root),
            "tools_run": [],
            "summary": {}
        }
        
        # Run linter
        print("\n1. Running GDScript Linter...")
        lint_success = self.run_tool("lint", ["--format", "json"])
        results["tools_run"].append({"tool": "lint", "success": lint_success})
        
        # Parse lint results
        lint_file = self.project_root / "gdscript_analysis.json"
        if lint_file.exists():
            with open(lint_file) as f:
                lint_data = json.load(f)
                results["summary"]["lint_issues"] = len(lint_data)
                results["summary"]["critical_issues"] = len([
                    issue for issue in lint_data if issue.get("severity") == "error"
                ])
        
        # Run tests
        print("\n2. Running Tests...")
        test_success = self.run_tool("test")
        results["tools_run"].append({"tool": "test", "success": test_success})
        
        # Parse test results
        test_file = self.project_root / "test_report.json"
        if test_file.exists():
            with open(test_file) as f:
                test_data = json.load(f)
                results["summary"]["total_tests"] = test_data.get("summary", {}).get("total_tests", 0)
                results["summary"]["tests_passed"] = test_data.get("summary", {}).get("passed", 0)
                results["summary"]["tests_failed"] = test_data.get("summary", {}).get("failed", 0)
        
        # Generate documentation
        print("\n3. Generating Documentation...")
        docs_success = self.run_tool("docs", ["--format", "json"])
        results["tools_run"].append({"tool": "docs", "success": docs_success})
        
        # Parse documentation results
        docs_file = self.project_root / "project_docs.json"
        if docs_file.exists():
            with open(docs_file) as f:
                docs_data = json.load(f)
                results["summary"]["total_classes"] = len(docs_data.get("classes", []))
                results["summary"]["total_scenes"] = len(docs_data.get("scenes", []))
        
        # Save comprehensive report
        report_file = self.project_root / "project_analysis_report.json"
        with open(report_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"\nFull analysis complete! Report saved to {report_file}")
        self._print_summary(results["summary"])
        
        return results
    
    def _print_summary(self, summary: Dict[str, Any]) -> None:
        """Print analysis summary"""
        print(f"\n{'='*50}")
        print("PROJECT ANALYSIS SUMMARY")
        print(f"{'='*50}")
        
        if "lint_issues" in summary:
            print(f"Lint Issues: {summary['lint_issues']} (Critical: {summary.get('critical_issues', 0)})")
        
        if "total_tests" in summary:
            print(f"Tests: {summary['tests_passed']}/{summary['total_tests']} passed ({summary['tests_failed']} failed)")
        
        if "total_classes" in summary:
            print(f"Classes: {summary['total_classes']}")
        
        if "total_scenes" in summary:
            print(f"Scenes: {summary['total_scenes']}")
        
        print(f"{'='*50}")
    
    def setup_project_tools(self) -> None:
        """Setup tools for the project"""
        print("Setting up Godot development tools...")
        
        # Create tools directory structure
        (self.tools_dir / "scripts").mkdir(exist_ok=True)
        (self.project_root / "docs").mkdir(exist_ok=True)
        
        # Create tool runner scripts
        self._create_run_scripts()
        
        print("Project tools setup complete!")
    
    def _create_run_scripts(self) -> None:
        """Create convenient runner scripts"""
        # Create lint runner
        lint_script = self.tools_dir / "run_lint.sh"
        with open(lint_script, 'w') as f:
            f.write(f"""#!/bin/bash
cd "{self.project_root}"
python3 MCP/TOOLS/gdscript_linter.py . --format text
""")
        lint_script.chmod(0o755)
        
        # Create test runner
        test_script = self.tools_dir / "run_tests.sh"
        with open(test_script, 'w') as f:
            f.write(f"""#!/bin/bash
cd "{self.project_root}"
python3 MCP/TOOLS/godot_test_runner.py .
""")
        test_script.chmod(0o755)
        
        # Create docs runner
        docs_script = self.tools_dir / "run_docs.sh"
        with open(docs_script, 'w') as f:
            f.write(f"""#!/bin/bash
cd "{self.project_root}"
python3 MCP/TOOLS/godot_doc_generator.py . --format markdown --output docs
""")
        docs_script.chmod(0o755)
        
        # Create main runner
        main_script = self.tools_dir / "run_analysis.sh"
        with open(main_script, 'w') as f:
            f.write(f"""#!/bin/bash
cd "{self.project_root}"
python3 MCP/TOOLS/godot_tool_suite.py . --full-analysis
""")
        main_script.chmod(0o755)
    
    def list_tools(self) -> None:
        """List all available tools"""
        print("Available Godot Development Tools:")
        print(f"{'='*50}")
        
        for tool_name, tool_info in self.tools.items():
            print(f"\n{tool_name}:")
            print(f"  Description: {tool_info['description']}")
            print(f"  Script: {tool_info['script']}")
            if tool_info['args']:
                print(f"  Arguments: {', '.join(tool_info['args'])}")
    
    def health_check(self) -> Dict[str, bool]:
        """Check if all tools are properly installed"""
        print("Checking tool health...")
        
        health = {}
        
        # Check Python tools
        for tool_name, tool_info in self.tools.items():
            if tool_info["script"].endswith(".py"):
                script_path = self.tools_dir / tool_info["script"]
                health[tool_name] = script_path.exists()
                
                status = "✓" if health[tool_name] else "✗"
                print(f"{status} {tool_name}: {script_path}")
        
        # Check dependencies
        dependencies = ["json", "re", "pathlib", "subprocess"]
        for dep in dependencies:
            try:
                __import__(dep)
                health[f"dependency_{dep}"] = True
                print(f"✓ {dep}: Available")
            except ImportError:
                health[f"dependency_{dep}"] = False
                print(f"✗ {dep}: Missing")
        
        return health

def main():
    parser = argparse.ArgumentParser(description="Godot Development Tools Suite")
    parser.add_argument("project_root", help="Path to Godot project root")
    parser.add_argument("--tool", help="Run specific tool")
    parser.add_argument("--full-analysis", action="store_true", help="Run full project analysis")
    parser.add_argument("--setup", action="store_true", help="Setup project tools")
    parser.add_argument("--list", action="store_true", help="List available tools")
    parser.add_argument("--health", action="store_true", help="Check tool health")
    parser.add_argument("--tool-args", nargs="*", help="Arguments to pass to specific tool")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.project_root):
        print(f"Error: Project root '{args.project_root}' does not exist")
        sys.exit(1)
    
    suite = GodotToolSuite(args.project_root)
    
    if args.setup:
        suite.setup_project_tools()
    elif args.list:
        suite.list_tools()
    elif args.health:
        health = suite.health_check()
        all_healthy = all(health.values())
        sys.exit(0 if all_healthy else 1)
    elif args.full_analysis:
        results = suite.run_full_analysis()
        # Exit with error if critical issues found
        critical_issues = results.get("summary", {}).get("critical_issues", 0)
        failed_tests = results.get("summary", {}).get("tests_failed", 0)
        sys.exit(1 if (critical_issues > 0 or failed_tests > 0) else 0)
    elif args.tool:
        tool_args = args.tool_args or []
        success = suite.run_tool(args.tool, tool_args)
        sys.exit(0 if success else 1)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
