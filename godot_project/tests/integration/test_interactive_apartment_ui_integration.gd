extends GutTest

## Test InteractiveApartment integration with main UI

const UI_SCENE := "res://scenes/ui/main_ui.tscn"

func test_interactive_apartment_loads_in_main_ui():
	# Load the main UI scene
	var main_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var main_ui = main_ui_scene.instantiate()
	add_child_autofree(main_ui)
	
	# Wait for initialization
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get TermRoot
	var term_root = main_ui.get_node("%MainPanel/TermRoot")
	assert_not_null(term_root, "TermRoot should exist in main UI")
	
	# Load and add our InteractiveApartment to TermRoot
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	term_root.add_child(apartment)
	
	await get_tree().process_frame
	
	# Verify apartment is accessible
	var found_apartment = term_root.get_node("InteractiveApartment")
	assert_not_null(found_apartment, "InteractiveApartment should be added to TermRoot")
	
	# Verify it has required methods
	assert_true(apartment.has_method("get_apartment_size"), "Should have apartment size method")
	assert_true(apartment.has_method("get_player_position"), "Should have player position method")
	assert_true(apartment.has_method("handle_input"), "Should have input handling")
	
	print("[Test] InteractiveApartment integrated with main UI")

func test_interactive_apartment_renders_with_ascii_canvas():
	# Load the main UI scene
	var main_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var main_ui = main_ui_scene.instantiate()
	add_child_autofree(main_ui)
	
	# Wait for initialization
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get components
	var term_root = main_ui.get_node("%MainPanel/TermRoot")
	var ascii_canvas = main_ui.get_node("%MainPanel/AsciiCanvas")
	
	# Load and add our InteractiveApartment
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	term_root.add_child(apartment)
	
	await get_tree().process_frame
	
	# Trigger rendering
	ascii_canvas.render()
	await get_tree().process_frame
	
	# Check that apartment is rendering
	assert_true(apartment.has_method("_blit_self_under_canvas"), "Should have Canvas rendering method")
	
	# Verify player character exists
	var player_pos = apartment.get_player_position()
	var player_cell = apartment.get_cell(player_pos)
	assert_eq(player_cell.character, "@", "Player should be rendered as @")
	
	print("[Test] InteractiveApartment renders with AsciiCanvas")

func test_interactive_apartment_input_integration():
	# Load the main UI scene
	var main_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var main_ui = main_ui_scene.instantiate()
	add_child_autofree(main_ui)
	
	# Wait for initialization
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get TermRoot
	var term_root = main_ui.get_node("%MainPanel/TermRoot")
	
	# Load and add our InteractiveApartment
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	term_root.add_child(apartment)
	
	await get_tree().process_frame
	
	# Test input handling
	var initial_pos = apartment.get_player_position()
	print("[Test] Initial position: ", initial_pos)
	
	# Try moving right
	apartment.handle_input("ui_right")
	await get_tree().process_frame
	
	var new_pos = apartment.get_player_position()
	print("[Test] Position after move right: ", new_pos)
	
	# Should move if path is clear
	if apartment._is_passable(initial_pos + Vector2i(1, 0)):
		assert_ne(new_pos, initial_pos, "Player should move if path is clear")
	else:
		assert_eq(new_pos, initial_pos, "Player should not move if blocked")
	
	print("[Test] InteractiveApartment input handling works in main UI")
