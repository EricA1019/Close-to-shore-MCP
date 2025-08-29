extends GutTest

## Test that BasicRoom is properly integrated into main UI

func test_main_ui_has_basic_room():
	# Ensure we start from the BasicRoom location (explicitly set, default is now interactive Apartment)
	if has_node("/root/LocationState"):
		get_node("/root/LocationState").set_location("Your Apartment")
	# Load the main UI scene
	var main_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var main_ui = main_ui_scene.instantiate()
	add_child_autofree(main_ui)
	
	# Wait for _ready to complete
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find the BasicRoom node in TermRoot
	var term_root = main_ui.get_node("%MainPanel/TermRoot")
	assert_not_null(term_root, "TermRoot should exist in main UI")
	
	var basic_room = term_root.get_node_or_null("BasicRoom")
	assert_not_null(basic_room, "BasicRoom should exist in TermRoot")
	
	# Verify it has the Canvas blit method
	assert_true(basic_room.has_method("_blit_self_under_canvas"), "BasicRoom should have Canvas support")

func test_basic_room_renders_in_main_ui():
	# Ensure we start from the BasicRoom location (explicitly set, default is now interactive Apartment)
	if has_node("/root/LocationState"):
		get_node("/root/LocationState").set_location("Your Apartment")
	# Load the main UI scene
	var main_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var main_ui = main_ui_scene.instantiate()
	add_child_autofree(main_ui)
	
	# Wait for initialization
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get the AsciiCanvas and trigger rendering
	var ascii_canvas = main_ui.get_node("%MainPanel/AsciiCanvas")
	assert_not_null(ascii_canvas, "AsciiCanvas should exist")
	
	ascii_canvas.render()
	await get_tree().process_frame
	
	# Check if the buffer has content (room should render something)
	var buffer = ascii_canvas.buffer
	assert_not_null(buffer, "AsciiCanvas should have a buffer")
	
	var non_clear_cells = 0
	var buffer_size = buffer.get_size()
	for x in range(buffer_size.x):
		for y in range(buffer_size.y):
			var cell = buffer.get_cell(Vector2i(x, y))
			if cell and cell.character != " ":
				non_clear_cells += 1
	
	assert_gt(non_clear_cells, 0, "Main UI should render ASCII content from BasicRoom")
	print("[Test] Main UI rendered ", non_clear_cells, " non-clear cells")

func test_location_state_set_correctly():
	# Ensure we start from the BasicRoom location (explicitly set, default is now interactive Apartment)
	if has_node("/root/LocationState"):
		get_node("/root/LocationState").set_location("Your Apartment")
	# Load the main UI scene
	var main_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var main_ui = main_ui_scene.instantiate()
	add_child_autofree(main_ui)
	
	# Wait for _ready to complete
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check that location was set correctly
	var location_state = get_node("/root/LocationState")
	assert_not_null(location_state, "LocationState autoload should exist")
	
	var current_location = location_state.get_location()
	assert_eq(current_location, "Your Apartment", "Location should be set to 'Your Apartment'")
