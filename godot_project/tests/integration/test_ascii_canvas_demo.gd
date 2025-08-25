extends GutTest

const CANVAS_DEMO_SCENE := "res://scenes/ascii_min_demo/ascii_min_demo_canvas.tscn"

func test_canvas_ascii_renders_text():
	var s: PackedScene = load(CANVAS_DEMO_SCENE)
	var inst: Control = s.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	
	var ascii_canvas: Control = inst.get_node("AsciiCanvas")
	assert_not_null(ascii_canvas, "AsciiCanvas should exist")
	
	# Force render
	ascii_canvas.render()
	await get_tree().process_frame
	
	# Verify the canvas has content
	var buffer = ascii_canvas.get("_buffer")
	assert_not_null(buffer, "Canvas should have a buffer")
	
	var cells = buffer.get_all_cells()
	var non_empty_count := 0
	for pos in cells:
		var cell = buffer.get_cell(pos)
		if cell and cell.character != " ":
			non_empty_count += 1
	
	assert_gt(non_empty_count, 0, "Canvas should have non-empty cells")

func test_canvas_ascii_visible_size():
	var s: PackedScene = load(CANVAS_DEMO_SCENE)
	var inst: Control = s.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	
	var ascii_canvas: Control = inst.get_node("AsciiCanvas")
	assert_gt(ascii_canvas.size.x, 0.0, "Canvas should have width")
	assert_gt(ascii_canvas.size.y, 0.0, "Canvas should have height")
