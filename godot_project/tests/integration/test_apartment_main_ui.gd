extends GutTest

## Test the new apartment main UI

func test_apartment_main_ui_loads():
	# Load our new apartment main UI scene
	var apartment_ui_scene = preload("res://scenes/ui/apartment_main_ui.tscn")
	var apartment_ui = apartment_ui_scene.instantiate()
	add_child_autofree(apartment_ui)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verify main components exist
	var term_root = apartment_ui.get_node("%MainPanel/TermRoot")
	assert_not_null(term_root, "TermRoot should exist")
	
	var apartment = term_root.get_node("InteractiveApartment")
	assert_not_null(apartment, "InteractiveApartment should be in TermRoot")
	
	# Verify apartment functionality
	assert_true(apartment.has_method("get_player_position"), "Should have player position")
	assert_true(apartment.has_method("handle_input"), "Should handle input")
	
	var player_pos = apartment.get_player_position()
	assert_eq(player_pos, Vector2i(5, 2), "Player should start at (5,2)")
	
	print("[Test] Apartment main UI loaded successfully")

func test_apartment_main_ui_movement():
	# Load our new apartment main UI scene
	var apartment_ui_scene = preload("res://scenes/ui/apartment_main_ui.tscn")
	var apartment_ui = apartment_ui_scene.instantiate()
	add_child_autofree(apartment_ui)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get apartment and test movement
	var term_root = apartment_ui.get_node("%MainPanel/TermRoot")
	var apartment = term_root.get_node("InteractiveApartment")
	
	var initial_pos = apartment.get_player_position()
	print("[Test] Initial position: ", initial_pos)
	
	# Test movement
	apartment.handle_input("ui_right")
	await get_tree().process_frame
	
	var new_pos = apartment.get_player_position()
	print("[Test] Position after right: ", new_pos)
	
	# Check if movement worked (depends on what's to the right)
	var expected_pos = initial_pos + Vector2i(1, 0)
	if apartment._is_passable(expected_pos):
		assert_eq(new_pos, expected_pos, "Should move right if passable")
	else:
		assert_eq(new_pos, initial_pos, "Should not move if blocked")
	
	print("[Test] Movement test completed")

func test_apartment_main_ui_rendering():
	# Load our new apartment main UI scene
	var apartment_ui_scene = preload("res://scenes/ui/apartment_main_ui.tscn")
	var apartment_ui = apartment_ui_scene.instantiate()
	add_child_autofree(apartment_ui)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get canvas and trigger rendering
	var ascii_canvas = apartment_ui.get_node("%MainPanel/AsciiCanvas")
	assert_not_null(ascii_canvas, "AsciiCanvas should exist")
	
	ascii_canvas.render()
	await get_tree().process_frame
	
	# Get apartment and verify it's rendering
	var term_root = apartment_ui.get_node("%MainPanel/TermRoot")
	var apartment = term_root.get_node("InteractiveApartment")
	
	var player_pos = apartment.get_player_position()
	var player_cell = apartment.get_cell(player_pos)
	assert_eq(player_cell.character, "@", "Player should render as @")
	
	print("[Test] Apartment main UI rendering verified")
