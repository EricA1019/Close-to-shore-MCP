extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"
const APARTMENT_SCENE := "res://scenes/locations/apartment/apartment.tscn"

func _spawn_ui() -> Node:
	var scene: PackedScene = load(UI_SCENE)
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	return inst

func _spawn_apartment() -> Node:
	var scene: PackedScene = load(APARTMENT_SCENE)
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	return inst

func test_action_panel_keyboard_selection() -> void:
	var ui := await _spawn_ui()
	var apt := await _spawn_apartment()
	await get_tree().process_frame
	
	# Select Desk to populate actions
	var desk := apt.find_child("Desk", true, false)
	assert_not_null(desk, "Desk POI exists")
	if desk.has_method("select"):
		desk.call("select")
	await get_tree().process_frame
	
	# Check that ActionPanel shows keyboard hints with numbered actions
	var action_panel: Node = ui.get_node("%ActionPanel")
	var hints: Label = action_panel.find_child("Hints", true, false)
	assert_not_null(hints, "ActionPanel has hints label")
	
	# Verify it shows numbered actions
	var hints_text = hints.text
	print("[Test] ActionPanel hints text: ", hints_text)
	assert_true(hints_text.findn("[1]") != -1, "Shows [1] key hint")
	assert_true(hints_text.findn("[2]") != -1, "Shows [2] key hint")
	assert_true(hints_text.findn("Inspect drawers") != -1 or hints_text.findn("Examine documents") != -1, "Shows action text")

func test_action_panel_keyboard_input() -> void:
	var ui := await _spawn_ui()
	var apt := await _spawn_apartment()
	await get_tree().process_frame
	
	# Select Desk to populate actions
	var desk := apt.find_child("Desk", true, false)
	assert_not_null(desk, "Desk POI exists")
	if desk.has_method("select"):
		desk.call("select")
	await get_tree().process_frame
	
	# Capture action emission
	var action_panel: Node = ui.get_node("%ActionPanel")
	var captured := {"id": null}
	if action_panel.has_signal("action_chosen"):
		action_panel.connect("action_chosen", func(id): captured.id = id)
	
	# Simulate pressing "1" key to select first action
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_1
	key_event.pressed = true
	
	# Send the key event to ActionPanel
	action_panel._input(key_event)
	await get_tree().process_frame
	
	assert_not_null(captured.id, "Action was triggered by keyboard")
	print("[Test] Captured action ID: ", captured.id)
	assert_true(captured.id.length() > 0, "Action ID is not empty")

func test_input_bus_action_integration() -> void:
	var ui := await _spawn_ui()
	var apt := await _spawn_apartment()
	await get_tree().process_frame
	
	# Verify InputBus is accessible
	var input_bus = get_node("/root/InputBus")
	assert_not_null(input_bus, "InputBus autoload exists")
	
	# Test movement command through InputBus
	var initial_pos = apt.get_current_pos() if apt.has_method("get_current_pos") else Vector2.ZERO
	print("[Test] Initial position: ", initial_pos)
	
	# Emit movement command through InputBus
	input_bus.emit_command("move", {"direction": "right"})
	await get_tree().process_frame
	
	print("[Test] InputBus integration test completed")
