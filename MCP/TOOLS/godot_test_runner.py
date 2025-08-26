#!/usr/bin/env python3
"""
Godot Test Automation Tool
Runs GUT tests and generates comprehensive reports
"""

import os
import sys
import json
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Any, Optional

class TestResult:
    def __init__(self, name: str, status: str, duration: float = 0.0, error_message: str = ""):
        self.name = name
        self.status = status  # "pass", "fail", "skip"
        self.duration = duration
        self.error_message = error_message
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "status": self.status,
            "duration": self.duration,
            "error_message": self.error_message
        }

class TestSuite:
    def __init__(self, name: str):
        self.name = name
        self.tests: List[TestResult] = []
        self.total_duration = 0.0
    
    def add_test(self, test: TestResult):
        self.tests.append(test)
        self.total_duration += test.duration
    
    @property
    def passed_count(self) -> int:
        return len([t for t in self.tests if t.status == "pass"])
    
    @property
    def failed_count(self) -> int:
        return len([t for t in self.tests if t.status == "fail"])
    
    @property
    def skipped_count(self) -> int:
        return len([t for t in self.tests if t.status == "skip"])
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "total_tests": len(self.tests),
            "passed": self.passed_count,
            "failed": self.failed_count,
            "skipped": self.skipped_count,
            "duration": self.total_duration,
            "tests": [test.to_dict() for test in self.tests]
        }

