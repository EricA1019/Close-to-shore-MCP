extends GutTest

## Test comparing apartment behavior in standalone vs MainUI context

func test_standalone_apartment_size():
	# Load just the InteractiveApartment scene
	var apartment_scene = preload("res://scenes/ui/interactive_apartment.tscn")
	var apartment = apartment_scene.instantiate()
	add_child_autofree(apartment)
	
	await get_tree().process_frame
	
	# Check its intrinsic size
	var size = apartment.get_apartment_size()
	var fixed_size = apartment.fixed_size
	var rect = apartment.get_rect()
	
	print("[Test] Standalone apartment:")
	print("  size:", size)
	print("  fixed_size:", fixed_size)
	print("  rect:", rect)
	
	assert_eq(size, Vector2i(28, 16), "Apartment size should be 28x16")

func test_apartment_in_main_ui_context():
	# Set location to Apartment to trigger auto-spawn
	var location_state = get_node("/root/LocationState")
	location_state.change_location("Apartment")
	
	# Load MainUI which should auto-spawn apartment
	var scene = preload("res://scenes/ui/main_ui.tscn").instantiate()
	add_child_autofree(scene)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find the apartment
	var term_root = scene.get_node("%MainPanel/TermRoot")
	var apartment := term_root.get_node_or_null("InteractiveApartment")
	
	assert_not_null(apartment, "InteractiveApartment should be spawned")
	
	# Check its size in MainUI context
	var size = apartment.get_apartment_size()
	var fixed_size = apartment.fixed_size
	var rect = apartment.get_rect()
	
	print("[Test] MainUI apartment:")
	print("  size:", size)
	print("  fixed_size:", fixed_size)
	print("  rect:", rect)
	
	# The size should be the same
	assert_eq(size, Vector2i(28, 16), "Apartment size should be 28x16 in MainUI")
	
	# But the rect might be different due to TermRoot layout
	print("[Test] Rect position:", rect.position, " size:", rect.size)

func test_term_root_layout_allocation():
	# Set location to Apartment to trigger auto-spawn
	var location_state = get_node("/root/LocationState")
	location_state.change_location("Apartment")
	
	# Load MainUI which should auto-spawn apartment
	var scene = preload("res://scenes/ui/main_ui.tscn").instantiate()
	add_child_autofree(scene)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check the total available space
	var ascii_canvas = scene.get_node("%MainPanel/AsciiCanvas")
	var term_root = scene.get_node("%MainPanel/TermRoot")
	var apartment := term_root.get_node_or_null("InteractiveApartment")
	
	assert_not_null(apartment, "InteractiveApartment should be spawned")
	
	# Get the TermRoot's total rect
	var term_root_rect = term_root.get_rect()
	print("[Test] TermRoot total rect:", term_root_rect)
	print("[Test] AsciiCanvas grid_size:", ascii_canvas.grid_size)
	
	# Check how space is divided among children
	print("[Test] TermRoot children allocation:")
	var total_fixed_height = 0
	for child in term_root.get_children():
		if child is TermElement:
			var child_rect = child.get_rect()
			var child_fixed = child.fixed_size
			print("  ", child.name, ":")
			print("    fixed_size:", child_fixed)
			print("    rect:", child_rect)
			total_fixed_height += child_fixed.y
	
	print("[Test] Total fixed height used:", total_fixed_height)
	print("[Test] Available height:", ascii_canvas.grid_size.y)
	
	# The apartment should get most of the remaining space
	var apartment_rect = apartment.get_rect()
	assert_gt(apartment_rect.size.y, 8, "Apartment should get significant height in layout")
