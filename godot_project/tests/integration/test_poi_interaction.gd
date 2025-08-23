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

func _get_action_buttons(panel: Node) -> Array:
	var buttons: Array = []
	for child in panel.get_children():
		if child is Button:
			buttons.append(child)
		elif child is Container:
			for c2 in child.get_children():
				if c2 is Button:
					buttons.append(c2)
	return buttons

func test_poi_selection_updates_panels() -> void:
	var ui := await _spawn_ui()
	var apt := await _spawn_apartment()
	await get_tree().process_frame
	# Find a POI named "Desk" and select it
	var desk := apt.find_child("Desk", true, false)
	assert_not_null(desk, "Desk POI exists")
	if desk.has_method("select"):
		desk.call("select")
	await get_tree().process_frame
	# Check OutputPanel description
	var output_panel: Node = ui.get_node("%OutputPanel")
	var label: Label = output_panel.find_child("Label", true, false)
	if label == null:
		# fallback: get first Label
		for n in output_panel.get_children():
			if n is Label:
				label = n
				break
	assert_not_null(label, "Output label exists")
	assert_true(label.text.findn("A cluttered wooden desk") != -1, "Description contains desk text")
	# Check ActionPanel has expected buttons
	var action_panel: Node = ui.get_node("%ActionPanel")
	var buttons := _get_action_buttons(action_panel)
	var names := buttons.map(func(b): return (b as Button).text)
	assert_true(names.has("Inspect drawers"))
	assert_true(names.has("Examine documents"))

func test_action_emission() -> void:
	var ui := await _spawn_ui()
	var apt := await _spawn_apartment()
	await get_tree().process_frame
	# Select Desk to populate actions
	var desk := apt.find_child("Desk", true, false)
	assert_not_null(desk)
	if desk.has_method("select"):
		desk.call("select")
	await get_tree().process_frame
	# Capture action
	var action_panel: Node = ui.get_node("%ActionPanel")
	var captured := {"id": null}
	if action_panel.has_signal("action_chosen"):
		action_panel.connect("action_chosen", func(id): captured.id = id)
	# Press the "Inspect drawers" button
	var buttons := _get_action_buttons(action_panel)
	var target: Button = null
	for b in buttons:
		if (b as Button).text == "Inspect drawers":
			target = b
			break
	assert_not_null(target, "Found Inspect drawers button")
	target.emit_signal("pressed")
	await get_tree().process_frame
	assert_eq(captured.id, "desk.inspect_drawers")
