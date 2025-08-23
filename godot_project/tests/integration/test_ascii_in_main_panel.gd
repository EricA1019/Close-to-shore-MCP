extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"

func test_main_panel_has_termrect_and_root_visible():
	assert_true(ResourceLoader.exists(UI_SCENE), "UI scene file should exist")
	var scene: PackedScene = load(UI_SCENE)
	var inst: Control = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	var main_panel := inst.get_node("%MainPanel")
	assert_not_null(main_panel, "MainPanel exists")
	var termrect := main_panel.get_node_or_null("TermRect")
	assert_not_null(termrect, "TermRect exists inside MainPanel")
	# Verify term_root is set and grid size computed after layout
	await get_tree().process_frame
	var term_root = termrect.term_root if termrect.has_method("get") else null
	assert_not_null(term_root, "term_root assigned on TermRect")
	# Control should have non-zero size after layout
	assert_gt(termrect.size.x, 0.0, "TermRect has width")
	assert_gt(termrect.size.y, 0.0, "TermRect has height")
