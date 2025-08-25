extends GutTest

## Test suite for Interactive Apartment system

func test_apartment_layout_creation():
	# Test basic apartment layout generation
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	add_child_autofree(apartment)
	
	# Verify apartment has the correct dimensions
	assert_true(apartment.has_method("get_apartment_size"), "Apartment should have size method")
	var size = apartment.get_apartment_size()
	assert_eq(size.x, 28, "Apartment width should be 28")
	assert_eq(size.y, 16, "Apartment height should be 16")
	
	# Verify basic room structure exists
	assert_true(apartment.has_method("get_cell"), "Apartment should have cell access")
	
	# Check that walls exist at edges
	var top_left = apartment.get_cell(Vector2i(0, 0))
	assert_eq(top_left.character, "█", "Top-left should be wall")
	
	print("[Test] Apartment layout creation verified")

func test_player_starting_position():
	# Test player starts in correct position
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	add_child_autofree(apartment)
	
	await get_tree().process_frame
	
	# Verify player exists and has starting position
	assert_true(apartment.has_method("get_player_position"), "Should have player position")
	var player_pos = apartment.get_player_position()
	assert_eq(player_pos, Vector2i(5, 2), "Player should start at (5,2)")
	
	# Verify player character is @ 
	var player_cell = apartment.get_cell(player_pos)
	assert_eq(player_cell.character, "@", "Player should be @ symbol")
	
	print("[Test] Player starting position verified")

func test_player_movement_wasd():
	# Test WASD movement controls
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	add_child_autofree(apartment)
	
	await get_tree().process_frame
	
	var initial_pos = apartment.get_player_position()
	
	# Test W (up) movement
	apartment.handle_input("ui_up")
	await get_tree().process_frame
	var new_pos = apartment.get_player_position()
	assert_eq(new_pos, initial_pos + Vector2i(0, -1), "W should move player up")
	
	# Test S (down) movement  
	apartment.handle_input("ui_down")
	await get_tree().process_frame
	var after_down = apartment.get_player_position()
	assert_eq(after_down, initial_pos, "S should move player back down")
	
	# Test A (left) movement
	apartment.handle_input("ui_left")
	await get_tree().process_frame
	var after_left = apartment.get_player_position()
	assert_eq(after_left, initial_pos + Vector2i(-1, 0), "A should move player left")
	
	# Test D (right) movement
	apartment.handle_input("ui_right")
	await get_tree().process_frame
	var after_right = apartment.get_player_position()
	assert_eq(after_right, initial_pos, "D should move player back right")
	
	print("[Test] WASD movement controls verified")

func test_collision_detection():
	# Test player cannot move through walls/furniture
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	add_child_autofree(apartment)
	
	await get_tree().process_frame
	
	# Move player to a wall and try to walk through it
	apartment.set_player_position(Vector2i(1, 1))  # Near top wall
	var wall_pos = apartment.get_player_position()
	
	# Try to move into wall (up)
	apartment.handle_input("ui_up")
	await get_tree().process_frame
	var after_wall_attempt = apartment.get_player_position()
	assert_eq(after_wall_attempt, wall_pos, "Player should not move through walls")
	
	# Test furniture collision
	# Move player next to desk and try to walk through it
	var desk_pos = Vector2i(14, 8)  # Position of desk in layout
	apartment.set_player_position(desk_pos + Vector2i(-1, 0))  # Left of desk
	
	apartment.handle_input("ui_right")  # Try to move into desk
	await get_tree().process_frame
	var after_furniture = apartment.get_player_position()
	assert_eq(after_furniture, desk_pos + Vector2i(-1, 0), "Player should not move through furniture")
	
	print("[Test] Collision detection verified")

func test_poi_detection():
	# Test POI detection when player is adjacent
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	add_child_autofree(apartment)
	
	await get_tree().process_frame
	
	# Move player next to desk POI
	var desk_pos = Vector2i(14, 8)  # Desk position (corrected to match layout)
	apartment.set_player_position(desk_pos + Vector2i(-1, 0))  # Adjacent to desk
	
	await get_tree().process_frame
	
	# Check if POI is detected
	assert_true(apartment.has_method("get_nearby_poi"), "Should have POI detection")
	var nearby_poi = apartment.get_nearby_poi()
	assert_not_null(nearby_poi, "Should detect nearby POI")
	assert_eq(nearby_poi.name, "Desk", "Should detect desk POI")
	
	print("[Test] POI detection verified")

