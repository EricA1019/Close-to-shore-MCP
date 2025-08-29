extends GutTest

## Test the sizing and positioning of InteractiveApartment when auto-spawned into MainUI

func test_apartment_sizing_in_main_ui():
	# Set location to Apartment to trigger auto-spawn
	var location_state = get_node("/root/LocationState")
	location_state.change_location("Apartment")
	
	# Load MainUI
	var scene = preload("res://scenes/ui/main_ui.tscn").instantiate()
	add_child_autofree(scene)
	
	# Wait for initialization and auto-spawn
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find the AsciiCanvas and InteractiveApartment
	var ascii_canvas = scene.get_node("%MainPanel/AsciiCanvas")
	var term_root = scene.get_node("%MainPanel/TermRoot")
	var apartment := term_root.get_node_or_null("InteractiveApartment")
	
	assert_not_null(ascii_canvas, "AsciiCanvas should exist")
	assert_not_null(apartment, "InteractiveApartment should be spawned")
	
	# Check AsciiCanvas grid size
	var grid_size = ascii_canvas.grid_size
	print("[Test] AsciiCanvas grid_size: ", grid_size)
	assert_eq(grid_size, Vector2i(30, 16), "AsciiCanvas should have 30x16 grid")
	
	# Check apartment size
	var apartment_size = apartment.get_apartment_size()
	print("[Test] Apartment size: ", apartment_size)
	assert_eq(apartment_size, Vector2i(28, 16), "Apartment should be 28x16")
	
	# Check apartment rect positioning
	var apartment_rect = apartment.get_rect()
	print("[Test] Apartment rect: ", apartment_rect)
	
	# The apartment should fill most/all of the available space
	assert_gte(apartment_rect.size.x, 20, "Apartment rect width should be reasonable")
	assert_gte(apartment_rect.size.y, 10, "Apartment rect height should be reasonable")

func test_apartment_canvas_cell_positions():
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
	
	# Force a render
	ascii_canvas.render()
	await get_tree().process_frame
	
	# Check for canvas cells rendered by apartment
	var canvas_cells = apartment.get_canvas_cells()
	print("[Test] Apartment canvas cells count: ", canvas_cells.size())
	assert_gt(canvas_cells.size(), 0, "Apartment should have some canvas cells")
	
	# Check player position
	var player_pos = apartment.get_player_position()
	print("[Test] Player position: ", player_pos)
	assert_true(player_pos.x >= 0 and player_pos.y >= 0, "Player should have valid position")
	
	# Find the player cell in canvas cells
	var player_cell = null
	for cell in canvas_cells:
		if cell.character == "@":
			player_cell = cell
			break
	
	assert_not_null(player_cell, "Player character should be in canvas cells")
	print("[Test] Player cell position: ", player_cell.position)

func test_term_root_child_sizing():
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
	var term_root = scene.get_node("%MainPanel/TermRoot")
	var apartment := term_root.get_node_or_null("InteractiveApartment")
	
	assert_not_null(apartment, "InteractiveApartment should be spawned")
	
	# Check what other elements are in TermRoot and their sizes
	print("[Test] TermRoot children:")
	for child in term_root.get_children():
		if child is TermElement:
			var fixed_size = child.fixed_size
			var rect = child.get_rect()
			print("  - ", child.name, " fixed_size:", fixed_size, " rect:", rect)
			
			if child.name == "InteractiveApartment":
				# The apartment should have the majority of the vertical space
				assert_gt(rect.size.y, 5, "Apartment should get significant vertical space")
