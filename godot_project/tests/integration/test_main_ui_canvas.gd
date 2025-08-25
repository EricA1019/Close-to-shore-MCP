extends GutTest

const MAIN_UI_SCENE := "res://scenes/ui/main_ui.tscn"

func test_main_ui_canvas_renders():
	var s: PackedScene = load(MAIN_UI_SCENE)
	var inst: Control = s.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	
	var main_panel: Control = inst.get_node("%MainPanel")
	assert_not_null(main_panel, "MainPanel should exist")
	
	var ascii_canvas: Control = main_panel.get_node_or_null("AsciiCanvas")
	assert_not_null(ascii_canvas, "AsciiCanvas should exist in MainPanel")
	
	# Force render and wait
	ascii_canvas.render()
	await get_tree().process_frame
	
	# Check that content is being drawn
	var buffer = ascii_canvas.get("_buffer")
	assert_not_null(buffer, "Canvas should have buffer")
	
	var cells = buffer.get_all_cells()
	var content_cells := 0
	for pos in cells:
		var cell = buffer.get_cell(pos)
		if cell and cell.character != " ":
			content_cells += 1
	
	assert_gt(content_cells, 0, "MainUI AsciiCanvas should render content")