class GodotTestRunner:
    def __init__(self, project_root: str, godot_executable: str = "godot"):
        self.project_root = Path(project_root)
        self.godot_executable = godot_executable
        self.test_suites: List[TestSuite] = []
    
    def find_test_files(self) -> List[Path]:
        """Find all test files in the project"""
        test_files = []
        
        # Look for files starting with "test_" or ending with "_test.gd"
        for gd_file in self.project_root.rglob("*.gd"):
            if (gd_file.name.startswith("test_") or 
                gd_file.name.endswith("_test.gd") or
                "test" in gd_file.parts):
                test_files.append(gd_file)
        
        return test_files
    
    def run_gut_tests(self, test_file: Optional[Path] = None) -> bool:
        """Run GUT tests using Godot"""
        try:
            # Build command to run tests
            cmd = [
                self.godot_executable,
                "--headless",
                "--path", str(self.project_root),
                "--script", "addons/gut/gut_cmdln.gd"
            ]
            
            if test_file:
                cmd.extend(["-gtest", str(test_file.relative_to(self.project_root))])
            
            print(f"Running command: {' '.join(cmd)}")
            
            # Run the command
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
            
            # Parse the output
            self._parse_gut_output(result.stdout)
            
            return result.returncode == 0
            
        except subprocess.TimeoutExpired:
            print("Test execution timed out!")
            return False
        except Exception as e:
            print(f"Error running tests: {e}")
            return False
    
    def _parse_gut_output(self, output: str) -> None:
        """Parse GUT test output"""
        lines = output.split('\n')
        current_suite = None
        
        for line in lines:
            line = line.strip()
            
            # Look for test suite indicators
            if "Running tests for" in line or "Test Script:" in line:
                suite_name = self._extract_suite_name(line)
                current_suite = TestSuite(suite_name)
                self.test_suites.append(current_suite)
            
            # Look for individual test results
            elif " [PASS]" in line or " [FAIL]" in line or " [SKIP]" in line:
                if current_suite:
                    test = self._parse_test_line(line)
                    if test:
                        current_suite.add_test(test)
    
    def _extract_suite_name(self, line: str) -> str:
        """Extract test suite name from output line"""
        # Try to extract filename from various formats
        if "Running tests for" in line:
            return line.split("Running tests for")[-1].strip()
        elif "Test Script:" in line:
            return line.split("Test Script:")[-1].strip()
        else:
            return "Unknown Suite"
    
    def _parse_test_line(self, line: str) -> Optional[TestResult]:
        """Parse a single test result line"""
        try:
            # Example format: "test_player_movement [PASS] (0.001s)"
            if "[PASS]" in line:
                name = line.split("[PASS]")[0].strip()
                duration = self._extract_duration(line)
                return TestResult(name, "pass", duration)
            
            elif "[FAIL]" in line:
                name = line.split("[FAIL]")[0].strip()
                duration = self._extract_duration(line)
                error = self._extract_error(line)
                return TestResult(name, "fail", duration, error)
            
            elif "[SKIP]" in line:
                name = line.split("[SKIP]")[0].strip()
                return TestResult(name, "skip")
            
        except Exception as e:
            print(f"Error parsing test line '{line}': {e}")
        
        return None
    
    def _extract_duration(self, line: str) -> float:
        """Extract test duration from line"""
        import re
        match = re.search(r'\(([0-9.]+)s?\)', line)
        if match:
            return float(match.group(1))
        return 0.0
    
    def _extract_error(self, line: str) -> str:
        """Extract error message from failed test line"""
        # This would need to be enhanced based on actual GUT output format
        return ""
    
    def generate_report(self, output_format: str = "json") -> str:
        """Generate comprehensive test report"""
        total_tests = sum(len(suite.tests) for suite in self.test_suites)
        total_passed = sum(suite.passed_count for suite in self.test_suites)
        total_failed = sum(suite.failed_count for suite in self.test_suites)
        total_skipped = sum(suite.skipped_count for suite in self.test_suites)
        total_duration = sum(suite.total_duration for suite in self.test_suites)
        
        if output_format == "json":
            return json.dumps({
                "summary": {
                    "total_tests": total_tests,
                    "passed": total_passed,
                    "failed": total_failed,
                    "skipped": total_skipped,
                    "duration": total_duration,
                    "success_rate": (total_passed / total_tests * 100) if total_tests > 0 else 0
                },
                "suites": [suite.to_dict() for suite in self.test_suites]
            }, indent=2)
        
        elif output_format == "text":
            report = f"Godot Test Report\n{'='*50}\n\n"
            report += f"Total Tests: {total_tests}\n"
            report += f"Passed: {total_passed}\n"
            report += f"Failed: {total_failed}\n"
            report += f"Skipped: {total_skipped}\n"
            report += f"Duration: {total_duration:.3f}s\n"
            report += f"Success Rate: {(total_passed / total_tests * 100) if total_tests > 0 else 0:.1f}%\n\n"
            
            for suite in self.test_suites:
                report += f"Suite: {suite.name}\n"
                report += f"  Tests: {len(suite.tests)} (P:{suite.passed_count}, F:{suite.failed_count}, S:{suite.skipped_count})\n"
                report += f"  Duration: {suite.total_duration:.3f}s\n"
                
                # Show failed tests
                failed_tests = [t for t in suite.tests if t.status == "fail"]
                if failed_tests:
                    report += "  Failed Tests:\n"
                    for test in failed_tests:
                        report += f"    - {test.name}\n"
                        if test.error_message:
                            report += f"      Error: {test.error_message}\n"
                report += "\n"
            
            return report
        
        else:
            raise ValueError(f"Unknown output format: {output_format}")
    
    def run_continuous_testing(self, watch_directory: str = "scripts") -> None:
        """Run tests continuously when files change"""
        try:
            import watchdog
            from watchdog.observers import Observer
            from watchdog.events import FileSystemEventHandler
            
            class TestHandler(FileSystemEventHandler):
                def __init__(self, runner):
                    self.runner = runner
                    self.last_run = 0
                
                def on_modified(self, event):
                    if event.is_directory:
                        return
                    
                    if event.src_path.endswith('.gd'):
                        # Debounce rapid file changes
                        current_time = time.time()
                        if current_time - self.last_run > 2:  # 2 second cooldown
                            self.last_run = current_time
                            print(f"\nFile changed: {event.src_path}")
                            print("Running tests...")
                            self.runner.run_all_tests()
            
            observer = Observer()
            handler = TestHandler(self)
            observer.schedule(handler, str(self.project_root / watch_directory), recursive=True)
            observer.start()
            
            print(f"Watching {watch_directory} for changes. Press Ctrl+C to stop.")
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                observer.stop()
            observer.join()
            
        except ImportError:
            print("Install watchdog for continuous testing: pip install watchdog")
    
    def run_all_tests(self) -> bool:
        """Run all tests in the project"""
        self.test_suites.clear()
        
        test_files = self.find_test_files()
        print(f"Found {len(test_files)} test files")
        
        if not test_files:
            print("No test files found!")
            return False
        
        # Run all tests
        success = self.run_gut_tests()
        
        # Generate and display report
        report = self.generate_report("text")
        print(report)
        
        # Save JSON report
        json_report = self.generate_report("json")
        with open("test_report.json", "w") as f:
            f.write(json_report)
        
        return success

def main():
    if len(sys.argv) < 2:
        print("Usage: python godot_test_runner.py <project_root> [--continuous] [--godot-path <path>]")
        sys.exit(1)
    
    project_root = sys.argv[1]
    continuous = "--continuous" in sys.argv
    
    godot_executable = "godot"
    if "--godot-path" in sys.argv:
        godot_index = sys.argv.index("--godot-path") + 1
        if godot_index < len(sys.argv):
            godot_executable = sys.argv[godot_index]
    
    if not os.path.exists(project_root):
        print(f"Error: Project root '{project_root}' does not exist")
        sys.exit(1)
    
    runner = GodotTestRunner(project_root, godot_executable)
    
    if continuous:
        runner.run_continuous_testing()
    else:
        success = runner.run_all_tests()
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
