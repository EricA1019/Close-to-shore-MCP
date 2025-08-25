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

func _get_selected_title(ui: Node) -> String:
	var output_panel: Node = ui.get_node("%OutputPanel")
	# Try to find a label that shows description; we assert on description substring instead
	var label: Label = output_panel.find_child("Label", true, false)
	if label == null:
		for n in output_panel.get_children():
			if n is Label:
				label = n
				break
	return label.text if label else ""

func test_keyboard_cycles_pois() -> void:
	var ui := await _spawn_ui()
	var apt := await _spawn_apartment()
	await get_tree().process_frame
	# Initial selection should be Desk (due to auto-select)
	var desc0 := _get_selected_title(ui)
	assert_true(desc0.findn("desk") != -1 or desc0.findn("Desk") != -1, "Desk selected by default")
	# Simulate right press by calling Apartment._input with InputEventAction to avoid focus issues
	var e := InputEventAction.new()
	e.action = "ui_right"
	e.pressed = true
	# Simulate user input via _input (engine callback)
	apt._input(e)
	await get_tree().process_frame
	# Now selection should change to Door (second POI)
	var desc1 := _get_selected_title(ui)
	assert_true(desc1.findn("door") != -1 or desc1.findn("Door") != -1, "Moved selection to Door")
	# Simulate accept to trigger first action
	var e2 := InputEventAction.new()
	e2.action = "ui_accept"
	e2.pressed = true
	# Simulate user input via _input (engine callback)
	apt._input(e2)
	await get_tree().process_frame
	# No strict assert on side-effects, but ensure no error and ActionPanel populated
	var action_panel: Node = ui.get_node("%ActionPanel")
	var has_buttons := false
	for c in action_panel.get_children():
		if c is Button:
			has_buttons = true
			break
		elif c is Container:
			for c2 in c.get_children():
				if c2 is Button:
					has_buttons = true
					break
	assert_true(has_buttons, "ActionPanel has actions after selection and accept")
