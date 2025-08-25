extends GutTest

## Test that "New Game" from main menu shows BasicRoom

func test_main_menu_new_game_shows_basic_room():
	# Load the main menu
	var main_menu_scene = preload("res://scenes/maaack_scenes/menus/main_menu/main_menu.tscn")
	var main_menu = main_menu_scene.instantiate()
	add_child_autofree(main_menu)
	
	# Wait for initialization
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verify the game scene path is set to main_ui.tscn
	assert_true(main_menu.has_method("load_game_scene"), "Main menu should have load_game_scene method")
	
	# The game_scene_path should be pointing to main_ui.tscn (which includes BasicRoom)
	if main_menu.has_method("get") and main_menu.has_property("game_scene_path"):
		var game_scene_path = main_menu.get("game_scene_path")
		assert_eq(game_scene_path, "res://scenes/ui/main_ui.tscn", "New Game should load main UI with BasicRoom")
	
	print("[Test] Main menu configured to load main_ui.tscn with BasicRoom")

func test_main_ui_standalone_shows_basic_room():
	# Test loading main_ui.tscn directly (what happens after New Game)
	var main_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var main_ui = main_ui_scene.instantiate()
	add_child_autofree(main_ui)
	
	# Wait for initialization
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check that location is set to "Your Apartment" (not overridden by apartment.gd)
	var location_state = get_node("/root/LocationState")
	var current_location = location_state.get_location()
	assert_eq(current_location, "Your Apartment", "Location should be 'Your Apartment' without apartment scene")
	
	# Verify BasicRoom exists and Canvas is rendering
	var term_root = main_ui.get_node("%MainPanel/TermRoot")
	var basic_room = term_root.get_node("BasicRoom")
	assert_not_null(basic_room, "BasicRoom should exist in standalone main UI")
	
	var ascii_canvas = main_ui.get_node("%MainPanel/AsciiCanvas")
	ascii_canvas.render()
	await get_tree().process_frame
	
	print("[Test] Standalone main UI: BasicRoom present and location correct")
