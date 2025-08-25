class_name AsciiCanvasBuffer
extends RefCounted

## Grid data structure for ASCII canvas with dirty region tracking.

const AsciiCanvasCell = preload("res://addons/ascii_grid/ascii_canvas_cell.gd")

var _grid: Dictionary = {}
var _size: Vector2i
var _dirty_regions: Array[Rect2i] = []
var _full_dirty: bool = true

func _init(size: Vector2i) -> void:
	_size = size
	clear()

func get_size() -> Vector2i:
	return _size

func set_cell(pos: Vector2i, cell: AsciiCanvasCell) -> void:
	if pos.x < 0 or pos.y < 0 or pos.x >= _size.x or pos.y >= _size.y:
		return
	
	var existing := get_cell(pos)
	if existing and existing.equals(cell):
		return  # No change needed
	
	_grid[pos] = cell
	mark_dirty(Rect2i(pos, Vector2i(1, 1)))

func get_cell(pos: Vector2i) -> AsciiCanvasCell:
	return _grid.get(pos, null)

func clear(clear_color: Color = Color.BLACK) -> void:
	_grid.clear()
	var empty_cell := AsciiCanvasCell.new(" ", clear_color, clear_color)
	for y in _size.y:
		for x in _size.x:
			_grid[Vector2i(x, y)] = empty_cell
	mark_full_dirty()

func mark_dirty(region: Rect2i) -> void:
	if _full_dirty:
		return
	_dirty_regions.append(region)

func mark_full_dirty() -> void:
	_full_dirty = true
	_dirty_regions.clear()

func get_dirty_regions() -> Array[Rect2i]:
	if _full_dirty:
		return [Rect2i(Vector2i.ZERO, _size)]
	return _dirty_regions.duplicate()

func clear_dirty() -> void:
	_full_dirty = false
	_dirty_regions.clear()

func get_all_cells() -> Dictionary:
	return _grid.duplicate()
