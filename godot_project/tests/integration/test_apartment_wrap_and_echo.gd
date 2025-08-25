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

func _get_desc(ui: Node) -> String:
	var output_panel: Node = ui.get_node("%OutputPanel")
	var label: Label = output_panel.find_child("Label", true, false)
	return label.text if label else ""

func test_wraps_left_right_and_ignores_echo() -> void:
	var ui := await _spawn_ui()
	var apt := await _spawn_apartment()
	await get_tree().process_frame
	# default Desk
	var d0 := _get_desc(ui)
	assert_true(d0.findn("desk") != -1 or d0.findn("Desk") != -1)
	# Move right 3 times should wrap back to Desk (3 POIs)
	for i in 3:
		var e := InputEventAction.new()
		e.action = "ui_right"
		e.pressed = true
		# Engine callback _input is an allowed entrypoint in tests to simulate user input
		apt._input(e)
		await get_tree().process_frame
	var d1 := _get_desc(ui)
	assert_true(d1.findn("desk") != -1 or d1.findn("Desk") != -1, "Wrapped back to Desk after 3 rights")
	# Send echo events and ensure description doesn't change
	var before := _get_desc(ui)
	var key := InputEventKey.new()
	key.keycode = KEY_DOWN
	key.pressed = true
	key.echo = true
	# Engine callback _input is allowed in tests
	apt._input(key)
	await get_tree().process_frame
	var after := _get_desc(ui)
	assert_eq(before, after, "Echo did not trigger navigation")

func test_up_down_are_aliases() -> void:
	var ui := await _spawn_ui()
	var apt := await _spawn_apartment()
	await get_tree().process_frame
	# Move down once (alias of right)
	var e1 := InputEventAction.new()
	e1.action = "ui_down"
	e1.pressed = true
	# Simulate user input via _input
	apt._input(e1)
	await get_tree().process_frame
	var d1 := _get_desc(ui)
	assert_true(d1.findn("door") != -1 or d1.findn("Door") != -1, "Down moved to Door")
	# Move up should move back to Desk
	var e2 := InputEventAction.new()
	e2.action = "ui_up"
	e2.pressed = true
	# Simulate user input via _input
	apt._input(e2)
	await get_tree().process_frame
	var d2 := _get_desc(ui)
	assert_true(d2.findn("desk") != -1 or d2.findn("Desk") != -1, "Up moved back to Desk")
