extends GutTest

const ROOM_DEMO_SCENE := "res://scenes/ascii_min_demo/basic_room_demo.tscn"

func test_basic_room_renders():
	var scene: PackedScene = load(ROOM_DEMO_SCENE)
	var inst: Control = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	
	var ascii_canvas: Control = inst.get_node("AsciiCanvas")
	assert_not_null(ascii_canvas, "AsciiCanvas should exist")
	
	# Force render
	ascii_canvas.render()
	await get_tree().process_frame
	
	# Check that room content exists
	var buffer = ascii_canvas.get("_buffer")
	assert_not_null(buffer, "Canvas should have buffer")
	
	var cells = buffer.get_all_cells()
	var wall_count := 0
	var floor_count := 0
	var furniture_count := 0
	
	for pos in cells:
		var cell = buffer.get_cell(pos)
		if cell:
			match cell.character:
				"█":  # Wall
					wall_count += 1
				".":  # Floor
					floor_count += 1
				"T", "C", "B", "=", "□", "+":  # Furniture and door
					furniture_count += 1
	
	assert_gt(wall_count, 0, "Room should have walls")
	assert_gt(floor_count, 0, "Room should have floor")
	assert_gt(furniture_count, 0, "Room should have furniture")
	
	print("[Test] Room contents: ", wall_count, " walls, ", floor_count, " floor, ", furniture_count, " furniture")

func test_room_has_correct_size():
	var scene: PackedScene = load(ROOM_DEMO_SCENE)
	var inst: Control = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	
	var basic_room: TermElement = inst.get_node("TermRoot/BasicRoom")
	assert_not_null(basic_room, "BasicRoom should exist")
	
	assert_eq(basic_room.get_fixed_width(), 20, "Room width should be 20")
	assert_eq(basic_room.get_fixed_height(), 12, "Room height should be 12")
