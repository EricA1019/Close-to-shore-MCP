extends GutTest

## Validate InputBus drives InteractiveApartment input without direct calls

func before_each():
	# Ensure InputBus exists
	var bus = get_tree().get_root().get_node_or_null("/root/InputBus")
	assert_not_null(bus, "InputBus autoload should be present")

func test_input_bus_moves_right():
	var scene = preload("res://scenes/ui/main_ui.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
    
	# Ensure Apartment location is active so InteractiveApartment is spawned into MainUI
	LocationState.change_location("Apartment")
	await get_tree().process_frame
	await get_tree().process_frame
    
	var apt: Node = scene.find_child("InteractiveApartment", true, false)
	assert_not_null(apt, "InteractiveApartment should exist")
	var start: Vector2i = apt.get_player_position()
	
	var bus = get_tree().get_root().get_node("/root/InputBus")
	bus.emit_action("ui_right", true)
	await get_tree().process_frame
	var pos_after: Vector2i = apt.get_player_position()
	
	var expected = start + Vector2i(1, 0)
	if apt._is_passable(expected):
		assert_eq(pos_after, expected, "Should move right via InputBus action")
	else:
		assert_eq(pos_after, start, "Should not move if blocked")

func test_input_bus_interact():
	var scene = preload("res://scenes/ui/main_ui.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
    
	# Ensure Apartment location is active so InteractiveApartment is spawned into MainUI
	LocationState.change_location("Apartment")
	await get_tree().process_frame
	await get_tree().process_frame
    
	var apt: Node = scene.find_child("InteractiveApartment", true, false)
	assert_not_null(apt, "InteractiveApartment should exist")
	
	var bus = get_tree().get_root().get_node("/root/InputBus")
	bus.emit_action("ui_accept", true)
	await get_tree().process_frame
	
	var last: Dictionary = apt.get_last_interaction()
	assert_true(last.has("timestamp"), "Interaction should be recorded via InputBus")
