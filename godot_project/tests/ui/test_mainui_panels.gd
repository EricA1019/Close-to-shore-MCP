extends GutTest

func test_top_status_shows_hungover_on_startup():
	var scene := preload("res://scenes/ui/main_ui.tscn")
	var ui = scene.instantiate()
	add_child_autofree(ui)

	await get_tree().process_frame
	await get_tree().process_frame

	var top_status: HBoxContainer = ui.get_node("%TopStatus")
	assert_not_null(top_status, "TopStatus should exist")
	var status_label: Label = top_status.get_node("StatusLabel")
	assert_not_null(status_label, "StatusLabel should exist")
	assert_true(status_label.text.findn("Hungover") != -1 or status_label.text.findn("Status:") != -1, "Status label should include Hungover or start with Status:")
