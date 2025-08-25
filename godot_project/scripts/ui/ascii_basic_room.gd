extends TermElement

## Simple ASCII room renderer with walls, floor, door, and furniture

var room_width: int = 20
var room_height: int = 12
var _room_cells: Dictionary = {}

func _ready() -> void:
	super()
	_build_room()

func _build_room() -> void:
	_room_cells.clear()
	
	# Draw floor
	for y in range(1, room_height - 1):
		for x in range(1, room_width - 1):
			_room_cells[Vector2i(x, y)] = TermCell.new(".", Color.YELLOW, Color.BLACK)
	
	# Draw walls
	for x in range(room_width):
		# Top and bottom walls
		_room_cells[Vector2i(x, 0)] = TermCell.new("█", Color.WHITE, Color.DARK_GRAY)
		_room_cells[Vector2i(x, room_height - 1)] = TermCell.new("█", Color.WHITE, Color.DARK_GRAY)
	
	for y in range(room_height):
		# Left and right walls
		_room_cells[Vector2i(0, y)] = TermCell.new("█", Color.WHITE, Color.DARK_GRAY)
		_room_cells[Vector2i(room_width - 1, y)] = TermCell.new("█", Color.WHITE, Color.DARK_GRAY)
	
	# Add door in the bottom wall
	var door_x = int(room_width / 2)
	_room_cells[Vector2i(door_x, room_height - 1)] = TermCell.new("+", Color.BROWN, Color.BLACK)
	
	# Add some furniture
	# Table in center
	var center_x = int(room_width / 2)
	var center_y = int(room_height / 2)
	_room_cells[Vector2i(center_x, center_y)] = TermCell.new("T", Color.BROWN, Color.BLACK)
	
	# Chair next to table
	_room_cells[Vector2i(center_x + 1, center_y)] = TermCell.new("C", Color.BROWN, Color.BLACK)
	
	# Bed in corner
	_room_cells[Vector2i(2, 2)] = TermCell.new("B", Color.BLUE, Color.BLACK)
	_room_cells[Vector2i(3, 2)] = TermCell.new("=", Color.BLUE, Color.BLACK)
	
	# Chest against wall
	_room_cells[Vector2i(room_width - 3, 2)] = TermCell.new("□", Color.BROWN, Color.BLACK)
	
	_redraw_required = true

func _blit_self_under(buffer: TermBuffer) -> void:
	for pos in _room_cells:
		var world_pos = _rect.position + pos
		buffer.put_cell(_room_cells[pos], world_pos)

func _blit_self_under_canvas(buffer) -> void:
	const CanvasCell = preload("res://addons/ascii_grid/ascii_canvas_cell.gd")
	for pos in _room_cells:
		var world_pos = _rect.position + pos
		var term_cell: TermCell = _room_cells[pos]
		var canvas_cell := CanvasCell.new(term_cell.character, term_cell.fg_color, term_cell.bg_color)
		buffer.set_cell(world_pos, canvas_cell)

func get_fixed_width() -> int:
	return room_width

func get_fixed_height() -> int:
	return room_height
