from flask import Flask, send_from_directory, jsonify, request
import os
import sys

# Add the current directory to Python path for imports
sys.path.append(os.path.dirname(__file__))

app = Flask(__name__)

# Test registry for MCP agents
TEST_REGISTRY = {
    "interactive_apartment": {
        "file_path": "tests/integration/test_interactive_apartment.gd",
        "description": "Interactive apartment system tests for WASD movement, POI interaction, and item management",
        "test_count": 9,
        "tests": [
            {
                "name": "test_apartment_layout_creation",
                "description": "Test basic apartment layout generation with correct dimensions and wall placement",
                "category": "unit",
                "dependencies": [],
                "expected_duration": "fast"
            },
            {
                "name": "test_player_starting_position", 
                "description": "Test player starts at correct position (5,2) with @ symbol",
                "category": "unit",
                "dependencies": [],
                "expected_duration": "fast"
            },
            {
                "name": "test_player_movement_wasd",
                "description": "Test WASD keyboard controls for player movement in all directions",
                "category": "integration", 
                "dependencies": ["test_apartment_layout_creation", "test_player_starting_position"],
                "expected_duration": "fast"
            },
            {
                "name": "test_collision_detection",
                "description": "Test player cannot move through walls, furniture, or other solid objects",
                "category": "integration",
                "dependencies": ["test_player_movement_wasd"],
                "expected_duration": "medium"
            },
            {
                "name": "test_poi_detection", 
                "description": "Test POI (Point of Interest) detection when player is adjacent to interactive objects",
                "category": "integration",
                "dependencies": ["test_collision_detection"],
                "expected_duration": "medium"
            },
            {
                "name": "test_desk_drawer_items",
                "description": "Test desk drawer contains three key detective items: service pistol, whiskey bottle, leather jacket",
                "category": "game_flow",
                "dependencies": ["test_poi_detection"],
                "expected_duration": "medium"
            },
            {
                "name": "test_item_interaction",
                "description": "Test taking items from desk drawer using E key interaction",
                "category": "game_flow", 
                "dependencies": ["test_desk_drawer_items"],
                "expected_duration": "medium"
            },
            {
                "name": "test_canvas_rendering",
                "description": "Test apartment renders properly with Canvas ASCII system integration",
                "category": "integration",
                "dependencies": ["test_apartment_layout_creation"],
                "expected_duration": "medium"
            },
            {
                "name": "test_ui_panel_integration",
                "description": "Test integration with OutputPanel and ActionPanel UI components",
                "category": "integration",
                "dependencies": ["test_canvas_rendering"],
                "expected_duration": "fast"
            }
        ],
        "run_command": "godot4 -d -s --headless addons/gut/gut_cmdln.gd -gtest=test_interactive_apartment.gd",
        "current_status": "6/9 passing",
        "failing_tests": ["test_collision_detection", "test_poi_detection", "test_desk_drawer_items"],
        "last_updated": "2025-08-25"
    }
}

# Serve MCP docs
@app.route('/docs/<path:filename>')
def serve_docs(filename):
    docs_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../'))
    return send_from_directory(docs_dir, filename)

# Status endpoint
@app.route('/status')
def status():
    return jsonify({'status': 'MCP server running', 'project': 'Godot MCP Template'})

@app.route('/tests/summary')
def get_test_summary():
    """Get a comprehensive summary of all tests in the project"""
    try:
        from test_registry_updater import TestRegistryUpdater
        
        project_root = '/home/eric/BrokenDivinityDemo/godot_project'
        updater = TestRegistryUpdater(project_root)
        discovered_registry = updater.scan_project_tests()
        
        # Calculate summary statistics
        total_suites = len(discovered_registry)
        total_tests = sum(suite['test_count'] for suite in discovered_registry.values())
        
        # Categorize tests
        categories = {'unit': 0, 'integration': 0, 'game_flow': 0, 'smoke': 0}
        durations = {'fast': 0, 'medium': 0, 'slow': 0}
        
        suite_breakdown = []
        for suite_name, suite_info in discovered_registry.items():
            suite_categories = {'unit': 0, 'integration': 0, 'game_flow': 0, 'smoke': 0}
            suite_durations = {'fast': 0, 'medium': 0, 'slow': 0}
            
            for test in suite_info['tests']:
                categories[test['category']] += 1
                durations[test['expected_duration']] += 1
                suite_categories[test['category']] += 1
                suite_durations[test['expected_duration']] += 1
            
            suite_breakdown.append({
                'name': suite_name,
                'test_count': suite_info['test_count'],
                'file_path': suite_info['file_path'],
                'categories': suite_categories,
                'durations': suite_durations,
                'run_command': suite_info['run_command']
            })
        
        return jsonify({
            'project_summary': {
                'total_suites': total_suites,
                'total_tests': total_tests,
                'categories': categories,
                'durations': durations
            },
            'suite_breakdown': suite_breakdown,
            'registry_status': {
                'tracked_suites': len(TEST_REGISTRY),
                'discovered_suites': total_suites,
                'needs_update': total_suites > len(TEST_REGISTRY)
            }
        })
        
    except Exception as e:
        return jsonify({'error': f'Failed to generate summary: {str(e)}'}), 500

