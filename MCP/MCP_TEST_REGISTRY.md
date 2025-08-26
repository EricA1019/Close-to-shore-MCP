# MCP Test Registry Documentation

The MCP Test Registry provides a comprehensive API for agents to discover, monitor, and interact with test suites in the Godot project.

## API Endpoints

### Core Test Information

#### `GET /tests`
List all available test suites
```json
{
  "test_suites": ["interactive_apartment"],
  "total_suites": 1,
  "total_tests": 9
}
```

#### `GET /tests/<suite_name>`
Get detailed information about a specific test suite
```json
{
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
    }
    // ... more tests
  ],
  "run_command": "godot4 -d -s --headless addons/gut/gut_cmdln.gd -gtest=test_interactive_apartment.gd",
  "current_status": "6/9 passing",
  "failing_tests": ["test_collision_detection", "test_poi_detection", "test_desk_drawer_items"],
  "last_updated": "2025-08-25"
}
```

### Test Execution

#### `GET /tests/<suite_name>/run`
Get command to run a specific test suite
```json
{
  "suite_name": "interactive_apartment",
  "run_command": "godot4 -d -s --headless addons/gut/gut_cmdln.gd -gtest=test_interactive_apartment.gd",
  "working_directory": "/home/eric/BrokenDivinityDemo/godot_project",
  "expected_test_count": 9,
  "current_status": "6/9 passing"
}
```

#### `GET /tests/commands`
Get run commands for all test suites
```json
{
  "interactive_apartment": {
    "command": "godot4 -d -s --headless addons/gut/gut_cmdln.gd -gtest=test_interactive_apartment.gd",
    "working_directory": "/home/eric/BrokenDivinityDemo/godot_project",
    "description": "Interactive apartment system tests for WASD movement, POI interaction, and item management"
  }
}
```

### Status Monitoring

#### `GET /tests/<suite_name>/status`
Get current status of a test suite
```json
{
  "suite_name": "interactive_apartment", 
  "status": "6/9 passing",
  "failing_tests": ["test_collision_detection", "test_poi_detection", "test_desk_drawer_items"],
  "last_updated": "2025-08-25",
  "total_tests": 9
}
```

#### `GET /tests/failing`
Get all currently failing tests across all suites
```json
{
  "interactive_apartment": {
    "failing_tests": ["test_collision_detection", "test_poi_detection", "test_desk_drawer_items"],
    "status": "6/9 passing"
  }
}
```

### Dynamic Discovery

#### `GET /tests/discover`
Dynamically discover and update test registry by scanning project files
```json
{
  "status": "success",
  "discovered_suites": 1,
  "total_suites": 1,
  "new_suites": []
}
```

#### `POST /tests/<suite_name>/update-status`
Update the status of a test suite
```json
// Request body:
{
  "current_status": "7/9 passing",
  "failing_tests": ["test_poi_detection", "test_desk_drawer_items"],
  "last_updated": "2025-08-25T14:30:00"
}

// Response:
{
  "status": "updated",
  "suite_name": "interactive_apartment",
  "new_status": "7/9 passing"
}
```

## Test Categories

- **unit**: Isolated component tests, fast execution
- **integration**: Cross-system tests, medium execution
- **game_flow**: End-to-end user scenarios
- **smoke**: Critical boot paths and basic functionality

## Test Dependencies

Tests may have dependencies indicating prerequisite tests that should pass first:
- Basic layout tests before movement tests
- Movement tests before collision tests  
- Collision tests before POI interaction tests
- POI tests before item interaction tests

## Usage for Agents

### Running Tests
1. Get run command: `GET /tests/<suite>/run`
2. Execute in terminal with returned working directory
3. Update status: `POST /tests/<suite>/update-status`

### Monitoring Progress
1. Check failing tests: `GET /tests/failing`
2. Get detailed status: `GET /tests/<suite>/status`
3. Focus on tests with dependencies

### Discovery
1. Scan for new tests: `GET /tests/discover`
2. Get updated registry: `GET /tests`

## Example Agent Workflow

```python
# 1. Check current test status
response = requests.get('http://localhost:5000/tests/failing')
failing_suites = response.json()

# 2. Get run command for failing suite
response = requests.get('http://localhost:5000/tests/interactive_apartment/run')
run_info = response.json()

# 3. Execute tests in terminal
# run_in_terminal(run_info['run_command'], working_dir=run_info['working_directory'])

# 4. Update status after test run
requests.post('http://localhost:5000/tests/interactive_apartment/update-status', 
              json={'current_status': '9/9 passing', 'failing_tests': []})
```

## Starting the MCP Server

```bash
cd /home/eric/BrokenDivinityDemo/MCP/TOOLS
python mcp_server.py
```

Server runs on http://localhost:5000

## Testing the API

```bash
cd /home/eric/BrokenDivinityDemo/MCP/TOOLS
python test_mcp_client.py
```
