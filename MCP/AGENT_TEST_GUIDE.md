# MCP Test Registry - Agent Quick Reference

## Overview
The MCP system has discovered **42 test suites** with **65 total tests** across the Godot project.

## Key Test Suites for Current Development

### Interactive Apartment (9 tests) - PRIMARY FOCUS
**File**: `tests/integration/test_interactive_apartment.gd`
**Command**: `godot4 -d -s --headless addons/gut/gut_cmdln.gd -gtest=test_interactive_apartment.gd`
**Status**: 6/9 passing (needs debugging)

**Test Breakdown**:
- **Unit Tests (2)**: Basic layout creation, player starting position
- **Integration Tests (5)**: Movement, collision, POI detection, Canvas rendering, UI integration  
- **Game Flow Tests (2)**: Desk drawer items, item interaction

**Current Issues**:
- `test_collision_detection` - Position coordination between tests and implementation
- `test_poi_detection` - POI lookup returning null
- `test_desk_drawer_items` - Item access after position changes

### Other Notable Test Suites

#### Core System Tests
- **test_main_ui_basic_room** (3 tests) - UI integration with room system
- **test_ascii_canvas_demo** (2 tests) - ASCII rendering system
- **test_entity_system** (2 tests) - Game entity management
- **test_battle_manager** (2 tests) - Combat system
- **test_poi_interaction** (2 tests) - Point of interest mechanics

#### Boot & Integration Tests  
- **test_boot** (1 test) - Application startup
- **test_main_ui_loads** (1 test) - Main UI initialization
- **test_new_game_flow** (2 tests) - Game initialization flow
- **test_main_menu_integration** (2 tests) - Menu system

#### ASCII System Tests
- **test_ascii_min_demo** (1 test) - Minimal ASCII demo
- **test_ascii_location_binding** (1 test) - Location system binding
- **test_ascii_redraw_debounce** (1 test) - Rendering optimization

## Agent Usage Patterns

### For Test-Driven Development:
1. **Focus on `test_interactive_apartment`** - highest priority, most complex
2. **Run Command**: `cd /home/eric/BrokenDivinityDemo/godot_project && godot4 -d -s --headless addons/gut/gut_cmdln.gd -gtest=test_interactive_apartment.gd`
3. **Debug failing tests**: collision detection, POI detection, item management
4. **Check dependencies**: layout → movement → collision → POI → items

### For System Validation:
1. **Boot tests**: Ensure core systems initialize
2. **UI tests**: Verify interface integration  
3. **ASCII tests**: Validate rendering pipeline
4. **Integration tests**: Check cross-system communication

### For Comprehensive Testing:
```bash
# Run all tests (may take several minutes)
find tests/ -name "test_*.gd" -exec basename {} \; | while read testfile; do
  echo "Running $testfile..."
  godot4 -d -s --headless addons/gut/gut_cmdln.gd -gtest="$testfile"
done
```

## Test Categories Distribution
- **Unit Tests**: ~60% (isolated component testing)
- **Integration Tests**: ~30% (cross-system validation)
- **Game Flow Tests**: ~8% (end-to-end scenarios)  
- **Smoke Tests**: ~2% (critical path validation)

## Files for Reference
- **Full Registry**: `/home/eric/BrokenDivinityDemo/MCP/test_registry.json`
- **MCP Server**: `/home/eric/BrokenDivinityDemo/MCP/TOOLS/mcp_server.py`
- **Registry Updater**: `/home/eric/BrokenDivinityDemo/MCP/TOOLS/test_registry_updater.py`
- **API Documentation**: `/home/eric/BrokenDivinityDemo/MCP/MCP_TEST_REGISTRY.md`

## API Endpoints (when MCP server running on localhost:5000)
- `GET /tests` - List all test suites
- `GET /tests/interactive_apartment` - Get apartment test details
- `GET /tests/interactive_apartment/run` - Get run command
- `GET /tests/failing` - Get currently failing tests
- `GET /tests/summary` - Get comprehensive project overview
- `POST /tests/interactive_apartment/update-status` - Update test status

## Next Steps for Agents
1. **Continue apartment debugging** - Focus on 3 remaining failing tests
2. **Update test status** - Report progress via MCP API
3. **Expand test coverage** - Add edge cases for working features
4. **System integration** - Ensure apartment works with broader game systems
