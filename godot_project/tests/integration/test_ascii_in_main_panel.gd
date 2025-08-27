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
	var ascii_canvas := main_panel.get_node_or_null("AsciiCanvas")
	assert_not_null(ascii_canvas, "AsciiCanvas exists inside MainPanel")
	# Verify term_root is set and grid size computed after layout
	await get_tree().process_frame
	var term_root = ascii_canvas.term_root if ascii_canvas.has_method("get") else null
	assert_not_null(term_root, "term_root assigned on AsciiCanvas")
	# Control should have non-zero size after layout
	assert_gt(ascii_canvas.size.x, 0.0, "AsciiCanvas has width")
	assert_gt(ascii_canvas.size.y, 0.0, "AsciiCanvas has height")
