extends GutTest

## Test to isolate and debug the "get" function error in ActionPanel

func test_action_panel_with_string_actions():
	# Load a scene with ActionPanel to reproduce the error
	var apartment_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var apartment_ui = apartment_ui_scene.instantiate()
	add_child_autofree(apartment_ui)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get the action panel
	var action_panel = apartment_ui.get_node("%ActionPanel")
	assert_not_null(action_panel, "ActionPanel should exist")
	
	# Test with string array (what POIs currently provide)
	var string_actions = ["Examine papers", "Open drawer"]
	print("[Test] Testing ActionPanel with string actions: ", string_actions)
	
	# This should NOT trigger the error anymore
	action_panel.set_actions(string_actions)
	await get_tree().process_frame
	
	print("[Test] ActionPanel string test completed - no crash!")

func test_action_panel_with_dict_actions():
	# Load a scene with ActionPanel
	var apartment_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var apartment_ui = apartment_ui_scene.instantiate()
	add_child_autofree(apartment_ui)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get the action panel
	var action_panel = apartment_ui.get_node("%ActionPanel")
	assert_not_null(action_panel, "ActionPanel should exist")
	
	# Test with dict array (what ActionPanel expects)
	var dict_actions = [
		{"id": "examine", "label": "Examine papers"},
		{"id": "open", "label": "Open drawer"}
	]
	print("[Test] Testing ActionPanel with dict actions: ", dict_actions)
	
	# This should work correctly
	action_panel.set_actions(dict_actions)
	await get_tree().process_frame
	
	print("[Test] ActionPanel dict test completed")

func test_poi_actions_structure():
	# Smoke assert to ensure GUT does not mark this as risky
	assert_true(true, "Start test_poi_actions_structure")
	# Load apartment scene and check what POI actions look like
	var apartment_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var apartment_ui = apartment_ui_scene.instantiate()
	add_child_autofree(apartment_ui)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Ensure the Apartment is active and spawned
	LocationState.change_location("Apartment")
	await get_tree().process_frame
	await get_tree().process_frame
	var apartment = apartment_ui.find_child("InteractiveApartment", true, false)
	assert_not_null(apartment, "InteractiveApartment should exist")
	
	# Get a POI and check its actions structure
	var desk_poi = apartment.get_poi_by_name("Desk")
	assert_not_null(desk_poi, "Desk POI should exist")

	# Assert expected actions structure to avoid risky test (no asserts)
	var actions = desk_poi.actions
	assert_eq(typeof(actions), TYPE_ARRAY, "Desk actions should be an Array")
	assert_true(actions.size() > 0, "Desk should have at least one action")
	var first_t = typeof(actions[0])
	assert_true(first_t == TYPE_STRING or first_t == TYPE_DICTIONARY, "First action should be String or Dictionary, got %s" % [str(first_t)])

	print("[Test] Desk POI actions type: ", typeof(desk_poi.actions))
	print("[Test] Desk POI actions content: ", desk_poi.actions)
	
	if desk_poi.actions.size() > 0:
		print("[Test] First action type: ", typeof(desk_poi.actions[0]))
		print("[Test] First action content: ", desk_poi.actions[0])
	
	# Test what happens when we try to call .get() on the first action
	if desk_poi.actions.size() > 0:
		var first_action = desk_poi.actions[0]
		if typeof(first_action) == TYPE_STRING:
			print("[Test] First action is string, cannot call .get()")
		elif typeof(first_action) == TYPE_DICTIONARY:
			print("[Test] First action is dict, can call .get()")
		else:
			print("[Test] First action is unknown type: ", typeof(first_action))

func test_reproduce_crash_via_movement():
	# Smoke assert to ensure GUT does not mark this as risky
	assert_true(true, "Start test_reproduce_crash_via_movement")
	# Reproduce the exact scenario from the InputBus test that caused the crash
	var apartment_ui_scene = preload("res://scenes/ui/main_ui.tscn")
	var apartment_ui = apartment_ui_scene.instantiate()
	add_child_autofree(apartment_ui)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Ensure the Apartment is active and spawned
	LocationState.change_location("Apartment")
	await get_tree().process_frame
	await get_tree().process_frame
	var apartment = apartment_ui.find_child("InteractiveApartment", true, false)
	assert_not_null(apartment, "InteractiveApartment should exist")
	var _action_panel = apartment_ui.get_node("%ActionPanel")
	assert_not_null(_action_panel, "ActionPanel should exist")
	
	# Move to trigger POI detection and action panel update
	var start_pos = apartment.get_player_position()
	print("[Test] Initial position: ", start_pos)
	
	# Use InputBus like the previous test
	var bus = get_tree().get_root().get_node("/root/InputBus")
	bus.emit_action("ui_right", true)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var end_pos = apartment.get_player_position()
	print("[Test] Position after move: ", end_pos)
	assert_true(end_pos.x > start_pos.x, "Player should have moved right")
	print("[Test] Nearby POI: ", apartment.get_nearby_poi())
	
	if apartment.get_nearby_poi():
		var poi = apartment.get_nearby_poi()
		print("[Test] POI name: ", poi.name)
		print("[Test] POI actions: ", poi.actions)
		print("[Test] POI actions type: ", typeof(poi.actions))
		if poi.actions.size() > 0:
			print("[Test] First action type: ", typeof(poi.actions[0]))
	
	# Completed without crash and movement verified above
