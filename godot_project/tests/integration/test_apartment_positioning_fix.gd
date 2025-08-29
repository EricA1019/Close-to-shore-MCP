extends GutTest

## Test that apartment positioning fix actually shows the apartment content properly

func test_apartment_content_visible():
	# Set location to Apartment to trigger auto-spawn
	var location_state = get_node("/root/LocationState")
	location_state.change_location("Apartment")
	
	# Load MainUI
	var scene = preload("res://scenes/ui/main_ui.tscn").instantiate()
	add_child_autofree(scene)
	
	# Wait for initialization and auto-spawn
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find components
	var ascii_canvas = scene.get_node("%MainPanel/AsciiCanvas")
	var term_root = scene.get_node("%MainPanel/TermRoot")
	var apartment := term_root.get_node_or_null("InteractiveApartment")
	
	assert_not_null(apartment, "InteractiveApartment should be spawned")
	
	# Check apartment positioning - should start near the top, not at Y=11
	var apartment_rect = apartment.get_rect()
	assert_lt(apartment_rect.position.y, 5, "Apartment should be positioned near top, not pushed down")
	assert_gte(apartment_rect.size.y, 12, "Apartment should have substantial height")
	
	# Force a render and check content
	ascii_canvas.render()
	await get_tree().process_frame
	
	# Verify conflicting elements are hidden during apartment mode
	var apartment_map := term_root.get_node_or_null("ApartmentMap")
	var test_pattern := term_root.get_node_or_null("TestPattern")
	assert_null(apartment_map, "ApartmentMap should be hidden when apartment is active")
	assert_null(test_pattern, "TestPattern should be hidden when apartment is active")
	
	# Verify substantial content is rendered
	var canvas_cells = apartment.get_canvas_cells()
	assert_gt(canvas_cells.size(), 300, "Apartment should have substantial visible content")
	
	# Check player is in a reasonable position within the visible area
	var player_pos = apartment.get_player_position()
	var world_player_pos = apartment_rect.position + player_pos
	assert_lt(world_player_pos.y, 16, "Player should be within visible canvas bounds")
	assert_gte(world_player_pos.y, 0, "Player should be above canvas bottom")
	
	print("[Test] Apartment content properly positioned and visible")
	print("  Apartment rect:", apartment_rect)
	print("  Player world pos:", world_player_pos)
	print("  Canvas cells:", canvas_cells.size())

func test_apartment_elements_restored_on_location_change():
	# Start with apartment active
	var location_state = get_node("/root/LocationState")
	location_state.change_location("Apartment")
	
	var scene = preload("res://scenes/ui/main_ui.tscn").instantiate()
	add_child_autofree(scene)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var term_root = scene.get_node("%MainPanel/TermRoot")
	
	# Verify apartment is active and other elements hidden
	var apartment := term_root.get_node_or_null("InteractiveApartment")
	assert_not_null(apartment, "InteractiveApartment should be spawned")
	
	var apartment_map := term_root.get_node_or_null("ApartmentMap")
	var test_pattern := term_root.get_node_or_null("TestPattern")
	assert_null(apartment_map, "ApartmentMap should be hidden during apartment mode")
	assert_null(test_pattern, "TestPattern should be hidden during apartment mode")
	
	# Switch location away from apartment
	location_state.change_location("Street")
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verify apartment is despawned and other elements restored
	apartment = term_root.get_node_or_null("InteractiveApartment")
	apartment_map = term_root.get_node_or_null("ApartmentMap")
	test_pattern = term_root.get_node_or_null("TestPattern")
	
	assert_null(apartment, "InteractiveApartment should be despawned")
	assert_not_null(apartment_map, "ApartmentMap should be restored")
	assert_not_null(test_pattern, "TestPattern should be restored")
	
	print("[Test] Elements properly restored when leaving apartment")
