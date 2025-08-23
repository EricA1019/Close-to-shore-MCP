extends GutTest

const ROOT_SCENE := "res://scenes/game_scene/game_root.tscn"

func test_ascii_title_updates_from_location_state():
	assert_true(ResourceLoader.exists(ROOT_SCENE), "Root scene exists")
	var scene: PackedScene = load(ROOT_SCENE)
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	# Find TermLabel under MainUI
	var ui := inst.get_node_or_null("MainUI")
	assert_not_null(ui, "MainUI exists")
	var main_panel := ui.get_node("%MainPanel")
	var title := main_panel.get_node("TermRoot/Title")
	# Initially Apartment scene sets location -> expect title to show it
	await get_tree().process_frame
	assert_eq(title.text, "Apartment", "ASCII title shows current location")
	# Change location and expect update
	var ls := get_tree().get_root().get_node_or_null("LocationState")
	if ls:
		ls.call("set_location", "Street")
		await get_tree().process_frame
		assert_eq(title.text, "Street", "ASCII title reacts to location change")