func test_desk_drawer_items():
	# Test desk drawer contains the three key items
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	add_child_autofree(apartment)
	
	await get_tree().process_frame
	
	# Get desk drawer POI
	assert_true(apartment.has_method("get_poi_by_name"), "Should have POI lookup")
	var drawer_poi = apartment.get_poi_by_name("Desk Drawer")
	assert_not_null(drawer_poi, "Desk drawer POI should exist")
	
	# Check items exist
	assert_true(drawer_poi.has_method("get_items"), "POI should have items")
	var items = drawer_poi.get_items()
	assert_eq(items.size(), 3, "Drawer should have 3 items")
	
	# Check specific items
	var pistol = null
	var whiskey = null  
	var jacket = null
	
	for item in items:
		match item.name:
			".38 Service Pistol":
				pistol = item
			"Bourbon Whiskey":
				whiskey = item
			"Brown Leather Jacket":
				jacket = item
	
	assert_not_null(pistol, "Service pistol should exist")
	assert_not_null(whiskey, "Whiskey bottle should exist") 
	assert_not_null(jacket, "Leather jacket should exist")
	
	# Check item properties
	assert_eq(pistol.item_type, "weapon", "Pistol should be weapon type")
	assert_eq(whiskey.item_type, "consumable", "Whiskey should be consumable")
	assert_eq(jacket.item_type, "armor", "Jacket should be armor type")
	
	print("[Test] Desk drawer items verified")

func test_item_interaction():
	# Test taking items from desk drawer
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	add_child_autofree(apartment)
	
	await get_tree().process_frame
	
	# Move player to desk drawer
	var drawer_pos = Vector2i(14, 9)  # Drawer position (corrected)
	apartment.set_player_position(drawer_pos + Vector2i(-1, 0))  # Adjacent
	
	# Interact with drawer
	apartment.handle_input("ui_accept")  # E key
	await get_tree().process_frame
	
	# Check if interaction occurred
	assert_true(apartment.has_method("get_last_interaction"), "Should track interactions")
	var interaction = apartment.get_last_interaction()
	assert_not_null(interaction, "Should have interaction result")
	assert_eq(interaction.poi, "Desk Drawer", "Should interact with drawer")
	
	print("[Test] Item interaction verified")

func test_canvas_rendering():
	# Test apartment renders properly with Canvas system
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	add_child_autofree(apartment)
	
	await get_tree().process_frame
	
	# Verify Canvas compatibility
	assert_true(apartment.has_method("_blit_self_under_canvas"), "Should have Canvas support")
	
	# Create mock canvas buffer and test rendering
	var buffer_scene = preload("res://addons/ascii_grid/ascii_canvas_buffer.gd")
	var buffer = buffer_scene.new(Vector2i(30, 20))
	
	apartment._blit_self_under_canvas(buffer)
	
	# Check that cells were rendered
	var rendered_cells = 0
	for x in range(28):
		for y in range(16):
			var cell = buffer.get_cell(Vector2i(x, y))
			if cell and cell.character != " ":
				rendered_cells += 1
	
	assert_gt(rendered_cells, 100, "Should render substantial content")
	
	print("[Test] Canvas rendering verified: ", rendered_cells, " cells")

func test_ui_panel_integration():
	# Test integration with OutputPanel and ActionPanel
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	add_child_autofree(apartment)
	
	await get_tree().process_frame
	
	# Test UI update methods exist
	assert_true(apartment.has_method("update_output_panel"), "Should update output panel")
	assert_true(apartment.has_method("update_action_panel"), "Should update action panel")
	
	# Test UI updates work
	apartment.update_output_panel("Test description")
	apartment.update_action_panel(["Test action 1", "Test action 2"])
	
	print("[Test] UI panel integration verified")
