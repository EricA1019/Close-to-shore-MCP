extends GutTest

var MainUI = preload("res://scenes/ui/main_ui.tscn")
var main_ui

func before_each():
	main_ui = MainUI.instantiate()
	add_child(main_ui)
	await get_tree().process_frame

func after_each():
	main_ui.queue_free()

func test_actions_are_laid_out_horizontally():
	var action_panel = main_ui.find_child("ActionPanel")
	assert_not_null(action_panel, "ActionPanel should exist")

	var actions = [
		{"label": "Inspect", "id": "inspect"},
		{"label": "Use", "id": "use"},
		{"label": "Talk", "id": "talk"}
	]
	action_panel.set_actions(actions)
	
	# Wait a couple of frames for the UI to fully update
	await get_tree().process_frame
	await get_tree().process_frame

	var hints_label = action_panel.get_node_or_null("Hints")
	assert_not_null(hints_label, "Hints label should exist after setting actions")

	var text = hints_label.text
	assert_true(text.contains("[1] Inspect"), "Text should contain first action")
	assert_true(text.contains("[2] Use"), "Text should contain second action")
	assert_true(text.contains("[3] Talk"), "Text should contain third action")

	# The entire text should be on a single line
	assert_false(text.contains("\n"), "Text should not contain newlines for horizontal layout. Full text: " + text)
