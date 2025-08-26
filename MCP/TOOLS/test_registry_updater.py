#!/usr/bin/env python3
"""
Test Registry Updater - Scans Godot project for test files and updates MCP registry
"""

import os
import re
import json
from typing import Dict, List, Any

class TestRegistryUpdater:
    def __init__(self, project_root: str):
        self.project_root = project_root
        self.test_patterns = {
            'test_function': r'^func\s+(test_\w+)\s*\(',
            'test_description': r'#\s*(.+)$',
            'extends': r'extends\s+(\w+)',
            'preload': r'preload\("([^"]+)"\)'
        }
    
    def scan_test_file(self, file_path: str) -> Dict[str, Any]:
        """Scan a single test file and extract test information"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            lines = content.split('\n')
            
            # Extract basic file info
            extends_class = None
            test_functions = []
            current_test = None
            
            for i, line in enumerate(lines):
                line_stripped = line.strip()
                
                # Check for extends clause
                extends_match = re.search(self.test_patterns['extends'], line)
                if extends_match:
                    extends_class = extends_match.group(1)
                
                # Check for test function
                func_match = re.search(self.test_patterns['test_function'], line)
                if func_match:
                    if current_test:
                        test_functions.append(current_test)
                    
                    current_test = {
                        'name': func_match.group(1),
                        'line_number': i + 1,
                        'description': '',
                        'category': self._infer_test_category(func_match.group(1)),
                        'dependencies': [],
                        'expected_duration': self._infer_duration(func_match.group(1))
                    }
                
                # Look for description comments above test function
                elif line_stripped.startswith('#') and current_test and not current_test['description']:
                    desc_match = re.search(self.test_patterns['test_description'], line)
                    if desc_match:
                        current_test['description'] = desc_match.group(1).strip()
            
            # Add the last test function
            if current_test:
                test_functions.append(current_test)
            
            # Analyze dependencies
            for test in test_functions:
                test['dependencies'] = self._infer_dependencies(test['name'], [t['name'] for t in test_functions])
            
            return {
                'file_path': os.path.relpath(file_path, self.project_root),
                'extends_class': extends_class,
                'test_count': len(test_functions),
                'tests': test_functions,
                'last_modified': os.path.getmtime(file_path)
            }
            
        except Exception as e:
            print(f"Error scanning {file_path}: {e}")
            return None
    
    def _infer_test_category(self, test_name: str) -> str:
        """Infer test category from test name"""
        name_lower = test_name.lower()
        
        if any(word in name_lower for word in ['layout', 'creation', 'starting', 'basic']):
            return 'unit'
        elif any(word in name_lower for word in ['movement', 'collision', 'detection', 'rendering', 'integration']):
            return 'integration'
        elif any(word in name_lower for word in ['interaction', 'item', 'drawer', 'game']):
            return 'game_flow'
        elif any(word in name_lower for word in ['smoke', 'boot', 'critical']):
            return 'smoke'
        else:
            return 'unit'  # default
    
    def _infer_duration(self, test_name: str) -> str:
        """Infer expected test duration from name"""
        name_lower = test_name.lower()
        
        if any(word in name_lower for word in ['rendering', 'canvas', 'heavy', 'complex']):
            return 'medium'
        elif any(word in name_lower for word in ['interaction', 'game_flow', 'item']):
            return 'medium' 
        else:
            return 'fast'
    
    def _infer_dependencies(self, test_name: str, all_test_names: List[str]) -> List[str]:
        """Infer test dependencies based on logical order"""
        dependencies = []
        
        # Basic dependency rules
        if 'movement' in test_name and any('layout' in name for name in all_test_names):
            dependencies.extend([name for name in all_test_names if 'layout' in name or 'starting' in name])
        
        if 'collision' in test_name and any('movement' in name for name in all_test_names):
            dependencies.extend([name for name in all_test_names if 'movement' in name])
        
        if 'poi' in test_name and any('collision' in name for name in all_test_names):
            dependencies.extend([name for name in all_test_names if 'collision' in name])
        
        if 'item' in test_name and any('poi' in name for name in all_test_names):
            dependencies.extend([name for name in all_test_names if 'poi' in name])
        
        return list(set(dependencies))  # Remove duplicates
    
    def scan_project_tests(self) -> Dict[str, Any]:
        """Scan entire project for test files"""
        test_registry = {}
        
        # Find all test files
        test_files = []
        for root, dirs, files in os.walk(self.project_root):
            for file in files:
                if file.startswith('test_') and file.endswith('.gd'):
                    test_files.append(os.path.join(root, file))
        
        # Process each test file
        for test_file in test_files:
            file_info = self.scan_test_file(test_file)
            if file_info and file_info['test_count'] > 0:
                # Create suite name from filename
                suite_name = os.path.splitext(os.path.basename(test_file))[0]
                
                # Determine run command based on test framework
                run_command = f"godot4 -d -s --headless addons/gut/gut_cmdln.gd -gtest={os.path.basename(test_file)}"
                
                test_registry[suite_name] = {
                    'file_path': file_info['file_path'],
                    'description': f"Test suite for {suite_name.replace('test_', '').replace('_', ' ')}",
                    'test_count': file_info['test_count'],
                    'tests': file_info['tests'],
                    'run_command': run_command,
                    'current_status': f"0/{file_info['test_count']} status unknown",
                    'failing_tests': [],
                    'last_updated': 'auto-discovered'
                }
        
        return test_registry
    
    def update_mcp_server(self, output_file: str = None):
        """Update the MCP server file with discovered tests"""
        registry = self.scan_project_tests()
        
        if output_file:
            with open(output_file, 'w') as f:
                json.dump(registry, f, indent=2)
                print(f"Test registry written to {output_file}")
        
        return registry

def main():
    """Main entry point for standalone execution"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Update MCP test registry')
    parser.add_argument('--project-root', default='/home/eric/BrokenDivinityDemo/godot_project',
                       help='Root directory of Godot project')
    parser.add_argument('--output', help='Output JSON file for registry')
    
    args = parser.parse_args()
    
    updater = TestRegistryUpdater(args.project_root)
    registry = updater.update_mcp_server(args.output)
    
    print(f"Discovered {len(registry)} test suites:")
    for suite_name, suite_info in registry.items():
        print(f"  {suite_name}: {suite_info['test_count']} tests")

if __name__ == '__main__':
    main()
