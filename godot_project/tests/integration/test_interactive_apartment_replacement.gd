extends GutTest

## Test replacing existing apartment with our InteractiveApartment

const UI_SCENE := "res://scenes/ui/main_ui.tscn"

func test_replace_apartment_map_with_interactive():
	# Load main UI 
	var main_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var main_ui = main_ui_scene.instantiate()
	add_child_autofree(main_ui)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get the TermRoot
	var term_root = main_ui.get_node("%MainPanel/TermRoot")
	assert_not_null(term_root, "TermRoot should exist")
	
	# Find and remove existing ApartmentMap
	var apartment_map = term_root.get_node("ApartmentMap")
	if apartment_map:
		apartment_map.queue_free()
		await get_tree().process_frame
	
	# Add our InteractiveApartment
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	apartment.name = "InteractiveApartment"
	term_root.add_child(apartment)
	
	await get_tree().process_frame
	
	# Test basic functionality
	assert_not_null(apartment, "InteractiveApartment should be added")
	assert_true(apartment.has_method("get_player_position"), "Should have player position")
	assert_true(apartment.has_method("handle_input"), "Should handle input")
	
	# Test initial player position
	var player_pos = apartment.get_player_position()
	assert_eq(player_pos, Vector2i(5, 2), "Player should start at expected position")
	
	# Test rendering integration
	var ascii_canvas = main_ui.get_node("%MainPanel/AsciiCanvas")
	ascii_canvas.render()
	await get_tree().process_frame
	
	print("[Test] InteractiveApartment successfully replaced ApartmentMap")

func test_interactive_apartment_basic_movement():
	# Load main UI without apartment scene to avoid conflicts
	var main_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var main_ui = main_ui_scene.instantiate()
	add_child_autofree(main_ui)
	
	await get_tree().process_frame
	
	# Get TermRoot and clear existing apartment components
	var term_root = main_ui.get_node("%MainPanel/TermRoot")
	var apartment_map = term_root.get_node("ApartmentMap")
	if apartment_map:
		apartment_map.queue_free()
		await get_tree().process_frame
	
	# Add just our InteractiveApartment
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	term_root.add_child(apartment)
	
	await get_tree().process_frame
	
	# Test movement
	var initial_pos = apartment.get_player_position()
	print("[Test] Initial position: ", initial_pos)
	
	# Test input handling
	apartment.handle_input("ui_right")
	await get_tree().process_frame
	
	var new_pos = apartment.get_player_position()
	print("[Test] Position after right: ", new_pos)
	
	# Movement should work based on collision detection
	var expected_new_pos = initial_pos + Vector2i(1, 0)
	if apartment._is_passable(expected_new_pos):
		assert_eq(new_pos, expected_new_pos, "Should move right if clear")
	else:
		assert_eq(new_pos, initial_pos, "Should not move if blocked")
	
	print("[Test] Movement test completed successfully")

func test_interactive_apartment_canvas_rendering():
	# Simple standalone test
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	add_child_autofree(apartment)
	
	await get_tree().process_frame
	
	# Test basic structure
	assert_true(apartment.has_method("get_apartment_size"), "Should have size method")
	var size = apartment.get_apartment_size()
	assert_eq(size, Vector2i(28, 16), "Should have correct size")
	
	# Test cell access
	var player_pos = apartment.get_player_position()
	var player_cell = apartment.get_cell(player_pos)
	assert_eq(player_cell.character, "@", "Player cell should be @")
	
	print("[Test] Basic apartment functionality verified")
