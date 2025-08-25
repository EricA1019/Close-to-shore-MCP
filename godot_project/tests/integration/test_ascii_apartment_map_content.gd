extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"

func test_apartment_map_populates_term_cell_map():
	assert_true(ResourceLoader.exists(UI_SCENE), "UI scene file should exist")
	var scene: PackedScene = load(UI_SCENE)
	var inst: Control = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	var term_root := inst.get_node("%MainPanel/TermRoot")
	assert_not_null(term_root, "TermRoot exists")
	var apt_map := term_root.get_node_or_null("ApartmentMap")
	assert_not_null(apt_map, "ApartmentMap exists")
	# Derive expected content size from the control's content rect
	var content_rect: Rect2i = apt_map.get_content_rect()
	assert_true(content_rect.size.x > 0 and content_rect.size.y > 0, "ApartmentMap content rect has size")
	var w := content_rect.size.x
	var h := content_rect.size.y
	var mid_x := int(w / 2.0)
	var mid_y := int(h / 2.0)
	# Find the internal TermCellMap child by duck-typing get_cell
	var cell_map: Variant = null
	for c in apt_map.get_children():
		if c and c.has_method("get_cell") and c.has_method("put_cell"):
			cell_map = c
			break
	assert_not_null(cell_map, "ApartmentMap has a TermCellMap child")
	# Assert specific glyphs at deterministic positions based on layout
	# Walls should frame the rectangle
	var tl = cell_map.get_cell(Vector2i(0, 0))
	var br = cell_map.get_cell(Vector2i(w - 1, h - 1))
	assert_not_null(tl, "Top-left wall exists")
	assert_not_null(br, "Bottom-right wall exists")
	if tl:
		assert_eq(tl.character, "█", "Top-left should be a solid wall")
	if br:
		assert_eq(br.character, "█", "Bottom-right should be a solid wall")
	# Interior should have floor dots if large enough
	if w > 2 and h > 2:
		var interior = cell_map.get_cell(Vector2i(1, 1))
		assert_not_null(interior, "Interior cell exists")
		if interior:
			assert_eq(interior.character, ".", "Interior should be floor")
	# The center should contain a door '+' when the grid is large enough to split rooms
	# For small sizes (e.g., initial 30x8) the map draws a single room with a top door.
	if w >= 20 and h >= 12:
		var center = cell_map.get_cell(Vector2i(mid_x, mid_y))
		assert_not_null(center, "Center cell exists")
		if center:
			assert_eq(center.character, "+", "Center should be a door")