@app.route('/tests/discover')
def discover_tests():
    """Dynamically discover and update test registry"""
    try:
        from test_registry_updater import TestRegistryUpdater
        
        project_root = '/home/eric/BrokenDivinityDemo/godot_project'
        updater = TestRegistryUpdater(project_root)
        discovered_registry = updater.scan_project_tests()
        
        # Merge with existing registry, preserving status information
        global TEST_REGISTRY
        for suite_name, suite_info in discovered_registry.items():
            if suite_name in TEST_REGISTRY:
                # Preserve existing status and update metadata
                existing = TEST_REGISTRY[suite_name]
                suite_info['current_status'] = existing.get('current_status', 'unknown')
                suite_info['failing_tests'] = existing.get('failing_tests', [])
                suite_info['last_updated'] = existing.get('last_updated', 'discovered')
            
            TEST_REGISTRY[suite_name] = suite_info
        
        return jsonify({
            'status': 'success',
            'discovered_suites': len(discovered_registry),
            'total_suites': len(TEST_REGISTRY),
            'new_suites': list(set(discovered_registry.keys()) - set(TEST_REGISTRY.keys()))
        })
        
    except Exception as e:
        return jsonify({'error': f'Failed to discover tests: {str(e)}'}), 500

@app.route('/tests/<suite_name>/update-status', methods=['POST'])
def update_test_status(suite_name):
    """Update the status of a test suite"""
    if suite_name not in TEST_REGISTRY:
        return jsonify({'error': 'Test suite not found'}), 404
    
    data = request.json
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    suite = TEST_REGISTRY[suite_name]
    
    # Update fields if provided
    if 'current_status' in data:
        suite['current_status'] = data['current_status']
    if 'failing_tests' in data:
        suite['failing_tests'] = data['failing_tests']
    if 'last_updated' in data:
        suite['last_updated'] = data['last_updated']
    
    return jsonify({
        'status': 'updated',
        'suite_name': suite_name,
        'new_status': suite['current_status']
    })

# Test registry endpoints
@app.route('/tests')
def list_test_suites():
    """Get all available test suites"""
    return jsonify({
        'test_suites': list(TEST_REGISTRY.keys()),
        'total_suites': len(TEST_REGISTRY),
        'total_tests': sum(suite['test_count'] for suite in TEST_REGISTRY.values())
    })

@app.route('/tests/<suite_name>')
def get_test_suite(suite_name):
    """Get detailed information about a specific test suite"""
    if suite_name not in TEST_REGISTRY:
        return jsonify({'error': 'Test suite not found'}), 404
    return jsonify(TEST_REGISTRY[suite_name])

@app.route('/tests/<suite_name>/run')
def get_run_command(suite_name):
    """Get the command to run a specific test suite"""
    if suite_name not in TEST_REGISTRY:
        return jsonify({'error': 'Test suite not found'}), 404
    
    suite = TEST_REGISTRY[suite_name]
    return jsonify({
        'suite_name': suite_name,
        'run_command': suite['run_command'],
        'working_directory': '/home/eric/BrokenDivinityDemo/godot_project',
        'expected_test_count': suite['test_count'],
        'current_status': suite['current_status']
    })

@app.route('/tests/<suite_name>/status')
def get_test_status(suite_name):
    """Get current status of a test suite"""
    if suite_name not in TEST_REGISTRY:
        return jsonify({'error': 'Test suite not found'}), 404
        
    suite = TEST_REGISTRY[suite_name]
    return jsonify({
        'suite_name': suite_name,
        'status': suite['current_status'],
        'failing_tests': suite.get('failing_tests', []),
        'last_updated': suite.get('last_updated'),
        'total_tests': suite['test_count']
    })

@app.route('/tests/failing')
def get_failing_tests():
    """Get all currently failing tests across all suites"""
    failing = {}
    for suite_name, suite in TEST_REGISTRY.items():
        if 'failing_tests' in suite and suite['failing_tests']:
            failing[suite_name] = {
                'failing_tests': suite['failing_tests'],
                'status': suite['current_status']
            }
    return jsonify(failing)

@app.route('/tests/commands')
def get_all_run_commands():
    """Get run commands for all test suites"""
    commands = {}
    for suite_name, suite in TEST_REGISTRY.items():
        commands[suite_name] = {
            'command': suite['run_command'],
            'working_directory': '/home/eric/BrokenDivinityDemo/godot_project',
            'description': suite['description']
        }
    return jsonify(commands)

# Feedback endpoint (stub)
@app.route('/feedback', methods=['POST'])
def feedback():
    data = request.json
    # Save feedback to file or process as needed
    return jsonify({'received': data}), 201

# Workflow endpoint (stub)
@app.route('/workflow')
def workflow():
    return jsonify({'steps': ['plan', 'test', 'implement', 'validate', 'feedback', 'document']})

if __name__ == '__main__':
    app.run(port=5000, debug=True)
